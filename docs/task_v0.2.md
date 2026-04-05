# 개발 작업 현황 (v0.2)

1,000명의 데이터를 시스템 전화 기능과 연동하는 Native 작업 리스트입니다.

- `[x]` **Step 1: 데이터 준비 및 DB 구축**
    - `[x]` 샘플 데이터 생성 (1,000명 CSV)
    - `[x]` SQLite 스키마 설계 (이름, 번호, 부서, 직급)
    - `[x]` CSV → SQLite 데이터 마이그레이션 로직 구현
- `[x]` **Step 2: 사용자 화면(UI) 개발**
    - `[x]` 메인 검색 화면 (사소 검색바 + 리스트)
    - `[x]` 사원 상세 정보 팝업
- `[x]` **Step 3: Android Native 개발 (진행 중)**
    - `[x]` `ROLE_CALL_SCREENING` 권한 요청 로직 (MainActivity)
    - `[x]` `CallScreeningService` 서비스 구현
    - `[x]` 네이티브 SQLite 연동 및 발신자 이름 로그 출력 테스트
- `[x]` **Step 4: iOS Native 개발**
    - `[ ]` `App Groups` 설정 가이드 작성
    - `[x]` `CallKit` Extension 핵심 코드 구현
    - `[x]` 디렉토리 데이터 업데이트 채널 구축
- `[ ]` **Step 5: 검증**
    - `[/]` 실제 전화 수신 시 이름 표시 확인
