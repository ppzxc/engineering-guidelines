# Feature Specification: feat: modernize distributed tracing headers to W3C traceparent

**Feature Branch**: `005-modernize-tracing-headers`

**Created**: 2026-06-09

**Status**: Draft

**Input**: User description: GitHub Issue #130: feat: modernize distributed tracing headers to W3C traceparent\n\n분산 마이크로서비스 환경 및 OpenTelemetry 모니터링 표준과의 원활한 상호 운용을 위해, 기존 커스텀 Request-Id 전파 모델에서 탈피하여 W3C Trace Context 규격인 traceparent 및 tracestate를 기본 분산 추적 헤더 표준으로 가이드라인 및 규칙에 통합합니다.

## Clarifications

### Session 2026-06-09
- Q: 기존 시스템 및 레거시 모듈과의 하위 호환성 유지 여부 -> A: 하위 호환성 유지 (traceparent/tracestate와 Request-Id 병행 지원)
- Q: 유효하지 않은 traceparent 헤더 수신 시의 폴백(Fallback) 정책 -> A: 트레이스 재시작(Restart Trace) 및 디버깅을 위한 경고 로그 기록
- Q: 외부 최초 요청 진입점(API Gateway 등)에서의 traceparent 신규 생성 책임 -> A: 최초 진입점 발급 및 책임 (API Gateway 등에서 새로 생성하여 전파)

## User Scenarios & Testing *(mandatory)*\n\n### User Story 1 - 마이크로서비스 통신 시 W3C traceparent 기반 분산 추적 (Priority: P1)

시스템 엔지니어 및 개발자가 분산 호출 경로 상에서 발생하는 이벤트를 하나의 트레이스로 추적하기 위해, 기존 커스텀 Request-Id 대신 W3C Trace Context 표준 규격을 기반으로 전파받아야 한다.

**Why this priority**: OpenTelemetry 및 3rd-party APM 솔루션들과 표준적이고 원활하게 연동하기 위해 필수적인 아키텍처 현대화 작업임.

**Independent Test**: 게이트웨이 및 개별 마이크로서비스 요청의 HTTP Header에서 `traceparent` 및 `tracestate` 표준 필드를 성공적으로 수신 및 전파하는 가이드라인 규칙을 검증한다.

**Acceptance Scenarios**:

1. **Given** 분산 아키텍처의 서비스 간 호출이 일어날 때, **When** 새로운 가이드를 적용하면, **Then** 시스템은 기존 커스텀 Request-Id의 하위 호환성을 유지하면서, W3C `traceparent` 및 `tracestate` 포맷의 추적 헤더 전파 규격을 병행하여 준수한다.\n\n## Requirements *(mandatory)*\n\n### Functional Requirements

- **FR-001**: [SKILL.md](file:///home/ppzxc/projects/engineering-guidelines/plugins/guideline/skills/restful-api/SKILL.md)의 Headers 섹션에 W3C `traceparent` 및 `tracestate` 전파 규격을 반영한다.
- **FR-002**: [.claude/rules/api-rules.md](file:///home/ppzxc/projects/engineering-guidelines/.claude/rules/api-rules.md) 내 분산 로깅/추적 관련 보안 및 인프라 헤더 규칙을 현대화된 표준으로 갱신한다.
- **FR-003**: 점진적 마이그레이션 및 하위 호환성을 위해 기존 커스텀 `Request-Id` 헤더도 함께 전파하는 규격을 설계한다.
- **FR-004**: 유효하지 않은 포맷의 `traceparent` 수신 시 요청을 거부하지 않고 표준에 따라 무시한 뒤 새로운 `traceparent`를 재발급(Restart Trace)하며, 디버깅을 위한 경고 로그를 남기도록 가이드라인을 작성한다.
- **FR-005**: 시스템 최초 진입점(API Gateway 등)에서 `traceparent` 헤더가 유입되지 않은 경우, 새 헤더를 발급하여 전파하는 규격을 가이드라인에 정의한다.\n\n## Success Criteria *(mandatory)*\n\n### Measurable Outcomes\n\n- **SC-001**: Implement the criteria outlined in acceptance scenarios.\n\n## Assumptions\n\n- Assumed target integration behaves according to standard conventions.\n