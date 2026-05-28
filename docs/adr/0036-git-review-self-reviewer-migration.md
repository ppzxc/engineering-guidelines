# git:review Self-Review agent를 pr-review-toolkit:code-reviewer로 교체

* Status: accepted
* Date: 2026-05-28
* Decision Makers: ppzxc
* Consulted: —
* Informed: —

## Context and Problem Statement

`git:review` Self-Review SUBAGENT(ADR-0033)는 언어별 스킬(java:reviewer/golang:reviewer/java:spring)을 Skill 툴로 호출하여 리뷰를 수행했다. 이 구조는 언어 매핑 유지 비용이 높고, 미매핑 언어는 general criteria로 silently 강등된다. 또한 Step 4a의 동적 agent 선택(AskUserQuestion)이 UX 단계를 추가했다. `pr-review-toolkit:code-reviewer`(opus)는 CLAUDE.md 컴플라이언스 + 버그 감지를 단일 agent로 처리하며, confidence 스코어링(≥80만 리포트)으로 노이즈를 자체 필터링한다.

## Decision Drivers

* 언어별 스킬 유지 비용 제거
* Step 4a 동적 선택 제거 → UX 단순화
* opus model 고정으로 Self-Review 품질 유지
* CLAUDE.md 컴플라이언스 자동 포함
* git:clean / git:review standalone 두 컨텍스트 모두 동작

## Considered Options

* (i) 언어별 스킬 유지 + 추가 언어 매핑 확장
* **(ii) pr-review-toolkit:code-reviewer 단독 사용** ← 선택

## Decision Outcome

Chosen option: "(ii) pr-review-toolkit:code-reviewer 단독 사용", because 언어별 스킬 유지 비용을 제거하고, opus model + confidence 필터(≥80)로 Self-Review 품질을 유지할 수 있으며, SUBAGENT prompt에 `gh pr diff <PR_NUMBER>` 결과를 직접 주입하여 diff 소스 문제를 해결한다.

### Consequences

* Good, because 언어별 스킬(java:reviewer/golang:reviewer/java:spring) 제거 → maintenance 포인트 감소
* Good, because Step 4a(동적 agent 선택 AskUserQuestion) 제거 → UX 단순화
* Good, because code-reviewer가 CLAUDE.md 컴플라이언스를 자동 포함
* Good, because confidence ≥80 자체 필터로 노이즈 감소
* Good, because `gh pr diff <PR_NUMBER>` 주입으로 git:clean / standalone 모두 동작
* Bad, because 언어별 specialized ruleset(Java/Go peer ruleset) 수준의 도메인 특화 리뷰는 Self에서 불가 (Peer에서 계속 적용)

### Confirmation

- `plugins/git/skills/review/SKILL.md` Step 4a 제거, Step 5a에 code-reviewer dispatch 포함
- `.claude/rules/git-rules.md`에 [ADR-0036] 태그 규칙 2개 추가
- 버전 v0.1.0 → v0.2.0 범프 3곳 동기화

## Pros and Cons of the Options

### (i) 언어별 스킬 유지 + 언어 매핑 확장

* Good, because 언어별 specialized 리뷰 유지
* Bad, because 언어 매핑 테이블 지속 관리 필요
* Bad, because 미매핑 언어 silently 강등
* Bad, because Step 4a UX 단계 유지

### (ii) pr-review-toolkit:code-reviewer 단독 사용 (선택)

* Good, because 단일 agent로 언어 무관 리뷰
* Good, because opus model + confidence 필터
* Good, because 유지 비용 없음
* Bad, because Java/Go 언어별 critical 룰셋은 Peer에서만 적용

## More Information

- ADR-0033: `0033-git-review-parallel-subagent-cross-review.md` (보강, supersede 아님)
- `pr-review-toolkit:code-reviewer` agent: `model: opus`, confidence 0-100 스코어링, ≥80만 리포트
- confidence → severity 매핑: 90-100 → critical, 80-89 → high (모두 union merge)
- diff 소스: `gh pr diff <PR_NUMBER>` → SUBAGENT prompt 직접 주입
- `plugins/git/skills/review/SKILL.md` — 강제 구현
- `.claude/rules/git-rules.md` — 강제 규칙
