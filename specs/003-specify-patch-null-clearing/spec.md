# Feature Specification: feat: specify null-clearing behavior in PATCH updateMask

**Feature Branch**: `003-specify-patch-null-clearing`

**Created**: 2026-06-09

**Status**: Draft

**Input**: User description: GitHub Issue #128: feat: specify null-clearing behavior in PATCH updateMask\n\nJSON 필드 생략(Omit null) 원칙을 준수하는 과정에서 발생하는 PATCH의 데이터 초기화(Clearing/Nulling) 모순을 해결하기 위해, updateMask를 사용할 때 특정 필드를 명시적으로 null 처리하는 구체적인 동작 명세를 추가합니다.

## User Scenarios & Testing *(mandatory)*\n\n### User Story 1 - 특정 필드의 명시적 null 처리 (Priority: P1)

API 사용자가 PATCH 요청을 보낼 때 리소스 내 특정 필드의 값을 완전히 지우기(null 또는 초기화) 위해 updateMask와 null 필드를 명확하게 조합하여 호출할 수 있어야 한다.

**Why this priority**: 부분 수정(PATCH) 환경에서 의도치 않은 필드 값 누락과 의도된 필드 초기화(Nulling) 간의 기능적 충돌을 해소하기 위해 필수적임.

**Independent Test**: `updateMask`에 명시된 필드가 Request Body에 `"field": null`로 지정되었을 때만 데이터베이스 또는 리소스에서 해당 필드가 null로 갱신되는 로직을 정의한다.

**Acceptance Scenarios**:

1. **Given** PATCH API 설계 표준이 제공될 때, **When** 사용자가 특정 필드를 명시적으로 삭제하고자 할 때, **Then** `updateMask`에 해당 필드명을 기재하고 Request Body에 `"field": null`을 전달하도록 동작 원칙이 가이드에 정확히 명시된다.\n\n## Requirements *(mandatory)*\n\n### Functional Requirements

- **FR-001**: [SKILL.md](file:///home/ppzxc/projects/engineering-guidelines/plugins/guideline/skills/restful-api/SKILL.md) 내 PATCH 및 CRUD Behavior 섹션에 Null 값 초기화(Clearing) 명세를 추가한다.
- **FR-002**: `updateMask`에 명시되어 있고 Request Body에 해당 필드가 `"field": null`로 포함되어 있을 때만 데이터를 삭제(Clear)한다는 표준 처리 가이드를 문서화한다.\n\n## Success Criteria *(mandatory)*\n\n### Measurable Outcomes

- **SC-001**: PATCH API 데이터 초기화 오동작 건수 0%를 달성하기 위한 명확하고 상세한 아키텍처적 규칙을 수립한다.
- **SC-002**: 개발자들이 공통 라이브러리 작성 시 참고할 수 있도록 명확한 입력/출력 매핑 시나리오를 명시한다.\n\n## Assumptions\n\n- Assumed target integration behaves according to standard conventions.\n