# Workflow 스킬 규칙

feature-pipeline 스킬을 사용하거나 구현할 때 반드시 다음 제약을 따른다.

✓ feature-pipeline이 생성/수정하는 plan은 `docs/plans/<slug>.md`에 저장할 것 [ADR-0011]
✓ feature-pipeline plan의 behavioral task는 `[TDD]` 또는 `[TDD-EXEMPT: 사유]`를 반드시 명시할 것 [ADR-0011]
✓ feature-pipeline plan의 tidying task는 `[TIDY]` 태그를 부착하고 `## Behavioral Phase`와 분리된 `## Tidying Phase` 섹션에 둘 것 [ADR-0011]
✓ feature-pipeline은 gemini-crosscheck Skill을 직접 호출하지 않고 `mcp__gemini-cli__ask-gemini`로 review-only 검증만 수행할 것 (이중 실행 방지) [ADR-0011]
