# `git:clean` 양방향 peer cross-check 도입 (호스트별 라우팅)

* Status: accepted
* Date: 2026-05-22
* Decision Makers: ppzxc

## Context and Problem Statement

`git:clean`은 전체 PR 수명주기(commit → PR → review → merge → cleanup)를 순차적으로 처리하는 핵심 오케스트레이션 스킬이다. 이 과정에서 브랜치 생성/삭제, 코드 커밋, PR 생성 및 머지 등 파괴적이거나 복잡한 Git 상태 변경이 발생한다.
그러나 시작 전 단계에서 현재 Git 상태와 실행 계획의 정합성을 검증하는 외부 peer cross-check 단계가 없었다. 이에 따라 호스트 환경(Claude Code, Gemini CLI, Antigravity)별로 상호 크로스체크를 진행할 수 있는 안전장치가 필요하다.

## Decision Drivers

* `using-superpowers` 및 `git:review` (ADR-0022)의 양방향 peer cross-review 모델과의 일관성 유지.
* 자기 자신에게 cross-check를 요청하는 무한 루프(메아리) 방지.
* `git:clean` 실행 전 오동작 가능성(커밋 유실, 잘못된 브랜치 정리 등) 최소화.
* 쉘 인젝션 차단 및 안정적 타임아웃(300s) 제어.

## Considered Options

* Host-aware single SKILL.md (자연어 분기 + `claude -p` 비대화형 CLI)
* Host-specific 진입점 (호스트별 별도 SKILL.md 변형)

## Decision Outcome

Chosen option: "Host-aware single SKILL.md", because 기존 `git:review`에서 검증된 양방향 라우팅 메커니즘을 동일하게 재사용하여 코드 및 문서 관리 일관성을 유지하고, 추가적인 파일 복제 부담을 없앨 수 있다.

매트릭스:

| 실행 호스트 | 1차 peer reviewer | 호출 방식 |
|------------|------------------|----------|
| Claude Code | agy | `mcp__agy__agy_cross_check(plan, context_map)` |
| Gemini CLI | Claude | Bash: `claude -p "<크로스체크 지시 + clean 계획>"` (300s timeout) |
| Antigravity (agy host) | Claude | Bash: `claude -p "<크로스체크 지시 + clean 계획>"` (300s timeout) |

Sentinel: `AGY_TIMEOUT:` / `AGY_ERROR(exit=...)` / `AGY_NOT_FOUND:` 및 `CLAUDE_CLI_NOT_FOUND:` / `CLAUDE_CLI_TIMEOUT:` / `CLAUDE_CLI_ERROR(exit=N):` 추가. sentinel 응답 시 self-only check로 fallback 진행.

### Consequences

* Good, because `git:clean` 시작 전에 변경 이력 파괴 위험성을 peer reviewer가 상호 검토하여 안전성을 대폭 보강한다.
* Good, because 자기 자신에 대한 호출을 방지한다.
* Bad, because `claude` CLI 또는 agy MCP 가용성에 의존한다 (Pre-flight 검증 및 Sentinel 처리로 보완).
* Bad, because CLI 인자로 계획 정보를 직접 주입 시 shell injection 우려 (stdin pipe 형태로만 정보 전달을 강제하여 방지).

### Confirmation

* Claude Code에서 `/git:clean` 실행 시 `mcp__agy__agy_cross_check`가 정상적으로 진행되는지 확인.
* Gemini CLI / Antigravity 환경에서 `claude -p` 분기로 진입하여 stdin을 통한 cross-check가 수행되는지 확인.
* Sentinel 발생 시 정상적으로 self-only check로 복귀(fallback)하는지 검증.

## Pros and Cons of the Options

### Host-aware single SKILL.md

* Good, because 단일 파일에서 통일된 라이프사이클 관리 가능.
* Good, because 기존 규칙과 일관성 유지.
* Bad, because 호스트 ID 오인지 리스크 존재 (도구 및 CLI 감지 시그널 조합으로 완화).

### Host-specific 진입점

* Good, because 호스트 환경별 분기가 완벽히 분리됨.
* Bad, because 유사한 Git clean 절차가 호스트별 파일로 쪼개져 유지보수 부담 가중.

## More Information

* Amends ADR-0006 (`git-clean` 스킬 통합)
* Amends ADR-0022 (`git:review` 양방향 peer cross-review 도입)
* Related rules: `.claude/rules/git-rules.md`
* Related skill: `plugins/git/skills/clean/SKILL.md`
