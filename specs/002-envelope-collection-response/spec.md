# Feature Specification: feat: adopt envelope pattern for API collection responses

**Feature Branch**: `002-envelope-collection-response`

**Created**: 2026-06-09

**Status**: Draft

**Input**: User description: GitHub Issue #127: feat: adopt envelope pattern for API collection responses\n\nAPI 확장성 확보 및 JSON Hijacking 등의 보안 우려 완화를 위해, 기존 Top-level JSON Array 반환 강제 정책에서 탈피하여 객체 봉투 패턴({"items": [], "totalCount": N})을 공식 또는 대체 수단으로 사용할 수 있도록 가이드라인을 수정합니다.

## User Scenarios & Testing *(mandatory)*\n\n### User Story 1 - 컬렉션 조회 시 Envelope 패턴 규격 사용 (Priority: P1)

클라이언트 개발자가 목록/컬렉션 데이터를 조회할 때, Top-level JSON Array 대신 메타데이터가 포함된 Envelope 객체 포맷으로 결과를 안정적으로 제공받아 파싱할 수 있어야 한다.

**Why this priority**: JSON Hijacking 보안 취약점 예방 및 대용량 페이지네이션 메타데이터 확장을 지원하기 위한 핵심 필수 요구사항임.

**Independent Test**: API 응답 본문을 파싱할 때 `items` 배열 필드와 `totalCount` 숫자 필드가 포함된 Envelope 형태의 객체가 규격에 맞게 정의되었는지 검사한다.

**Acceptance Scenarios**:

1. **Given** 목록 응답 규격을 정의할 때, **When** Envelope 패턴 가이드를 적용하면, **Then** 최상위가 배열이 아닌 `{"items": [...], "totalCount": N}` 형태의 객체 구조로 리스폰스를 설계 및 정의한다.\n\n## Requirements *(mandatory)*\n\n### Functional Requirements

- **FR-001**: [SKILL.md](file:///home/ppzxc/projects/engineering-guidelines/plugins/guideline/skills/restful-api/SKILL.md)의 Collections & Pagination 섹션에서 Top-level JSON Array 단독 반환 강제 규칙을 완화한다.
- **FR-002**: 메타데이터를 Response Body에 Envelope 형태로 실어 보낼 수 있는 표준 JSON 포맷 명세를 가이드라인에 규정한다.\n\n## Success Criteria *(mandatory)*\n\n### Measurable Outcomes

- **SC-001**: 컬렉션 API의 90% 이상이 Top-level Array 방식 대신 Envelope 패턴을 적용할 수 있는 설계적 유연성을 보장받는다.
- **SC-002**: 프런트엔드/백엔드 간 컬렉션 파싱 충돌율을 0%로 만들기 위한 표준화된 Response 필드 명세를 확보한다.\n\n## Assumptions\n\n- Assumed target integration behaves according to standard conventions.\n