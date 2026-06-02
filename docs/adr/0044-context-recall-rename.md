# context:resume → context:recall 리네임으로 /resume 라우팅 충돌 근본 제거

* Status: accepted
* Date: 2026-06-02
* Decision Makers: ppzxc

## Context and Problem Statement

ADR-0042(v0.5.3)에서 `disable-model-invocation: true` frontmatter로 `context:resume`를 available-skills 목록에서 제거했으나 라우팅 충돌이 지속됐다. 근본 원인: `disable-model-invocation: true`는 자동발견(목록 노출)만 차단하고, 모델이 CLAUDE.md/context-rules.md 본문 텍스트에서 스킬명 `context:resume`을 읽어 **명시 호출**(`Skill({skill:"context:resume"})`)을 시도하는 경로는 열려 있다. 또한 `using-superpowers` 지침("slash command = skill, YOU HAVE NO CHOICE")이 CLAUDE.md 프로즈 금지 규칙을 이기는 구조적 우선순위 문제가 있다.

## Decision Outcome

Chosen option: "스킬명 리네임 (`context:resume` → `context:recall`)", because 토큰 레벨에서 `/resume`과의 suffix-match를 제거하는 것이 프로즈 규칙이나 frontmatter 플래그보다 결정적이다. 스킬명이 바뀌면 모델이 CLAUDE.md 텍스트를 읽어도 `/resume`과 매칭할 수 있는 `context:resume`이라는 이름 자체가 없어진다.

**변경 사항:**
- `plugins/context/skills/resume/` → `plugins/context/skills/recall/` 디렉토리 리네임
- SKILL.md frontmatter: `name: resume` → `name: recall`, description 트리거 갱신
- `disable-model-invocation: true` 제거 (이제 불필요)
- `context:resume` 모든 참조를 `context:recall`로 교체 (plan/SKILL.md, README.md, README.ko.md, context-rules.md, CLAUDE.md)
- CLAUDE.md `/resume` 금지 프로즈 규칙 제거 (스킬명 충돌 자체가 없어지므로 불필요)

**결과:**
- Good: `/resume` → CC 내장 세션 picker만 발동 (토큰 레벨 격리)
- Good: `/context:recall` → 스킬 정상 발동
- Good: `using-superpowers` 지침과 충돌 없음 (매칭 자체 없음)
- Neutral: 사용자 인터페이스 명칭 변경 (`/context:resume` → `/context:recall`)

**supersedes:** ADR-0042 (`disable-model-invocation` 접근 — 명시 호출 경로 미차단으로 불충분 판정)
