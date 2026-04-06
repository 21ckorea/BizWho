# 📱 비즈후(BizWho) 서비스 프로세스 안내 (본부장님 보고용)

본 다이어그램은 사내 임직원 연락처 정보를 기반으로 한 발신자 식별 서비스의 전체 흐름을 시각화한 것입니다.

## 1. 서비스 흐름도 (Sequence Diagram)

```mermaid
sequenceDiagram
    autonumber
    actor User as 사용자 (본부장님)
    participant App as 비즈후 앱 (BizWho)
    participant OS as 안드로이드 시스템
    participant Call as 외부 발신자 (직원)

    Note over User, App: [최초 1회 설정]
    User->>App: 앱 설치 및 권한 승인
    App->>App: 사내 주소록 데이터(CSV) 자동 로드
    
    Note over App, OS: [백그라운드 대기]
    App->>OS: "발신자 식별 엔진 가동 중" (상시 대기)

    Note over Call, User: [전화 수신 시점]
    Call->>User: 📞 전화 벨소리 울림
    OS->>App: "모르는 번호(010-XXXX)로 전화가 왔어요!"
    
    rect rgb(230, 245, 255)
        Note right of App: [매칭 엔진 가동]
        App->>App: 내부 주소록에서 010-XXXX 검색
        App-->>App: "마케팅팀 / 이정우 / 과장" 매칭 성공!
    end

    App->>User: 🌟 화면 중앙에 발신자 정보 오버레이 표시
    Note over User: "누구인지 즉시 확인하고 응대"

    Note over Call, User: [통화 종료 후]
    OS->>App: "통화가 종료되었습니다."
    App->>User: 발신 정보창 자동 소멸 (화면 정리)
```

## 2. 본부장님께 드리는 3줄 요약

1.  **자동화**: 임직원 데이터를 한 번만 넣어두면, 앱을 켜지 않아도 **24시간 자동**으로 작동합니다.
2.  **직관성**: 모르는 번호도 전화가 오는 즉시 **[부서 / 성함 / 직급]**을 카드 형태로 보여주어 당황하지 않고 전화를 받으실 수 있습니다.
3.  **철저한 보안**: 모든 데이터 대조는 스마트폰 내부에서만 이루어지며, 외부 서버로 임직원 정보가 유출되지 않도록 설계되었습니다.

---
> [!TIP]
> **폴더블 폰(Z Flip) 특화**: 본부장님께서 폴더블 폰을 사용하신다면, 폰을 접어두었다가 펼쳐서 전화를 받으실 때도 정보창이 화면 크기에 맞춰 자동으로 다시 나타나도록 최적화되어 있습니다.
