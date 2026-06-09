# Research Report: W3C Trace Context Modernization and Migration Strategy

## Executive Summary
기존 커스텀 `Request-Id` 헤더 방식에서 탈피하여 글로벌 표준인 W3C Trace Context 규격(`traceparent`, `tracestate`)을 도입하고, 대규모 분산 아키텍처 환경의 안전성을 보장하기 위해 점진적 마이그레이션 및 예외 처리 정책을 제정합니다.

---

## Decision 1: W3C Trace Context 표준 규격 도입
*   **Decision**: 분산 추적 헤더의 기본 표준으로 W3C Trace Context 규격(`traceparent` 및 `tracestate`)을 전격 채택한다.
*   **Rationale**:
    *   **표준 상호운용성**: OpenTelemetry 및 Datadog, AWS X-Ray, GCP Cloud Trace 등 현대 APM 벤더와의 무설정(Zero-config) 연동을 가능하게 합니다.
    *   **구조적 모니터링**: 단일 식별자인 Request-Id와 달리 `traceparent`는 Trace ID(전체 요청 식별), Parent ID(개별 스팬/구간 식별), Trace Flags(샘플링 여부)를 포함하여 호출 계층 구조를 명확히 표현할 수 있습니다.
*   **Alternatives Considered**:
    *   *Alternative 1 (Zipkin B3 propagation headers)*: `X-B3-TraceId`, `X-B3-SpanId` 등을 사용하는 B3 규격을 검토했으나, 최신 OpenTelemetry 표준에서 W3C를 기본 규격으로 채택하고 있으므로 W3C가 더 미래지향적입니다.

---

## Decision 2: 기존 `Request-Id` 하위 호환성(Dual Propagation) 유지
*   **Decision**: 과도기적 안정성을 위해 신규 `traceparent`/`tracestate` 규격과 기존 커스텀 `Request-Id` 헤더를 동시에 전파(Dual Propagation)하도록 가이드한다.
*   **Rationale**:
    *   **점진적 배포 지원**: MSA 구조에서 수십 개의 개별 서비스를 동시에 배포하는 것은 불가능합니다. 신/구 헤더를 병행 지원함으로써 배포 순서와 무관하게 추적 일관성을 유지합니다.
*   **Alternatives Considered**:
    *   *Alternative 1 (즉시 폐기 및 표준 단독 강제)*: `Request-Id` 가이드를 일괄 제거하고 W3C만 허용할 경우, 미배포된 레거시 시스템 간 통신에서 트레이스 단절 또는 누락 현상이 유입되므로 기각되었습니다.

---

## Decision 3: 유효하지 않은 `traceparent` 폴백 정책 (Restart Trace + Warning Log)
*   **Decision**: 유효하지 않은(Malformed) `traceparent` 수신 시 표준에 명시된 대로 해당 헤더를 무시하고 새로운 `traceparent`를 발급(Restart Trace)하며, 사후 진단을 위해 경고 로그(Warning Log)를 기록하도록 규정한다.
*   **Rationale**:
    *   **서비스 가용성 우선**: 비정상적인 트레이스 헤더 때문에 API 요청 자체가 실패(Reject)하면 비즈니스 장애로 번집니다. 시스템 가동성 유지가 항상 최우선입니다.
    *   **이상 감지**: 조용히 무시하기만 하면 업스트림 모듈의 파싱 버그나 인프라 설정 오류를 인지할 수 없으므로 경고 로그를 명문화합니다.
*   **Alternatives Considered**:
    *   *Alternative 1 (요청 거부 - HTTP 400)*: 추적 일관성을 강제하기 위해 에러를 반환하는 옵션을 검토했으나, 비즈니스 안전성을 해치므로 기각되었습니다.

---

## Decision 4: 최초 진입점(Gateway)에서의 헤더 발급 책임
*   **Decision**: 외부 요청이 최초로 유입되는 API Gateway 또는 외곽 Edge 서비스가 트레이스 컨텍스트의 Originator 역할을 수행하며, `traceparent` 헤더가 없는 경우 즉시 새로 생성하여 하위로 전파할 책임을 갖는다.
*   **Rationale**:
    *   **일관된 트래킹 경계**: 요청 유입 시점부터의 전체 수명 주기를 일관되게 추적하기 위해서는 진입 장벽에서의 발급 제어가 필수적입니다.
*   **Alternatives Considered**:
    *   *Alternative 1 (개별 서비스의 필요시 자율 발급)*: 이 경우 전체 트레이스가 아닌 개별 서브 트리가 각각 다른 Trace ID로 분절되어 전체 시스템 모니터링이 불가능해집니다.
