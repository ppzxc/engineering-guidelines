# Evaluation Test Cases: W3C Distributed Tracing Headers

이 문서는 분산 추적 헤더 현대화 가이드라인 및 규칙의 구현 적합성을 검증하기 위한 평가용 테스트 케이스입니다. (TDD 용도로 먼저 작성되어 실패 여부를 체크한 후 구현에 들어갑니다.)

---

## [TC-001] W3C traceparent 및 tracestate 표준 도입 검증
*   **평가 대상**: `plugins/guideline/skills/restful-api/SKILL.md` (Headers 섹션)
*   **검증 조건**:
    *   W3C `traceparent` 및 `tracestate` 가 기본 분산 추적 규격으로 제정되어 있는지 확인.
    *   `traceparent` 헤더의 4가지 필드 구조(`version-trace_id-parent_id-trace_flags`)와 길이(55자 소문자 16진수) 등이 명시되어 있는지 검증.
*   **기대 상태**: **[PASSED]** (검증 완료)

---

## [TC-002] 레거시 `Request-Id` 하위 호환성(Dual Propagation) 검증
*   **평가 대상**: `plugins/guideline/skills/restful-api/SKILL.md` 및 `.claude/rules/api-rules.md`
*   **검증 조건**:
    *   W3C 헤더 도입 이후에도 점진적 마이그레이션을 위해 기존 커스텀 `Request-Id` 헤더를 병행하여 전파(Dual Propagation)하도록 규정하는지 검증.
    *   신규 요청 시 두 헤더를 함께 발급 및 유지하도록 명시되어 있는지 확인.
*   **기대 상태**: **[PASSED]** (검증 완료)

---

## [TC-003] 유효하지 않은 `traceparent` 폴백 검증
*   **평가 대상**: `.claude/rules/api-rules.md` 및 `plugins/guideline/skills/restful-api/SKILL.md`
*   **검증 조건**:
    *   잘못된 포맷의 `traceparent` 헤더가 들어왔을 때, HTTP 400 등으로 요청을 거절하지 않고 무시(Ignore)하며, 새로운 `traceparent`를 재발급(Restart Trace)하여 다운스트림으로 보내는지 검증.
    *   이상 진단을 위해 시스템 로그에 경고(Warning) 로그를 남기도록 규정하는지 검증.
*   **기대 상태**: **[PASSED]** (검증 완료)

---

## [TC-004] 최초 진입점(Gateway)의 traceparent 발급 책임 검증
*   **평가 대상**: `plugins/guideline/skills/restful-api/SKILL.md` 및 `.claude/rules/api-rules.md`
*   **검증 조건**:
    *   시스템 최초 유입 요청에 헤더가 누락되었을 때, API Gateway 또는 최초 진입 컴포넌트가 `traceparent`의 생성자(Originator)가 되어 새 헤더를 발급하고 전파하는 책임 규칙이 정의되었는지 검증.
*   **기대 상태**: **[PASSED]** (검증 완료)
