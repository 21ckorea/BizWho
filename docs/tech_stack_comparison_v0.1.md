# 기술 스택 비교 분석: Flutter vs React Native (v0.1)

본 문서는 업무용 콜러 ID(Caller ID) 앱 개발을 위해 고려된 프레임워크인 Flutter와 React Native(RN)를 비교 분석한 내용입니다.

---

## 1. 개요 (Overview)
콜러 ID 앱은 수신 전화 감지(Call Screening) 및 발신자 정보 표시(Call Identification)라는 **OS 시스템 레벨의 밀접한 연동**이 필요합니다. 따라서 단순히 화면을 그리는 속도보다 **백그라운드 서비스의 안정성**과 **네이티브 코드와의 통신 효율**이 가장 중요합니다.

## 2. 상세 비교 (Detailed Comparison)

| 항목 | Flutter (선택) | React Native |
| :--- | :--- | :--- |
| **언어 및 런타임** | Dart (Native ARM/x86 컴파일) | JavaScript (Hermes/V8 엔진 기반) |
| **성능 (브릿지)** | 브릿지 없이 직접 엔진이 네이티브 API 호출 | JS와 Native 간의 통신(Bridge) 오버헤드 존재 |
| **UI 렌더링** | 자체 엔진(Skia)으로 모든 화면을 직접 그림 | OS의 네이티브 컴포넌트를 호출하여 렌더링 |
| **백그라운드 처리** | 강력한 Isolates 및 백그라운드 서비스 지원 | 모듈에 따라 백그라운드 제약이 있을 수 있음 |
| **타입 안정성** | 언어 차원의 강력한 정적 타이핑 (Dart) | TypeScript를 사용해야 하지만 완벽한 싱크가 어려움 |

## 3. 왜 Flutter인가?

1. **실시간성 (Real-time Efficiency)**:
   전화가 울리는 도중(최대 5초 내)에 수천 개의 연락처에서 정보를 찾아 화면에 띄워야 합니다. Flutter는 브릿지 지연이 없는 컴파일 언어의 특성상 더 빠른 응답 속도를 보장합니다.

2. **단일 UI 코드베이스**:
   Android의 오버레이(Overlay) UI와 iOS의 상세 화면이 최대한 동일한 사용자 경험을 제공해야 합니다. Flutter는 두 플랫폼에서 시각적으로 100% 동일한 결과물을 내기 매우 쉽습니다.

3. **네이티브 기능 확장성**:
   `CallKit`(iOS)과 `CallScreeningService`(Android)는 결국 네이티브 코드로 작성해야 합니다. Flutter의 `Platform Channels`는 이 복잡한 코드를 메인 앱과 연결하는 데 매우 견고한 아키텍처를 제공합니다.

## 4. 최종 결론
사용자 및 개발팀의 기존 역량(React/JS)을 고려하더라도, **시스템 통합의 깊이**와 **성능적 요구사항**을 종합했을 때 Flutter가 이 프로젝트에 가장 적합한 선택입니다.
