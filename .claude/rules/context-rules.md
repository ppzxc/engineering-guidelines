# Context 플러그인 규칙

context 플러그인 스킬을 사용하거나 수정할 때 반드시 다음 제약을 따른다.

✓ 산출물은 `docs/context/{TASK_NAME}/`의 4파일(spec/plan/tasks/context.md)로 고정할 것 [ADR-0027]
✓ TASK_NAME은 kebab slug으로 정규화하여 경로 traversal·특수문자를 제거할 것 [ADR-0027]
✓ workflow 플러그인 산출물(`docs/superpowers/plans/`)과 context 산출물(`docs/context/{TASK}/`)의 경로 경계를 혼용하지 말 것 [ADR-0027]
✓ 래핑 스킬명은 실제 등록명(`superpowers:brainstorming`/`grill-me`/`superpowers:writing-plans`)을 추론 없이 정확히 명시할 것 [ADR-0027]
✓ context:plan에서 brainstorming → writing-plans 자동연계를 허용할 것 (HARD-GATE 차단 금지) [ADR-0030]
✓ context:plan의 탐색 단계(grill-me·brainstorming)는 플랜모드 안에서 진행하고, spec 내용은 플랜 파일에 기록한 뒤 ExitPlanMode로 사람 리뷰 게이트를 실행할 것 [ADR-0030]
✓ `context.md` 최상단에 `<!-- last_updated: ISO-8601(UTC) -->` 라인을 두고 update 시 갱신할 것 [ADR-0027]
✓ `context:guard`는 플랜모드에서 `.claude/settings.json` 쓰기를 거부하고, 기존 Stop hook을 덮어쓰지 않고 병합할 것 [ADR-0028]
✓ Stop hook은 IDE·툴 아티팩트 변경을 무시하고, 변경 코드와 매칭되는 관련 active context에만 발동할 것 [ADR-0031]
✓ Stop hook staleness 판정 시 decision:block+reason으로 /context:update 자동 실행을 유도하되, stop_hook_active 재진입은 즉시 차단할 것 [ADR-0031]
✓ Tier 2 cross-check는 비-Claude CLI(agy/gemini/codex)에 위임하고 Claude 자기 자신 호출을 금지할 것 [ADR-0029]
✓ 멀티 LLM 입력을 CLI 인자 직접 보간 없이 안전하게 전달할 것 [ADR-0029]
✓ CLI 부재·sentinel(NOT_FOUND/TIMEOUT/ERROR) 시 Claude self-generate로 fallback하고 리뷰 모델명을 provenance에 기록할 것 [ADR-0029]
✓ context:plan 검증 게이트는 spec 사람 리뷰(ExitPlanMode)와 plan GAN cross-check 2개만 사용할 것 (self-review 금지) [ADR-0030]
