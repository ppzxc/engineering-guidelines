# API Rules: Security, Versioning & Distributed Tracing

이 규칙 문서는 API 아키텍처 정합성 검증 및 보안 강화를 위해 준수해야 하는 강제 규칙(MUST)을 정의합니다. 모든 규칙에는 아키텍처 결정 기록(ADR) 및 중요도 등급(Tier 1, Tier 2, Tier 3) 태그가 포함되어야 합니다.

---

## 1. Security & Versioning (OWASP Top 10 & API Controls)

*   **API-SEC-001 (BOLA Prevention)**: 모든 자원 접근 시 요청자의 식별자와 대상 자원의 소유권을 매핑하여 검증해야 하며, 단순 식별자 변조를 통한 타인 자원 접근(BOLA)을 원천 차단해야 한다. `[T1]` `[ADR-0009]`
*   **API-SEC-002 (BOPA Prevention)**: 자원 생성 및 수정(POST/PATCH) 시 화이트리스트 기반 필드 바인딩만 허용하며, 정의되지 않은 속성을 통한 대량 할당(Mass Assignment/BOPA) 취약점을 차단해야 한다. `[T1]` `[ADR-0009]`
*   **API-VER-001 (Version Header Enforcement)**: 하위 호환성을 파괴하는 모순을 방지하기 위해 모든 API 요청은 지정된 버전 헤더(예: `API-Version` 또는 Accept Header 미디어 타입 버전)를 필수적으로 포함해야 한다. 헤더 누락 시 디폴트 처리를 하지 않고 `400 Bad Request` 에러를 반환해야 한다. `[T1]` `[ADR-0009]`

---

## 2. Distributed Tracing Rules (W3C Trace Context)

분산 환경에서의 모니터링 완결성과 안정성을 보장하기 위해 다음 분산 추적 규칙을 엄격히 준수해야 합니다.

*   **API-TRC-001 (W3C Standard Compliance)**: 모든 마이크로서비스 간 HTTP 호출 시 W3C Trace Context 규격인 `traceparent` 및 `tracestate` 헤더 전파 규격을 준수해야 한다. `[T1]` `[ADR-0009]`
    *   `traceparent` 포맷은 `00-{32hex_trace_id}-{16hex_parent_id}-{2hex_trace_flags}` 형식과 55자 소문자 16진수 규격을 충족해야 한다.
*   **API-TRC-002 (Dual Propagation for Backward Compatibility)**: 기존 모듈 및 레거시 시스템과의 점진적 마이그레이션 및 연동 안정성을 보장하기 위해, 신규 `traceparent`/`tracestate` 표준 헤더와 함께 기존 커스텀 `Request-Id` (UUID v4) 헤더도 동시에 전파(Dual Propagation)해야 한다. `[T1]` `[ADR-0009]`
*   **API-TRC-003 (Invalid Header Fallback)**: 수신된 `traceparent` 헤더가 W3C 표준 규격에 맞지 않거나 유효하지 않은 경우, API 요청을 거부(Reject)하거나 에러를 반환하지 않고 무시해야 한다. 대신, 새로운 `traceparent`를 즉시 신규 발급(Restart Trace)하여 다운스트림으로 전파하고, 시스템 디버깅 및 이상 감지를 위해 경고 로그(Warning Log)를 기록해야 한다. `[T1]` `[ADR-0009]`
*   **API-TRC-004 (Originator Responsibility at Entrypoint)**: 시스템 외부에서 유입되는 최초 요청에 `traceparent` 헤더가 없는 경우, API Gateway 또는 시스템의 외부 요청을 직접 수신하는 최초 서비스가 추적 컨텍스트의 시작자(Originator)가 되어 새로운 `traceparent` 및 `Request-Id` 헤더를 발급하고 전파해야 한다. `[T1]` `[ADR-0009]`
