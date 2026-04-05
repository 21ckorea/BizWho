# Enterprise Caller ID Native 연동 계획 (v0.2)

본 계획서는 v0.1에서 구축한 로컬 DB 및 UI를 바탕으로, 실제 시스템 전화 수신 시 발신자 정보를 표시하기 위한 **Native 연동** 과정을 다룹니다.

## 1. 개요
Flutter(UI/DB 레이어)와 Native OS(연동 레이어) 간의 브릿지를 구축하여, 전화 수신 이벤트 발생 시 로컬 SQLite 데이터를 참조할 수 있도록 합니다.

---

## 2. Android 구현 계획 (CallScreeningService)

### 주요 파일 변경
1.  **`AndroidManifest.xml`**:
    - `BIND_SCREENING_SERVICE` 권한 선언.
    - `CallScreeningService` 서비스 등록.
2.  **`CallScreeningServiceImpl.kt` [NEW]**:
    - `onScreenCall` 콜백 구현.
    - 네이티브 직접 SQLite 쿼리 또는 Flutter와 통신하여 정보 조회.
3.  **`MainActivity.kt`**:
    - 앱 실행 시 `RoleManager`를 통해 "발신자 ID 및 스팸 앱" 권한 요청 로직 추가.

---

## 3. iOS 구현 계획 (Call Directory Extension)

### 주요 파일 변경
1.  **`CallDirectoryHandler.swift` [NEW]**:
    - `CXCallDirectoryProvider` 구현.
    - **App Group**을 통해 공유된 데이터를 읽어 시스템 식별 목록에 등록.
2.  **`AppDelegate.swift`**:
    - Flutter에서 데이터 갱신 시 `CXCallDirectoryManager`를 호출하여 익스텐션을 리로드하는 네이티브 채널 구축.

---

## 4. 데이터 공유 전략 (Shared Storage)

Native Extension은 별도의 프로세스에서 실행되므로 Flutter의 메모리에 직접 접근할 수 없습니다.

- **방법**: Flutter에서 데이터를 로컬 DB(SQLite)에 저장할 때, Native가 읽을 수 있는 특정 경로(Android: Default DB Path, iOS: App Group Container)에 파일을 위치시킵니다.
- **iOS App Group**: `group.com.example.caller_id`와 같은 식별자를 생성하여 메인 앱과 Extension이 파일을 공유합니다.

---

## 5. 단계별 작업 (Next Steps)

1.  **Android 권한 요청 구현**: 앱 실행 시 팝업으로 권한을 받는 기능부터 개발합니다.
2.  **Android 서비스 구현**: 실제 수신 시 로그를 찍어보는 단계부터 진행합니다.
3.  **iOS 익스텐션 뼈대 생성**: 통화 디렉토리 등록 로직을 작성합니다.

## User Review Required

> [!IMPORTANT]
> **Android 실기기 테스트 필수**: `CallScreeningService`는 에뮬레이터에서 동작이 불안정하거나 지원되지 않을 수 있습니다. 반드시 유심이 장착된 실기기 테스트가 권장됩니다.

> [!WARNING]
> **iOS App Group 설정**: iOS의 경우 Xcode에서 직접 `App Groups` Capabilitiy를 추가하고 Group ID를 설정해야 합니다. 이 부분은 코드로 자동화가 어려우며 문서 가이드를 제공하겠습니다.

## Open Questions
- 테스트용 안드로이드 폰의 OS 버전이 어떻게 되시나요? (안드로이드 10 미만인 경우 다른 API를 사용해야 합니다.)
