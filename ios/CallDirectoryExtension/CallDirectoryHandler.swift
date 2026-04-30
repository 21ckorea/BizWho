import Foundation
import CallKit

class CallDirectoryHandler: CXCallDirectoryProvider {

    override func beginRequest(with context: CXCallDirectoryExtensionContext) {
        context.delegate = self

        // App Group을 통해 Flutter 메인 앱이 저장한 연락처 데이터를 읽어옵니다.
        // 주의: Xcode에서 App Group "group.com.bizwho.callerid" Capability를 Runner 및 이 Extension에 모두 추가해야 합니다.
        addAllIdentificationPhoneNumbers(to: context)

        context.completeRequest()
    }

    private func addAllIdentificationPhoneNumbers(to context: CXCallDirectoryExtensionContext) {
        // App Group 공유 UserDefaults에서 데이터 읽기
        let userDefaults = UserDefaults(suiteName: "group.com.bizwho.callerid")

        // 데이터 형식: Dictionary<String, String> (전화번호 문자열 : 이름 직책)
        // Flutter 앱에서 "caller_id_contacts" 키로 저장 (예: ["821012345678": "홍길동 대리"])
        guard let savedContacts = userDefaults?.dictionary(forKey: "caller_id_contacts") as? [String: String],
              !savedContacts.isEmpty else {
            // 저장된 연락처가 없으면 빈 상태로 종료
            return
        }

        // CXCallDirectoryPhoneNumber (Int64)로 변환하고, CallKit 규정에 따라 오름차순 정렬
        var contacts: [(CXCallDirectoryPhoneNumber, String)] = []

        for (phoneString, label) in savedContacts {
            // 숫자만 추출 (하이픈, 공백 등 제거)
            let digitsOnly = phoneString.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            if let phoneNumber = CXCallDirectoryPhoneNumber(digitsOnly) {
                contacts.append((phoneNumber, label))
            }
        }

        // 반드시 오름차순(숫자 크기 순) 정렬 (Apple 규정 필수사항)
        contacts.sort { $0.0 < $1.0 }

        // CallKit에 순차적으로 발신자 이름 등록
        for contact in contacts {
            context.addIdentificationEntry(withNextSequentialPhoneNumber: contact.0, label: contact.1)
        }
    }
}

extension CallDirectoryHandler: CXCallDirectoryExtensionContextDelegate {
    func requestFailed(for extensionContext: CXCallDirectoryExtensionContext, withError error: Error) {
        // 에러 발생 시 로그 출력
        NSLog("CallDirectoryHandler requestFailed: \(error.localizedDescription)")
    }
}
