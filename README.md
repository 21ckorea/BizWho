# 📱 BizWho (비즈후) - 스마트 발신자 식별 오버레이

사내 임직원 연락처 데이터를 기반으로, 전화 수신 시 발신자의 이름, 직급, 부서 정보를 화면에 즉시 띄워주는 Flutter 기반 안드로이드 애플리케이션입니다.

---

## ✨ 핵심 기능

- **지능형 오버레이**: 수신 전화 상태를 감지하여 발신자 정보를 프리미엄 카드 형태로 표시합니다.
- **통화 상태 실시간 동기화**: 벨이 울릴 때 나타나고, 통화 중에는 유지되며, 통화 종료 시 즉시 자동 소멸합니다. (v1.5.0+)
- **개인화 설정**: 정보창의 위치(상단/중간/하단), 글자 크기, 유지 시간을 사용자가 직접 조정할 수 있습니다. (v1.7.0+)
- **로컬 고성능 DB**: CSV 데이터를 로컬 SQLite에 최적화하여 저장하므로, 대용량 주소록에서도 즉각적인 검색이 가능합니다.

---

## 🚀 퀵 스타트 (Quick Start)

| 단계 | 필수 명령어 | 상세 설명 |
| :--- | :--- | :--- |
| **1. 환경 확인** | `flutter doctor` | Flutter 개발 환경 정상 여부 확인 |
| **2. 의존성 설치** | `flutter pub get` | 프로젝트에 필요한 패키지 다운로드 |
| **3. 데이터 준비** | `CSV 파일 작성` | `assets/employee_contacts.csv` 경로에 데이터 준비 |
| **4. 앱 실행** | `flutter run` | 연결된 안드로이드 기기에서 즉시 실행 |
| **5. 패키징** | `flutter build apk` | 배포용 APK 파일 생성 |

---

## 🛠️ 컴파일 및 실행 상세 가이드

### 1. 전제 조건 (Prerequisites)
- [Flutter SDK](https://docs.flutter.dev/get-started/install) 설치 (v3.0.0 이상 권장)
- 안드로이드 기기 (Android 10 이상 권장)

### 2. 필수 권한 설정
앱 실행 후 다음 권한을 반드시 허용해야 정상 작동합니다:
- **다른 앱 위에 표시 (Overlay Permission)**: 정보창을 띄우기 위해 필수입니다.
- **전화 상태 읽기 (Phone State)**: 전화 수신 및 통화 종료 상태를 감지하기 위해 필요합니다.

### 3. 데이터 구성 방식
보안을 위해 실제 임직원 데이터는 GitHub에 업로드하지 않습니다. 아래 샘플 양식에 맞춰 파일을 준비해 주세요.

- **파일명**: `assets/employee_contacts.csv`
- **인코딩**: UTF-8 (헤더 포함 필수)

---

## 🧪 데이터 샘플 (Dummy Data Sample)

`employee_contacts.csv` 파일은 반드시 아래의 **7개 컬럼 순서**를 지켜서 작성해야 합니다:

```csv
부서,성명,직급,직책,이메일,휴대폰,사내전화
전략기획팀,홍길동,과장,팀장,hgd@example.com,010-0000-0000,02-123-4567
인사총무팀,김철수,대리,팀원,csc@example.com,010-1111-2222,02-987-6543
영업본부,이영희,이사,본부장,yhlee@example.com,010-3333-4444,02-333-7777
```

> [!IMPORTANT]
> - **컬럼 순서**: `부서 -> 성명 -> 직급 -> 직책 -> 이메일 -> 휴대폰 -> 사내전화` 순서를 반드시 지켜야 합니다.
> - **파일명**: `assets/employee_contacts.csv` 경로를 유지해야 합니다.
> - **인코딩**: 한글 깨짐 방지를 위해 반드시 **UTF-8** 형식으로 저장해 주세요.

---

## 🔐 앱 서명 가이드 (Release Signing)

릴리스용 APK(`flutter build apk`)를 생성하기 위해서는 보안 키 생성 및 설정이 필요합니다. 아래 파일들은 보안을 위해 **GitHub에 업로드되지 않으므로** 직접 생성해야 합니다.

### 1. 키스토어 생성 (`key.jks`)
터미널에서 아래 명령을 실행하여 키 파일을 생성합니다.

```bash
keytool -genkey -v -keystore android/app/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key
```
- **위치**: `android/app/key.jks`
- 생성 시 입력한 비밀번호와 별칭(alias)을 기억해 두세요.

### 2. 키 속성 파일 작성 (`key.properties`)
`android/` 폴더 내에 아래 내용으로 파일을 만듭니다.

- **위치**: `android/key.properties`
- **내용**:
```properties
storePassword=<입력한_비밀번호>
keyPassword=<입력한_비밀번호>
keyAlias=key
storeFile=app/key.jks
```

> [!WARNING]
> `key.jks`와 `key.properties` 파일은 외부로 유출되지 않도록 주의하세요. 프로젝트 루트의 `.gitignore`에 이미 포함되어 있어 GitHub에는 올라가지 않습니다.

---

## 📄 라이선스 (License)
본 프로젝트는 사내 내부용으로 개발되었으며, 무단 배보 및 상업적 이용을 금합니다.
