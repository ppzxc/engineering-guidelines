# Workflow 스킬 규칙

feature-pipeline 스킬을 사용하거나 구현할 때 반드시 다음 제약을 따른다.

✓ feature-pipeline이 생성/수정하는 plan은 `docs/plans/<slug>.md`에 저장할 것 [ADR-0011]
✓ feature-pipeline plan의 behavioral task는 `[TDD]` 또는 `[TDD-EXEMPT: 사유]`를 반드시 명시할 것 [ADR-0011]
✓ feature-pipeline plan의 tidying task는 `[TIDY]` 태그를 부착하고 `## Behavioral Phase`와 분리된 `## Tidying Phase` 섹션에 둘 것 [ADR-0011]
✓ feature-pipeline은 gemini-crosscheck Skill을 직접 호출하지 않고 `mcp__gemini-cli__ask-gemini`로 review-only 검증만 수행할 것 (이중 실행 방지) [ADR-0011]
✓ feature-pipeline은 S1 grill-me 완료 직후 `workflow:karpathy-original` 스킬을 1회 invoke할 것 [ADR-0018]
✓ feature-pipeline의 S3 plan 작성 시 Simplicity First 가드레일을 확인할 것 (추측성 추상화, 요청 외 기능 금지) [ADR-0018]
✓ feature-pipeline의 S5 TDD 게이트는 태그([TDD], [TIDY] 등)와 TDD 구조의 존재 여부만 확인하며, 엄격한 §4 검사 책임은 S6로 이관됨을 인지할 것 [ADR-0018]
✓ feature-pipeline의 S5 TDD 게이트에서 오류 발견 시 스스로 수정(자동 재생성)을 시도하지 말고 즉시 사용자에게 에스컬레이션할 것
✓ feature-pipeline의 S6 subagent 지시에 workflow:karpathy-original 원문 11원칙 전체를 verbatim paste할 것 (§1~§11 강제력은 이 paste에 100% 의존) [ADR-0018]
✓ feature-pipeline S6 subagent paste 본문과 workflow:karpathy-original SKILL.md 본문은 1자도 다르지 않을 것 (drift 금지) [ADR-0018]
✓ feature-pipeline S3 시작 전 cwd가 worktree 경로와 일치하는지 `pwd && git rev-parse --show-toplevel` 로 검증할 것 [ADR-0014]
✓ feature-pipeline S4 완료 후 plan 파일에 `## Cross-check Feedback` 섹션이 존재하는지 grep으로 확인할 것 [ADR-0014]
✓ feature-pipeline Gate 1/2/3에서 사용자 응답을 받기 전까지 다음 단계를 시작하지 말 것 [ADR-0014]
✓ feature-pipeline은 superpowers:writing-plans 스킬을 호출하지 않고 plan을 직접 작성할 것 [ADR-0015]
✓ feature-pipeline plan 파일은 최상단에 Goal/Architecture/Tech Stack 헤더 3줄을 포함할 것 [ADR-0015]
✓ feature-pipeline plan의 각 task는 Files: Create/Modify/Test 줄로 파일 매핑을 명시할 것 [ADR-0015]
✓ feature-pipeline은 ExitPlanMode 흐름에 진입하지 않을 것 (Gate 3 승인은 AskUserQuestion만으로 처리) [ADR-0016]
✓ feature-pipeline plan 파일에 grill-me 대화 본문을 누적하지 않을 것 (결정/태스크/cross-check 요약만, 8KB 이하 유지) [ADR-0016]
