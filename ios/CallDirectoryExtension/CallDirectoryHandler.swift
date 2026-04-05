import Foundation
import CallKit

class CallDirectoryHandler: CXCallDirectoryProvider {

    override func beginRequest(with context: CXCallDirectoryExtensionContext) {
        context.delegate = self

        // v0.1: 수동으로 몇 개의 샘플 데이터를 등록해봅니다.
        // 실제 구현에서는 App Group을 통해 공유된 SQLite 또는 UserDefaults를 읽어옵니다.
        addAllIdentificationPhoneNumbers(to: context)

        context.completeRequest()
    }

    private func addAllIdentificationPhoneNumbers(to context: CXCallDirectoryExtensionContext) {
        // 주의: 번호는 반드시 오름차순(numerically ascending order)으로 추가해야 합니다.
        // 예: [821012345678, 821087654321]
        
        let phoneNumbers: [CXCallDirectoryPhoneNumber] = [821012345678, 821087654321]
        let labels = ["홍길동 대리(마케팅팀)", "이몽룡 과장(개발팀)"]

        for (phoneNumber, label) in zip(phoneNumbers, labels) {
            context.addIdentificationEntry(withNextSequentialPhoneNumber: phoneNumber, label: label)
        }
    }
}

extension CallDirectoryHandler: CXCallDirectoryExtensionContextDelegate {
    func requestFailed(for extensionContext: CXCallDirectoryExtensionContext, withError error: Error) {
        // 에러 처리
    }
}
