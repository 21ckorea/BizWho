# iOS 가이드: App Groups 및 Extension 설정 (v0.2)

iOS에서 발신자 정보를 표시하기 위해서는 메인 앱과 `Call Directory Extension` 간의 데이터 공유가 필수적입니다. 이 설정은 Xcode에서 수동으로 수행해야 합니다.

## 1. App Group 생성 및 설정

1.  **Xcode**에서 프로젝트 파일을 엽니다.
2.  `Runner` 타겟의 **Signing & Capabilities** 탭으로 이동합니다.
3.  **+ Capability**를 클릭하고 **App Groups**를 추가합니다.
4.  `group.com.example.caller_id_v01` (또는 원하는 ID) 형식으로 새로운 Group을 생성하고 체크합니다.
5.  `CallDirectoryExtension` 타겟에 대해서도 **동일한 과정**으로 똑같은 Group ID를 추가하고 체크합니다.

## 2. 코드 내 Group ID 반영

현재 `AppDelegate.swift`와 `CallDirectoryHandler.swift`에 작성된 Group ID가 상기 생성한 ID와 일치하는지 확인하십시오.

## 3. 권한 활성화 (사용자)

iOS 시스템에서 앱이 발신자 정보를 표시하도록 수동으로 허용해야 합니다.

1.  아이폰 **설정 (Settings)** 앱을 엽니다.
2.  **전화 (Phone)** 메뉴로 들어갑니다.
3.  **전화 차단 및 발신자 확인 (Call Blocking & Identification)**을 클릭합니다.
4.  작성하신 앱(`Caller ID v0.1`)의 스위치를 **On**으로 켭니다.

## 4. 주의 사항 (중요)

- **전화번호 형식**: 시스템에 등록할 때는 반드시 국가 코드(예: 8210...)가 포함된 **숫자만** 전달해야 합니다. (`context.addIdentificationEntry`)
- **정렬**: 번호는 반드시 **오름차순(Ascending)**으로 등록되어야 하며, 중복된 번호가 있으면 익스텐션이 충돌하여 작동하지 않습니다.
- **메모리 제한**: 익스텐션은 메모리 사용량이 극히 제한되므로(수 MB 이내), 1,000명의 데이터를 한 번에 읽을 때 루프를 최적화해야 합니다.
