# iOS 테스트 및 빌드 가이드 (v0.3)

iOS에서 콜러 ID(CallKit) 기능을 테스트하려면 Xcode 설정과 **실제 아이폰 기기**가 반드시 필요합니다. 시뮬레이터에서는 CallKit 익스텐션이 동작하지 않습니다.

## 1. 사전 준비

1. **Mac & Xcode**: 최신 버전의 Xcode가 설치되어 있어야 합니다.
2. **실제 아이폰**: iOS 13 이상 버전이 필요합니다.
3. **Apple Developer ID**: 앱의 권한(Signing)을 설정하기 위해 필요합니다. (무료 계정도 가능)

## 2. Xcode 프로젝트 설정 (중요)

터미널에서 프로젝트 루트 폴더로 이동한 후 다음을 수행합니다.

1. **iOS 프로젝트 열기**:
   ```bash
   open ios/Runner.xcworkspace
   ```
2. **Signing 설정**:
   - `Runner` 타겟 선택 -> `Signing & Capabilities` 탭 -> 사용자 **Team** 선택.
   - `CallDirectoryExtension` 타겟 선택 -> 동일한 **Team** 선택.
3. **Bundle ID 확인**: 
   - 메인 앱과 익스텐션의 Bundle ID가 고유해야 하며, 익스텐션의 ID는 메인 앱 ID를 포함해야 합니다.
   - 예: 메인(`com.company.app`), 익스텐션(`com.company.app.CallDirectoryExtension`)
4. **App Groups 설정**:
   - [iOS 설정 가이드(v0.2)](file:///Users/ryan/work/app/CallerID/docs/ios_setup_guide_v0.2.md)에 따라 두 타겟 모두에 동일한 **App Group ID**를 추가합니다.

## 3. 빌드 및 실행

1. 아이폰을 Mac에 연결합니다.
2. Xcode 상단에서 연결된 아이폰을 대상으로 선택합니다.
3. **Run (▶)** 버튼을 누르거나, 터미널에서 `flutter run`을 실행합니다.

## 4. 기능 테스트 방법

1. 앱 실행 후 **'직원 연락처 검색'** 화면이 뜨는지 확인합니다.
2. 이제 아이폰의 **설정 앱**으로 이동합니다.
3. **전화 > 전화 차단 및 발신자 확인** 메뉴로 들어갑니다.
4. **'Caller ID v0.1'** 스위치를 **On**으로 활성화합니다. (이 과정이 없으면 이름이 뜨지 않습니다.)
5. 샘플 연락처(예: `김대리 010-4052-0941`) 중 하나로 전화를 걸어보거나, 해당 번호로 전화를 받아 이름이 표시되는지 확인합니다.

---

## 5. 주의 사항

- **데이터 정합성**: `CallDirectoryHandler.swift`에 등록된 번호와 실제 발신 번호가 일치해야 합니다. (국가 코드 포함 여부 확인)
- **익스텐션 정지**: 테스트 중 이름이 안 뜨면 Xcode의 `Debug > Attach to Process` 메뉴에서 `CallDirectoryExtension`을 찾아 강제 중단 후 다시 시도해 보세요.
