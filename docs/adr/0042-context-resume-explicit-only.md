# context:resume explicit-only invocation — disable model auto-invocation

* Status: accepted
* Date: 2026-06-01
* Decision Makers: ppzxc

## Context and Problem Statement

사용자가 Claude Code 내장 `/resume`(세션 재개)를 입력해도 `context:resume` 스킬이 발동하는 라우팅 충돌이 지속됐다. 커밋 3c8057f(v0.5.2)에서 SKILL.md 본문에 `<ACTIVATION>` 가드를 추가하고 CLAUDE.md에 프로즈 규칙을 삽입했으나 실패했다. 모델은 자동발동 결정 시 `name` + `description`만 읽으며, **본문은 Skill 도구 호출 후에야 로드된다** — 가드가 결정 시점 이전에 닿지 않는다. `description`에 `/context:resume` 리터럴과 broad 토큰 `"continue"`가 포함되어 `/resume` 입력과 fuzzy-match가 발생했다.

## Decision Outcome

Chosen option: "`disable-model-invocation: true` frontmatter 추가 + description 정제", because frontmatter 레벨 제어는 모델이 Skill 도구를 호출하기 전에 적용되어 결정적으로 자동발동을 차단하며, 본문 가드(3c8057f 방식)는 구조적으로 효과가 없다.

**변경 사항:**
- `disable-model-invocation: true` frontmatter 추가 → 모델 자동발동 전면 차단
- `description`에서 broad 토큰 `"continue"` 제거 → fuzzy-match 제거
- 본문 `<ACTIVATION>` 가드 블록 제거 → dead text 정리
- `/context:resume` 슬래시 호출만 허용; 자연어 자동발동("이어서" 등)은 의도적 포기

**결과:**
- Good: `/resume` → CC 내장 세션 picker만 발동, 100% 결정적 차단
- Good: `/context:resume` → 스킬 정상 발동
- Bad: "이어서", "어디까지 했지" 자연어 자동발동 불가 (사용자 동의 하에 포기)
- Note: CLAUDE.md / AGENTS.md의 `/resume` 프로즈 규칙은 이제 load-bearing이 아니며 의도 문서화 용도로만 유지

**supersedes:** 3c8057f의 본문 `<ACTIVATION>` 가드 접근 (무효 판정)
