# 개발 방법론 (v0.1)

초기 단계에서는 **"데이터 정합성"**과 **"전화 수신 감지"**라는 두 가지 핵심 가치에 집중합니다.

## 1. 기술 스택 (v0.1)
- **프레임워크**: Flutter ([비교 문서 참조](file:///Users/ryan/work/app/CallerID/docs/tech_stack_comparison_v0.1.md))
- **DB**: `sqflite` (SQLite for Flutter)
- **Native 연동**: `MethodChannel`을 통한 Java/Kotlin/Swift 통신

## 2. 작업 방식
1. **정적 데이터 사용**: 초기에는 서버 통신 로직을 완전히 배제하고, `assets` 폴더에 CSV 파일을 포함시켜 빌드합니다.
2. **이벤트 루프 확인**: 전화가 왔을 때 앱이 백그라운드나 종료된 상태에서도 로컬 DB를 즉시 조회할 수 있는지 우선 검증합니다.

## 3. 히스토리 관리
- 모든 문서는 `v0.x` 형태로 버전을 표기하여 저장합니다.
- 큰 기능 단위의 변화가 있을 때마다 버전을 올립니다.
