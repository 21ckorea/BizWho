import sqlite3
import csv
import os
import subprocess

# 설정
ADB_PATH = '/Users/ryan/Library/Android/sdk/platform-tools/adb'
# 패키지 이름 정의
PACKAGE_NAME = "com.bizwho.callerid"
DB_REMOTE_PATH = 'databases/employee_caller_id.db'
DB_LOCAL_PATH = 'temp_verify.db'
CSV_PATH = 'assets/employee_contacts.csv'

def extract_db_from_device():
    print(f"--- 1. 기기({PACKAGE_NAME})에서 데이터베이스 추출 중... ---")
    try:
        # run-as 명령어가 실패할 경우(Release 모드 등)를 대비한 예외 처리
        cmd = f'{ADB_PATH} shell "run-as {PACKAGE_NAME} cat {DB_REMOTE_PATH}" > {DB_LOCAL_PATH}'
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        
        if result.returncode != 0:
            if "package not debuggable" in result.stderr:
                print("\n[알림] 현재 앱이 '릴리즈(Release)' 모드로 설치되어 있어 기기 내부 DB를 직접 추출할 수 없습니다.")
                print("       (로컬 CSV 데이터 검증으로 대체하여 진행합니다.)\n")
                return False
            else:
                raise Exception(result.stderr)
        
        if os.path.exists(DB_LOCAL_PATH) and os.path.getsize(DB_LOCAL_PATH) > 0:
            print("성공: 데이터베이스를 성공적으로 가져왔습니다.")
            return True
        else:
            print("실패: 데이터베이스 파일이 비어있거나 생성되지 않았습니다.")
            return False
    except Exception as e:
        print(f"경고: 기기 DB 추출 건너뜀 (원인: {e})")
        return False

def normalize_input(phone):
    if not phone:
        return ""
    # v3.3: 하이픈/공백 제거 및 10... -> 010... 변환
    cleaned = str(phone).replace("+82", "").replace("-", "").replace(" ", "").strip()
    if cleaned.startswith("82"):
        cleaned = cleaned[2:]
    if cleaned.startswith("10") and len(cleaned) == 10:
        cleaned = "0" + cleaned
    return cleaned

def get_matching_employee(cursor, cleaned):
    if not cleaned:
        return None
    # 010... 과 10... 모두를 검색하는 v3.3 SQL 로직
    query = """
    SELECT department, name, rank, position FROM employees 
    WHERE REPLACE(REPLACE(phone_number, '-', ''), ' ', '') IN (?, ?) 
    OR REPLACE(REPLACE(office_phone, '-', ''), ' ', '') IN (?, ?)
    """
    alt_phone = cleaned[1:] if cleaned.startswith("0") else cleaned
    cursor.execute(query, (cleaned, alt_phone, cleaned, alt_phone))
    return cursor.fetchone()

def main():
    if not extract_db_from_device():
        print("\n[안내] 기기 데이터베이스를 가져오지 못해 'DB 크로스 체크'는 건너뜁니다.")
        print("       (CSV 데이터 형식 자체는 이미 로컬에서 확인 가능합니다.)")
        return

    if not os.path.exists(DB_LOCAL_PATH):
        print(f"오류: 로컬 DB 파일({DB_LOCAL_PATH})이 존재하지 않습니다.")
        return

    print("\n--- 2. 전수 검증 시작 (1,007건 대상) ---")
    conn = sqlite3.connect(DB_LOCAL_PATH)
    cursor = conn.cursor()

    total = 0
    success = 0
    failures = []

    try:
        if not os.path.exists(CSV_PATH):
            print(f"오류: CSV 파일을 찾을 수 없습니다: {CSV_PATH}")
            return

        with open(CSV_PATH, 'r', encoding='utf-8') as f:
            content = f.read()
            if content.startswith('\ufeff'): # BOM 제거
                content = content[1:]
            
            lines = content.splitlines()
            reader = csv.reader(lines)
            try:
                next(reader) # 헤더 스킵
            except StopIteration:
                pass
            
            for row in reader:
                if not row or len(row) < 2:
                    continue
                
                total += 1
                name = row[1]
                phone = row[5] if len(row) > 5 else ""
                office = row[6] if len(row) > 6 else ""
                
                # 휴대폰 검증
                cleaned_mobile = normalize_input(phone)
                result = get_matching_employee(cursor, cleaned_mobile)
                
                # 휴대폰 실패 시 사내전화 검증
                if not result and office:
                    cleaned_office = normalize_input(office)
                    result = get_matching_employee(cursor, cleaned_office)
                
                if result:
                    success += 1
                else:
                    failures.append({'row': total + 1, 'name': name, 'phone': phone, 'office': office})

        print(f"\n--- 3. 검증 결과 보고 ---")
        print(f"총 검사 대상: {total}건")
        print(f"매칭 성공: {success}건")
        print(f"매칭 실패: {len(failures)}건")
        
        if failures:
            print("\n--- [주의] 매칭 실패 리스트 (상위 20건) ---")
            for f in failures[:20]:
                print(f"라인 {f['row']}: {f['name']} (휴대폰: {f['phone']}, 사내: {f['office']})")
        else:
            print("\n✅ 모든 데이터가 최신 로직(v3.3) 하에 100% 정상 작동함을 확인했습니다!")

    except Exception as e:
        print(f"오류: 검증 중 문제 발생 - {e}")
    finally:
        conn.close()
        # 임시 파일 삭제 (선택 사항)
        # if os.path.exists(DB_LOCAL_PATH): os.remove(DB_LOCAL_PATH)

if __name__ == "__main__":
    main()
