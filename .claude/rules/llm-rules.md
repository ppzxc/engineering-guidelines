# LLM 플러그인 규칙

✓ 자기 호스트 LLM에 cross-check 위임 금지 (자기-호출 금지) [ADR-0022][ADR-0023][ADR-0034]
✓ peer 폴백 체인은 자기 호스트 제외 풀에서 우선순위대로 시도, 모든 sentinel(NOT_FOUND/TIMEOUT/ERROR)에서 다음 peer로 이동 [ADR-0034]
✓ CLI 인자 직접 보간 금지, stdin pipe 또는 tmpfile 사용 [ADR-0034]
✓ Pre-flight `timeout 3 <cli> --version` 강제, 미충족 시 sentinel 발동 [ADR-0034]
✓ `.context-map.md` 생성·전달·참조 금지 (ADR-0021/0022/0023 부분 supersede) [ADR-0034]
✓ wrapper 우선순위는 MCP/스킬/SubAgent 1순위 → stdin CLI fallback 2순위 [ADR-0034]
✓ self+peer 병렬 SUBAGENT dispatch 수행 (ADR-0033 패턴 차용) [ADR-0034]
✓ 입력 분류 4종(plan/spec/idea/diff). diff 입력은 git:review로 redirect [ADR-0034]
