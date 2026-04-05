# 개발 방법론 및 기술 스택 (Development Methodology)

이 프로젝트의 개발 방향과 사용할 기술적 도구들을 정의합니다.

## 1. 개발 스택 (Tech Stack)

### Mobile App
- **프레임워크**: Flutter (추천)
  - 이유: Android/iOS UI 싱크 및 성능 최적화에 유리하며, 고성능 네이티브 플러그인(Platform Channels) 연동이 매끄럽습니다.
- **로컬 스토리지**: SQLite + SQLCipher
  - 이유: 대량의 연락처 데이터를 빠르게 조회해야 하며, 기업 보안 정책상 데이터 암호화가 필수입니다.

### Backend (Proxy)
- **언어/프레임워크**: Node.js (TypeScript) 또는 Python (FastAPI)
- **인프라**: Azure Functions / AWS Lambda (무상태 함수로 가벼운 연동)
- **데이터 소스**: Microsoft Graph API (Cloud) 또는 LDAP (On-premise)

---

## 2. 개발 방법론 (Methodology)

### Agile & Iterative
1. **MVP 개발**: 가장 먼저 검색 기능이 있는 간단한 연락처 앱부터 시작합니다.
2. **Native Extension 추가**: UI가 완성되면 Android/iOS의 전화 감지 기능을 개별적으로 붙입니다.
3. **보안 강화**: 마지막 단계에서 DB 암호화 및 토근 유효성 검사를 추가합니다.

### CI/CD 및 협업
- **Source Control**: Git (GitHub/GitLab)
- **Code Convention**: 각 언어별 표준 컨벤션 준수 (Flutter: `flutter_lints`, Kotlin: `ktlint` 등)

---

## 3. 핵심 운영 원칙
- **Privacy First**: 통화 내용이나 개인적인 연락처는 수집하지 않으며, 오직 기업 AD 정보만 활용합니다.
- **Fail-safe Design**: 서버가 일시적으로 다운되더라도 마지막에 동기화된 로컬 DB를 사용하여 기능을 유지합니다.
- **Low Impact**: 백그라운드 작업은 배터리 소모를 최소화하도록 백그라운드 fetch 주기를 최적화합니다.
