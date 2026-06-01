# Context 플러그인 규칙

context 플러그인 스킬을 사용하거나 수정할 때 반드시 다음 제약을 따른다.

✓ 산출물은 `docs/context/{TASK_NAME}/`의 4파일(spec/plan/tasks/context.md)로 고정할 것 [ADR-0027]
✓ TASK_NAME은 kebab slug으로 정규화하여 경로 traversal·특수문자를 제거할 것 [ADR-0027]
✓ TASK_NAME 정규화 결과가 빈 문자열이면 즉시 오류 처리할 것 (한글·이모지 전용 입력 방어, 빈 경로 `docs/context//` 생성 금지) [ADR-0027]
✓ workflow 플러그인 산출물(`docs/superpowers/plans/`)과 context 산출물(`docs/context/{TASK}/`)의 경로 경계를 혼용하지 말 것 [ADR-0027]
✓ 래핑 스킬명은 실제 등록명(`superpowers:brainstorming`/`grill-me`/`superpowers:writing-plans`)을 추론 없이 정확히 명시할 것 [ADR-0027]
✓ context:plan에서 brainstorming → writing-plans 자동연계를 허용할 것 (HARD-GATE 차단 금지) [ADR-0030]
✓ context:plan의 모든 설계(spec/plan/tasks/GAN)는 ExitPlanMode 前 플랜모드(Opus)에서 수행하고, spec 사람 리뷰는 AskUserQuestion으로(ExitPlanMode 비사용), ExitPlanMode는 완성된 설계의 최종 전사 릴리스 게이트로만 호출할 것 [ADR-0030][ADR-0041]
✓ `context.md` 최상단에 `<!-- last_updated: ISO-8601(UTC) -->` 라인을 두고 **생성·update 시 실제 타임스탬프로 충전**할 것 (플레이스홀더 잔류 금지 — resume/update가 이 주석을 sort로 활성 task 선택에 사용) [ADR-0027]
✓ `context:guard`는 플랜모드에서 `.claude/settings.json` 쓰기를 거부하고, 기존 Stop hook을 덮어쓰지 않고 병합할 것 [ADR-0028]
✓ Stop hook은 IDE·툴 아티팩트 변경을 무시하고, 변경 코드와 매칭되는 관련 active context에만 발동할 것 [ADR-0031]
✓ Stop hook staleness 판정 시 decision:block+reason으로 /context:update 자동 실행을 유도하되, stop_hook_active 재진입은 즉시 차단할 것 [ADR-0031]
✓ Tier 2 cross-check는 비-Claude CLI(agy/gemini/codex)에 위임하고 Claude 자기 자신 호출을 금지할 것 [ADR-0029]
✓ 멀티 LLM 입력을 CLI 인자 직접 보간 없이 안전하게 전달할 것 [ADR-0029]
✓ CLI 부재·sentinel(NOT_FOUND/TIMEOUT/ERROR) 시 Claude self-generate로 fallback하고 리뷰 모델명을 provenance에 기록할 것 [ADR-0029]
✓ context:plan 검증 게이트는 spec 사람 리뷰(AskUserQuestion, Step 5)와 plan GAN cross-check(Step 6, 플랜모드 내) 2개만 사용할 것 (self-review 금지) [ADR-0030][ADR-0041]
✓ context:plan 디시플린 주입·검증 상세는 [ADR-0032] 본문 참조. GAN 프롬프트 본문은 verification.md 1곳만 정본으로 유지할 것.
✓ context:plan은 `docs/context/{TASK_NAME}/` 4파일만 산출하며 소스코드를 편집하지 않을 것. ExitPlanMode 승인 후 동작은 기계적 전사+종료뿐 [ADR-0041]
