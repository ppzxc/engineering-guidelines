# llm 플러그인 4-way 폴백 체인 확장 및 context-map 폐기

* Status: accepted
* Supersedes (부분): ADR-0021 (context-map 생성·전달 영역), ADR-0022 (context-map 전달 영역), ADR-0023 (context-map 전달 영역)
* Date: 2026-05-28
* Decision Makers: ppzxc

## Context and Problem Statement

`llm` 플러그인은 ADR-0021로 Claude↔agy 2-way 구조를 채택했다. 그러나 두 가지 문제가 누적됐다.

1. **2-way 한계**: agy 단일 peer에 의존. agy 장애·인증 만료 시 즉시 self-only로 fallback되어 크로스체크 품질이 저하된다. gemini CLI / codex CLI 등 가용 LLM 풀을 활용하지 못했다.
2. **context-map 운영 부담**: `llm:agy`가 `collect-project-data.sh`로 프로젝트 스냅샷을 수집하고 `.context-map.md`를 생성·관리했다. 60분 TTL + git rev 매칭 로직이 복잡하고, git:clean / llm:claude에서 `.context-map.md`를 cross-check 인자로 전달하는 패턴이 여러 스킬에 분산되어 유지비용이 높다. agy MCP 자체는 plan만으로 충분히 동작하므로 context-map 부가가치 대비 비용이 크다.

## Decision Drivers

* 자기-호출 금지 원칙 (ADR-0022, ADR-0023): peer 풀에서 자기 호스트 제외
* 폴백 다양성: 단일 peer 실패 시 대체 경로 필요
* SRP: wrapper 스킬은 해당 CLI 위임만 담당, 라우팅은 `llm:auto` 단독 책임
* 운영 단순화: context-map 생성·관리 제거
* ADR-0033 패턴 차용: git:review SUBAGENT 병렬 dispatch 성공 사례

## Considered Options

* Option 1: 2-way 유지 (status quo) — agy sentinel 시 즉시 self-only
* Option 2: context-map 보존 + peer 풀 확장 — 기존 context-map 로직 유지하면서 gemini/codex 추가
* Option 3: context-map 폐기 + 4-way 확장 (채택) — context-map 전면 제거, {claude, agy, gemini, codex} 4-way 폴백 체인

## Decision Outcome

Chosen option: "Option 3 — context-map 폐기 + 4-way 확장", because 운영 단순화와 폴백 다양성을 동시에 달성하며, agy MCP는 context_map 없이도 plan 단독으로 동작이 검증됐다.

### Consequences

* Good, because 단일 peer 장애에도 2개 이상의 대체 peer가 보장된다.
* Good, because context-map 생성·관리 코드(collect-project-data.sh, TTL 체크, gitignore 동기화)가 제거되어 운영 복잡도가 낮아진다.
* Good, because wrapper 스킬 4종이 순수 위임 역할로 단일화되어 유지보수가 쉽다.
* Bad, because gemini / codex CLI가 미설치된 환경에서는 폴백 체인이 짧아진다.
* Bad, because context-map 기반의 풍부한 프로젝트 컨텍스트가 agy cross-check에 전달되지 않는다.

### Confirmation

1. `grep -r "context-map\|context_map" plugins/` — plugins 디렉토리 내 잔여 0건 (historical plans/ADR 제외)
2. `ls plugins/llm/skills/agy/references/` — `collect-project-data.sh` 부재 확인
3. `llm:agy` SKILL.md에 "Step 1" 또는 "Context Map" 섹션 부재 확인
4. `llm:claude` SKILL.md에 `.context-map.md` cat 로직 부재 확인
5. `git:clean` SKILL.md line 56 context-map 참조 제거 확인

## Pros and Cons of the Options

### Option 1: 2-way 유지

* Good, because 변경 없음, 리스크 없음
* Bad, because agy 단일 장애 시 self-only fallback — 크로스체크 품질 보장 불가
* Bad, because gemini/codex CLI 자원 미활용

### Option 2: context-map 보존 + peer 풀 확장

* Good, because 기존 context-map 기반 분석 품질 유지
* Bad, because context-map 운영 복잡도 그대로 + 신규 peer CLI에 context-map 전달 방식 불명확
* Bad, because `collect-project-data.sh`를 gemini/codex에도 적용해야 하므로 확장 비용 ↑

### Option 3: context-map 폐기 + 4-way 확장

* Good, because 운영 단순화 + 폴백 다양성
* Good, because ADR-0033 패턴(Self+Peer 병렬 SUBAGENT dispatch)과 설계 정합
* Neutral, because context-map 없이 plan 텍스트만으로 agy cross-check 품질이 실용적으로 충분함이 검증됨
* Bad, because CLI 미설치 환경에서 폴백 체인 단축

## More Information

### Host Fallback Matrix

| Self host | Peer 우선순위 |
|-----------|---------------|
| Claude Code | agy → gemini → codex |
| Antigravity (agy) | claude → gemini → codex |

Self-host = {Claude Code, agy} 2종 (Gemini CLI / Codex는 SKILL 실행 환경 미검증).

### Wrapper 우선순위 체인

| Wrapper | 1순위 | 2순위 (Fallback) |
|---------|-------|------------------|
| `llm:claude` | Claude Code 자체 추론 (self-host 시) | `claude -p` stdin CLI |
| `llm:agy` | `mcp__agy__agy_cross_check` MCP | `agy -p` stdin CLI |
| `llm:gemini` | Agent(subagent_type=`gemini:gemini-rescue`) | `gemini -p` stdin CLI |
| `llm:codex` | Agent(subagent_type=`codex:codex-rescue`) | `codex exec -` stdin |

### 입력 분류

`llm:auto`는 입력을 plan / spec / idea / diff 4종으로 분류. diff는 `git:review`로 redirect.

### 관련 문서

- [ADR-0021](0021-migrate-llm-backend-from-gemini-cli-to-agy.md) — agy 백엔드 채택 (context-map 도입)
- [ADR-0022](0022-bidirectional-peer-cross-review.md) — git:review 양방향 peer cross-review
- [ADR-0023](0023-git-clean-bidirectional-peer-cross-check.md) — git:clean 양방향 peer cross-check
- [ADR-0033](0033-git-review-parallel-subagent-cross-review.md) — git:review 병렬 SUBAGENT 패턴 (차용)
- `.claude/rules/llm-rules.md` — 강제 규칙
