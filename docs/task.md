# 개발 작업 현황 (Task List)

Caller ID 앱 개발 프로세스 관리를 위한 작업 리스트입니다.

- `[ ]` **Phase 1: 기반 구축 및 Backend 연동**
    - `[ ]` Azure AD/Active Directory 연동용 Backend Proxy API 설계
    - `[ ]` Microsoft Graph API 연동 (유저 데이터 동기화)
    - `[ ]` Mobile용 인증 흐름 구현 (MSAL)
- `[ ]` **Phase 2: Mobile UI 및 로컬 DB 개발**
    - `[ ]` 검색 UI 및 직원 상세 정보 화면 개발
    - `[ ]` 기기 로컬 암호화 DB (SQLite + SQLCipher) 구축
- `[ ]` **Phase 3: Android Native 개발**
    - `[ ]` `CallScreeningService` 구현
    - `[ ]` 번호 식별 및 정보 표시 오버레이 UI 구현
- `[ ]` **Phase 4: iOS Native 개발**
    - `[ ]` `CXCallDirectoryExtension` 구현
    - `[ ]` 로컬 DB 데이터 로드 및 갱신 로직 구현
- `[ ]` **Phase 5: 통합 테스트 및 배포**
    - `[ ]` 수신 식별 정확도 및 성능 테스트
    - `[ ]` 배포 가이드 문서 작성 (권한 설정 방법 등)
