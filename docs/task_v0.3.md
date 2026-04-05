# 개발 작업 현황 (v0.3)

사용자가 실제 안드로이드 폰에서 빌드하고 테스트할 수 있도록 환경 설정을 완료한 단계입니다.

- `[x]` **Step 1: 데이터 준비 및 DB 구축**
    - `[x]` 샘플 데이터 생성 (1,000명 CSV)
    - `[x]` SQLite 스키마 설계
- `[x]` **Step 2: 사용자 화면(UI) 개발**
    - `[x]` 메인 검색 화면
- `[x]` **Step 3: Android Native 개발**
    - `[x]` `ROLE_CALL_SCREENING` 권한 로직
    - `[x]` `CallScreeningService` 구현
- `[x]` **Step 4: iOS Native 개발**
    - `[x]` `App Groups` 설정 가이드 작성
    - `[x]` `CallKit` Extension 핵심 코드 구현
    - `[x]` 디렉토리 데이터 업데이트 채널 구축
- `[x]` **Step 5: 빌드 설정 및 테스트 환경 구축 (v0.3)**
    - `[x]` Android Build Script (`gradle`) 생성
    - `[x]` Android/iOS 테스트 가이드 작성 ([ios_test_guide_v0.3.md](file:///Users/ryan/work/app/CallerID/docs/ios_test_guide_v0.3.md))
    - `[x]` Info.plist 및 테마 설정 완료
- `[ ]` **Step 6: 검증 및 피드백 반영**
    - `[ ]` 실기기 수신 테스트 및 버그 수정
