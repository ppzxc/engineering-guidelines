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
- **FR-002**: `updateMask`에 명시되어 있고 Request Body에 해당 필드가 `"field": null`로 포함되어 있거나, `updateMask`에 명시되어 있으나 Request Body에서 필드가 아예 생략(누락)된 경우 데이터를 삭제(Clear/Null)하는 AIP-134 표준 처리 가이드를 문서화한다.
- **FR-003**: `updateMask`에 지정되지 않은 필드는 Request Body에 어떤 값이 오더라도 수정 대상에서 완전히 제외하고 변경하지 않는다.
- **FR-004**: 점(.) 표기법(dot notation, 예: `profile.bio`)을 통해 중첩 객체의 특정 하위 세부 필드만 타겟하여 개별적으로 값을 초기화(Clear)할 수 있는 설계 가이드를 명시한다.
- **FR-005**: `updateMask`에 유효하지 않거나 존재하지 않는 리소스 필드 경로가 지정된 경우, 전체 요청을 처리하지 않고 `400 Bad Request` 에러를 반환하는 명세를 가이드라인에 정의한다.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: PATCH API 데이터 초기화 오동작 건수 0%를 달성하기 위한 명확하고 상세한 아키텍처적 규칙을 수립한다.
- **SC-002**: 개발자들이 공통 라이브러리 작성 시 참고할 수 있도록 명확한 입력/출력 매핑 시나리오를 명시한다.

## Assumptions

- Assumed target integration behaves according to standard conventions.

## Clarifications

### Session 2026-06-09

- Q: `updateMask`에는 필드명이 지정되어 있으나, Request Body에서 해당 필드가 아예 누락(생략)된 경우 API 가이드라인상 어떻게 처리하도록 정의해야 할까요? → A: AIP-134 표준을 준수하여 해당 필드를 묵시적으로 초기화(clear/null)한다.
- Q: 1단계 깊이의 최상위 필드가 아닌, 중첩 객체의 내부 필드(예: `user.profile.bio` 또는 `profile.bio`)를 초기화하려 할 때, 점(.) 표기법(dot notation)을 통한 중첩 필드 단위의 초기화 가이드를 명시해야 할까요? → A: 점(.) 표기법(dot notation)을 통해 중첩 객체의 하위 필드 개별 초기화를 명시적으로 지원한다.
- Q: API 명세에 정의되어 있지 않은 존재하지 않는 잘못된 필드명이 `updateMask`에 포함되어 전달된 경우, 서버는 어떻게 대응해야 할까요? → A: 잘못된 요청으로 규정하여 전체 요청을 즉시 거부하고 에러를 반환한다 (400 Bad Request / INVALID_ARGUMENT).