# Feature Specification: feat: provide fallback path pattern for custom actions

**Feature Branch**: `004-fallback-path-custom-actions`

**Created**: 2026-06-09

**Status**: Rejected / Cancelled (Decided to maintain strict colon-based custom methods without exception rules)

**Input**: User description: GitHub Issue #129: feat: provide fallback path pattern for custom actions\n\nExpress/Rails 등의 프레임워크 라우팅 충돌 및 특정 방화벽(WAF) 장비에서 URL 경로 세그먼트 내부의 콜론(:)을 오진하여 차단하는 문제를 방지하기 위해, 콜론 구문 외에 하이픈 서브패스(예: /orders/{id}/cancel) 형태의 대체(Fallback) 경로 패턴 규격을 가이드라인에 명시합니다.

## Clarifications

### Session 2026-06-09
- Q: 대체 경로 패턴의 정확한 URL 및 명명 규칙 → A: 가이드라인 및 ADR에 대체 경로 패턴이나 예외 규정을 전혀 추가하지 않는다. 콜론 기반 커스텀 메서드(:ACTION VERB)만 단일 표준으로 고수하며, 예외 사항에 대한 언급 자체를 배제한다.

## User Scenarios & Testing *(mandatory)*\n\n### User Story 1 - 콜론 차단 장비 대응을 위한 하이픈 대체 경로 패턴 적용 (Priority: P1)

API 클라이언트 및 게이트웨이가 특정 보안 장비(WAF)나 웹 프레임워크 한계로 인해 콜론(:) 세그먼트를 사용할 수 없는 환경에서도, 대체 경로 패턴을 통해 안전하게 커스텀 액션을 유발할 수 있어야 한다.

**Why this priority**: WAF의 콜론 오진 차단 이슈 및 라우터 매칭 충돌을 방지하기 위한 크리티컬한 호환성 확보 요건임.

**Independent Test**: WAF 장비가 콜론 구문을 차단할 때 `/orders/{id}/cancel`과 같은 하이픈/대체 서브패스 URL 패턴으로 설계된 API 사양서를 확인하고 검증한다.

**Acceptance Scenarios**:

1. **Given** 콜론 기반의 커스텀 메서드 사양을 사용하는 환경에서, **When** 특정 WAF 장비가 URL 콜론을 오진하여 차단하는 이슈가 발생할 때, **Then** 대안으로 `/orders/{id}/cancel` 형태의 대체 서브패스 패턴 규격을 사용할 수 있게 가이드라인이 허용한다.\n\n## Requirements *(mandatory)*\n\n### Functional Requirements

- **FR-001**: [SKILL.md](file:///home/ppzxc/projects/engineering-guidelines/plugins/guideline/skills/restful-api/SKILL.md)에 예외 규정이나 대체 경로 규격을 추가하지 않고 기존 콜론 표준을 그대로 유지한다.
- **FR-002**: [docs/adr/0005-adopt-aip-resource-oriented-design-and-colon-custom-methods.md](file:///home/ppzxc/projects/engineering-guidelines/docs/adr/0005-adopt-aip-resource-oriented-design-and-colon-custom-methods.md)의 결정을 변경 없이 그대로 유지한다.\n\n## Success Criteria *(mandatory)*\n\n### Measurable Outcomes\n\n- **SC-001**: Implement the criteria outlined in acceptance scenarios.\n\n## Assumptions\n\n- Assumed target integration behaves according to standard conventions.\n