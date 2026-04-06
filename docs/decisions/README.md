# Architecture Decision Records

이 디렉토리는 프로젝트의 주요 결정(ADR)을 기록한다.
형식은 [MADR 4.0](https://adr.github.io/madr/)을 따른다.

## 인덱스

| ADR | 상태 | 주제 |
|-----|------|------|
| [ADR-0001](0001-docs-plugin-adr-madr-skills.md) | accepted | docs 플러그인 ADR/MADR 스킬 채택 |
| [ADR-0002](0002-plugin-skill-evaluation-system.md) | accepted | 플러그인별 독립 평가 시스템 채택 |
| [ADR-0003](0003-adopt-rfc-6648-for-custom-http-header-naming.md) | accepted | RFC 6648 커스텀 HTTP 헤더 네이밍 채택 |
| [ADR-0004](0004-adopt-non-crud-action-endpoint-pattern.md) | superseded by ADR-0005 | Non-CRUD Action Endpoint 패턴 |
| [ADR-0005](0005-adopt-aip-resource-oriented-design-and-colon-custom-methods.md) | accepted | AIP 리소스 중심 설계 및 콜론 커스텀 메서드 채택 |
| [ADR-0006](0006-git-plugin-rename-and-consolidation.md) | accepted | Git 플러그인 리네이밍 및 통합 |
| [ADR-0007](0007-adopt-aip-resource-lifecycle-patterns.md) | accepted | AIP 리소스 수명주기 패턴 2차 도입 |
| [ADR-0008](0008-adopt-aip-filter-fieldmask-partial-response.md) | accepted | AIP filter 표현식, updateMask 필수화, Partial Response 도입 |
| [ADR-0009](0009-adopt-strict-api-security-and-versioning-rules.md) | accepted | 엄격한 API 보안 및 버저닝 규칙 도입 (OWASP Top 10, 하위 호환성) |
| [ADR-0010](0010-adopt-tiered-api-profile-system.md) | accepted | API 플러그인 계층화 프로필 시스템 도입 (T1/T2/T3 점진적 채택) |

## 새 ADR 추가

`.claude/rules/rules-maintenance.md`의 MADR 작성 형식을 따른다.
번호는 현재 최대값 + 1, 파일명은 `NNNN-<kebab-case-title>.md`.

- 옵션이 3개 이상이거나 트레이드오프가 중요한 결정: `0000-template.md` (full)
- 옵션이 2개 이하이고 트레이드오프가 경미한 결정: `0000-template-minimal.md` (minimal)
