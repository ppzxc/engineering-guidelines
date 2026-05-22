# `git:review` 양방향 peer cross-review 도입 (호스트별 라우팅)

* Status: accepted
* Date: 2026-05-22
* Decision Makers: ppzxc

## Context and Problem Statement

ADR-0021로 `git:review` Step 5a는 `mcp__agy__agy_cross_check`를 단방향(Claude → agy)으로 호출한다. 그러나 동일 플러그인을 Claude Code 외 호스트(Gemini CLI, Antigravity/agy)에서 실행하면 (1) agy MCP 도구가 노출되지 않거나 (2) 자기 자신에게 cross-check를 보내는 무의미한 호출이 된다. 멀티 호스트 호환성을 위해 호스트 자기 인지 기반 양방향 라우팅이 필요하다.

## Decision Drivers

* `using-superpowers` Platform Adaptation 패턴과 일관성
* 자기 자신에게 cross-check를 보내는 호출 금지 (메아리 방지)
* 신규 추상화 최소화 (YAGNI — 별도 reverse wrapper 스킬 생성 X)
* shell 접근은 모든 호스트가 보장한다는 가정

## Considered Options

* Host-aware single SKILL.md (자연어 분기 + `claude -p` 비대화형 CLI)
* Host-specific 진입점 (호스트별 별도 SKILL.md 변형)
* 환경변수 기반 결정적 분기 (bash로 `CLAUDE_CODE`/`GEMINI`/`AGY` 변수 감지)

## Decision Outcome

Chosen option: "Host-aware single SKILL.md", because superpowers의 Platform Adaptation 패턴과 일치하고 `claude` CLI는 모든 shell 환경에서 보편이며 호스트별 별도 파일 관리 부담이 없다.

매트릭스:

| 실행 호스트 | 1차 peer reviewer | 호출 방식 |
|------------|------------------|----------|
| Claude Code | agy | `mcp__agy__agy_cross_check(plan, context_map)` |
| Gemini CLI | Claude | Bash: `claude -p "<리뷰 지시 + PR diff>"` (300s timeout) |
| Antigravity (agy host) | Claude | Bash: `claude -p "<리뷰 지시 + PR diff>"` (300s timeout) |

Sentinel: 기존 `AGY_TIMEOUT:` / `AGY_ERROR(exit=...)` / `AGY_NOT_FOUND:` 외에 `CLAUDE_CLI_NOT_FOUND:` / `CLAUDE_CLI_TIMEOUT:` / `CLAUDE_CLI_ERROR(exit=N):` 추가. sentinel 응답 시 동일 인자 재호출 금지, self-generate fallback.

### Consequences

* Good, because 동일 플러그인이 Claude Code/Gemini CLI/Antigravity에서 모두 작동한다.
* Good, because 자기 자신에게 cross-check를 보내는 무의미한 호출이 차단된다.
* Bad, because `claude` CLI 비대화형 모드 가용성에 의존한다 — 2026-05-22 spike에서 `claude -p` 가용성을 확인했다 (claude v2.1.148, exit 0).
* Bad, because 호스트가 자기 ID를 잘못 인지하면 분기 오류가 난다 — `mcp__agy__` 도구 노출 여부를 보조 시그널로 사용해 완화한다.

### Confirmation

* Claude Code에서 `/git:review <PR#>` 실행 시 기존과 동일하게 `mcp__agy__agy_cross_check`가 호출되는지 (회귀)
* Gemini CLI / Antigravity 환경에서 동일 명령 실행 시 `claude -p` Bash 분기로 진입하는지 (spike)
* sentinel 응답을 강제 주입했을 때 self-generate fallback이 발동되는지

## Pros and Cons of the Options

### Host-aware single SKILL.md

* Good, because 단일 파일로 유지보수 단순
* Good, because superpowers 패턴과 일관
* Neutral, because LLM이 자기 호스트를 인지한다는 가정에 의존
* Bad, because 호스트 ID 오인지 시 분기 오류

### Host-specific 진입점

* Good, because 호스트별 동작이 명확히 분리
* Bad, because 동일 로직이 3중 복제되어 유지보수 부담 3배
* Bad, because 사용자가 호스트마다 다른 슬래시 명령을 외워야 함

### 환경변수 기반 결정적 분기

* Good, because 결정적이고 LLM 자기 인지에 의존하지 않음
* Bad, because 각 호스트가 신뢰할 만한 표준 환경변수를 노출하는지 불확실
* Bad, because shell 컨텍스트 변경(서브셸/CI) 시 환경변수 누락 가능

## More Information

* Supersedes 없음 (ADR-0021은 그대로 유지: agy를 단일 LLM 백엔드로 본 결정은 Claude→agy 방향에 한해 그대로 유효, 본 ADR은 그 매트릭스를 확장)
* Related rules: `.claude/rules/git-rules.md`
* Related skill: `plugins/git/skills/review/SKILL.md` Step 5a
