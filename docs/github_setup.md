# 🐙 GitHub 형상 관리 가이드 (BizWho)

이 문서는 프로젝트의 초기 설정 과정과 향후 코드 수정 시 GitHub에 업데이트하는 방법을 기록합니다.

---

## 1. 초기 프로젝트 업로드 (Initial Setup)

프로젝트를 처음으로 GitHub에 올릴 때 실행한 명령어들입니다.

```bash
# 1. 로컬 저장소 초기화
git init

# 2. 모든 파일 스테이징 (.gitignore에 등록된 개인정보 파일은 자동으로 제외됨)
git add .

# 3. 첫 커밋 남기기 (메타데이터 기록)
git commit -m "feat: BizWho v1.7.5 - 스마트 발신자 식별 오버레이 정식 배포 준비"

# 4. 기본 브랜치 이름을 main으로 변경
git branch -M main

# 5. GitHub 원격 저장소 연결
git remote add origin https://github.com/21ckorea/BizWho.git

# 6. 원격 저장소로 첫 업로드 (upstream 설정)
git push -u origin main
```

---

## 2. 수정 사항 업데이트 방법 (Update Workflow)

기능을 추가하거나 버그를 수정한 후, 변경된 내용을 다시 GitHub에 올릴 때는 아래 **3단계**만 기억하세요.

### Step 1: 변경된 파일 담기 (add)
수정된 파일들을 업로드 대기 목록에 올립니다.

```bash
# 모든 수정된 파일을 담을 때
git add .

# 특정 파일만 담고 싶을 때 (예: main.dart)
git add lib/main.dart
```

### Step 2: 변경 내용 기록 (commit)
어떤 작업을 했는지 짧고 명확한 메시지를 남깁니다.

```bash
# 예: 설정창 레이아웃 수정 시
git commit -m "fix: 설정창 하단 버튼 레이아웃 및 그룹화 개선"

# 예: 통화 상태 연동 기능 추가 시
git commit -m "feat: 통화 상태(OFFHOOK, IDLE) 연동 오버레이 제어 로직 추가"
```

### Step 3: 서버로 전송 (push)
내 컴퓨터의 커밋 내역을 GitHub 서버로 보냅니다.

```bash
git push
```

---

## 💡 유용한 팁

- **현재 상태 확인**: 어떤 파일이 수정되었는지 궁금할 때 `git status`를 입력하세요.
- **커밋 내역 확인**: 지금까지 어떤 업데이트가 있었는지 보려면 `git log --oneline`을 입력하세요.
- **취소하고 싶을 때**: `git add` 한 내용을 취소하려면 `git reset`을 입력하세요.

> [!IMPORTANT]
> - `employee_contacts.csv`나 `key.jks` 등 개인정보 파일은 `.gitignore`에 등록되어 자동으로 보호되므로 안심하고 `git add .`를 사용하셔도 됩니다.
