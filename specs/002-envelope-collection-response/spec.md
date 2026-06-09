# Feature Specification: feat: adopt envelope pattern for API collection responses

**Feature Branch**: `002-envelope-collection-response`

**Created**: 2026-06-09

**Status**: Draft

**Input**: User description: GitHub Issue #127: feat: adopt envelope pattern for API collection responses\n\nAPI 확장성 확보 및 JSON Hijacking 등의 보안 우려 완화를 위해, 기존 Top-level JSON Array 반환 강제 정책에서 탈피하여 객체 봉투 패턴({"items": [], "totalCount": N})을 공식 또는 대체 수단으로 사용할 수 있도록 가이드라인을 수정합니다.\n\n사용자 추가 사양: application/hal+json 으로 대표되는 HATEOAS 방식으로 고정. IANA 표준으로 제정되어있어 표준 지향 관점에 맞음. draft-kelly-json-hal-11 문서를 기반으로 하되, _links, _embedded 필드 외에 확장 가능하게 열어둔 항목을 활용하여 커스텀 메타데이터 필드도 수용할 수 있도록 함.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - JSON HAL 포맷 기반 컬렉션 데이터 조회 (Priority: P1)

클라이언트 개발자가 목록/컬렉션 데이터를 조회할 때, `application/hal+json` 표준에 따라 `_links`와 `_embedded`를 포함하고 페이지네이션 메타데이터가 최상위에 기술된 Envelope 형태로 조회할 수 있어야 한다.

**Why this priority**: IANA 표준 규격인 JSON HAL을 적용하여 HATEOAS 원칙을 충족하고 보안 및 확장성을 강화하기 위한 최우선 설계 기준임.

**Independent Test**: API 응답의 Content-Type이 `application/hal+json`인지 확인하고, 본문 구조에 `_links`, `_embedded` 및 `totalCount`가 적절히 포함되어 구조를 만족하는지 검사한다.

**Acceptance Scenarios**:

1. **Given** 목록 응답 규격을 정의할 때, **When** JSON HAL 가이드를 적용하면, **Then** 응답 본문은 최상위 배열 대신 `{"_links": {...}, "_embedded": { "items": [...] }, "totalCount": N}` 형태의 JSON HAL 구조로 설계된다.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: [SKILL.md](file:///home/ppzxc/projects/engineering-guidelines/plugins/guideline/skills/restful-api/SKILL.md)의 Collections & Pagination 섹션에서 Top-level JSON Array 단독 반환 강제 규칙을 변경하여 JSON HAL (`application/hal+json`)을 표준으로 수용한다.
- **FR-002**: JSON HAL의 `_links` (self, next, prev, first, last) 및 `_embedded` 구조를 명시한다.
- **FR-003**: HAL draft 규격을 기반으로 하되, `totalCount` 등 커스텀 메타데이터 확장을 허용하는 표준 JSON 포맷 명세를 가이드라인에 규정한다.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 컬렉션 API 설계가 IANA JSON HAL 표준(draft-kelly-json-hal-11)을 준수하도록 가이드가 갱신된다.
- **SC-002**: 프런트엔드/백엔드 간 컬렉션 파싱 충돌율을 0%로 만들기 위해 표준화된 `application/hal+json` 예시 코드를 포함한다.

## Assumptions

- JSON HAL 표준을 준수하지만, 기존 클라이언트 호환성을 고려하여 기존 Link 헤더 방식도 필요시 하이브리드로 사용하거나 점진적으로 전환할 수 있음을 가이드라인에 고려한다.