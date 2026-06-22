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

---

## [TC-005] 다중 LLM 피어 오케스트레이션 및 샌드박스 웜업 검증
*   **평가 대상**: `plugins/llm/skills/peer-orchestrator/SKILL.md`
*   **검증 조건**:
    - 샌드박스 락 방지를 위해 메인 프로세스에서 피어 CLI(claude, agy, openai)의 버전을 `timeout 3 <cli> --version`으로 조회하여 샌드박스 승인을 사전에 얻도록 규정하는지 검증.
    - `invoke_subagent`를 통해 Self-Review와 Peer-Review 서브에이전트를 병렬 구동하는 절차가 명시되었는지 검증.
    - 30초 스케줄 기반의 서브에이전트 감시 폴링 및 최대 5분(300초) 타임아웃 규칙이 정의되었는지 검증.
*   **기대 상태**: **[PASSED]** (검증 완료)

---

## [TC-006] CLI 센티널 에러 감지 및 우선순위 폴백 검증
*   **평가 대상**: `plugins/llm/skills/peer-orchestrator/SKILL.md`
*   **검증 조건**:
    - CLI 실행 오류 발생 시 센티널 신호(`CLI_NOT_FOUND`, `CLI_TIMEOUT`, `CLI_ERROR`)를 감지하고 파싱하는지 검증.
    - 실패 시 우선순위 체인(`claude ➡️ agy ➡️ openai`)에 따라 다음 피어로 자동 스위칭하는 폴백 규칙이 정의되었는지 검증.
*   **기대 상태**: **[PASSED]** (검증 완료)

---

## [TC-007] 중요도 기반 하이브리드 Findings 병합 검증
*   **평가 대상**: `plugins/llm/skills/peer-orchestrator/SKILL.md`
*   **검증 조건**:
    - 수집된 findings 중 `Critical/High` 등급은 합집합(Union) 처리하고, `Medium/Low` 등증은 양쪽에서 중복 지적된 항목만 살리는 교집합(Intersection)으로 머지하는 규칙이 명문화되었는지 검증.
*   **기대 상태**: **[PASSED]** (검증 완료)

---

## [TC-008] 로컬 호스트 LLM 제외 및 llm:auto 위임 검증
*   **평가 대상**: `plugins/llm/skills/peer-orchestrator/SKILL.md` 및 `plugins/llm/skills/auto/SKILL.md`
*   **검증 조건**:
    - 현재 실행 중인 호스트 CLI(LOCAL)를 감지하여 폴백 목록에서 동적으로 중복 배제하는지 검증.
    - `llm:auto` 스킬이 자체 로직을 제거하고 `llm:peer-orchestrator`에 오케스트레이션을 위임(Delegate)하도록 리팩토링되었는지 검증.
*   **기대 상태**: **[PASSED]** (검증 완료)

---

## [TC-009] 모든 스킬의 모델 호출 허용 검증
*   **평가 대상**: 모든 `plugins/*/skills/*/SKILL.md`
*   **검증 조건**:
    *   모든 스킬 파일의 프론트매터(Frontmatter)에 `disable-model-invocation: true` 설정이 제거되어 모델 호출 및 슬래시 명령이 정상 동작하는지 확인.
*   **기대 상태**: **[PASSED]** (검증 완료 - disable-model-invocation: true 제거됨)


