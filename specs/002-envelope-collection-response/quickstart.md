# Quickstart Validation Guide: JSON HAL Collection Response

본 피처의 변경사항이 정상적으로 적용되었는지 검증하기 위한 시나리오 가이드입니다.

## Prerequisites

- [ ] Git이 로컬에 설치되어 있어야 함
- [ ] 현재 브랜치가 `002-envelope-collection-response` 인지 확인

## Verification Scenarios

### Scenario 1: TDD 평가 케이스 검증

1. **설정 및 검증 명령어**:
   - `docs/evaluation/test-cases.md` 파일 내에 JSON HAL 컬렉션 응답 가이드라인 검증을 위한 테스트 케이스가 작성되어 있는지 확인합니다.
2. **기대 결과**:
   - 테스트 케이스에 명시된 "JSON HAL HATEOAS 및 커스텀 메타데이터 규격"이 존재해야 합니다.

### Scenario 2: 가이드라인 가독성 및 정합성 검증

1. **검증 대상**:
   - [restful-api SKILL.md](../../plugins/guideline/skills/restful-api/SKILL.md) 파일의 `## Collections & Pagination` 섹션을 수동 검토합니다.
2. **검증 조건**:
   - Top-level Array 단독 반환 규정이 완화되고, JSON HAL(`application/hal+json`) 포맷을 표준 봉투(Envelope) 패턴으로 수용했는지 확인합니다.
   - 응답 필드로 `_links`, `_embedded` 및 `totalCount`가 기술되어 있는지 확인합니다.

### Scenario 3: 버젼 동기화 확인

1. **검증 파일**:
   - [plugin.json](../../plugins/guideline/plugin.json), [README.md](../../README.md), [.claude-plugin/marketplace.json](../../.claude-plugin/marketplace.json) 세 곳의 버전이 `0.4.0`으로 정상 업그레이드되었는지 확인.
