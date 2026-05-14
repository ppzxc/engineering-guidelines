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
✓ feature-pipeline S3 시작 전 cwd가 worktree 경로와 일치하는지 `pwd && git rev-parse --show-toplevel` 로 검증할 것 [ADR-0014]
✓ feature-pipeline S4 완료 후 plan 파일에 `## Cross-check Feedback` 섹션이 존재하는지 grep으로 확인할 것 [ADR-0014]
✓ feature-pipeline Gate 1/2/3에서 사용자 응답을 받기 전까지 다음 단계를 시작하지 말 것 [ADR-0014]
