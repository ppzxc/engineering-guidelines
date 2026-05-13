# Workflow 스킬 규칙

feature-pipeline 스킬을 사용하거나 구현할 때 반드시 다음 제약을 따른다.

✓ feature-pipeline이 생성/수정하는 plan은 `docs/plans/<slug>.md`에 저장할 것 [ADR-0011]
✓ feature-pipeline plan의 behavioral task는 `[TDD]` 또는 `[TDD-EXEMPT: 사유]`를 반드시 명시할 것 [ADR-0011]
✓ feature-pipeline plan의 tidying task는 `[TIDY]` 태그를 부착하고 `## Behavioral Phase`와 분리된 `## Tidying Phase` 섹션에 둘 것 [ADR-0011]
✓ feature-pipeline은 gemini-crosscheck Skill을 직접 호출하지 않고 `mcp__gemini-cli__ask-gemini`로 review-only 검증만 수행할 것 (이중 실행 방지) [ADR-0011]
✓ feature-pipeline은 S1 grill-me 완료 직후 `andrej-karpathy-skills:karpathy-guidelines` 스킬을 1회 invoke할 것 (실패 시 경고 후 계속) [ADR-0013]
✓ feature-pipeline의 S3 plan 작성 시 Simplicity First 가드레일을 확인할 것 (추측성 추상화, 요청 외 기능 금지) [ADR-0013]
✓ feature-pipeline의 S5 TDD 게이트는 각 [TDD] task에 검증 가능한 성공 기준이 있는지 확인할 것 [ADR-0013]
✓ feature-pipeline의 S6 subagent 지시에 Surgical Changes 가드레일을 포함할 것 (변경된 줄 모두 요청으로부터 추적 가능해야 함) [ADR-0013]
