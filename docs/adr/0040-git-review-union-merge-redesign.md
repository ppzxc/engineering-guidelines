# git:review 5c 머지 재설계 — union+agreement 태그+fix-gate

* Status: accepted
* Date: 2026-06-01
* Decision Makers: ppzxc
* Consulted: —
* Informed: —

## Context and Problem Statement

`git:review` Step 5c는 ADR-0033에서 severity-gated hybrid 머지(critical/high=union, medium/low=intersection)를 채택했다. 그러나 이 설계는 세 가지 구조적 문제를 가진다: (1) exact `file:line` intersection 매칭이 너무 엄격해 medium/low가 거의 탈락함, (2) ADR-0039의 tier 비대칭(fast+deep 조합)이 "두 리뷰어 능력 대등" 전제를 파괴함, (3) 단일 리뷰어 상황에서 medium/low 처리가 미정의. 업계 실무(Mozilla Star Chamber, arxiv 앙상블 연구)는 intersection으로 버리지 않고 union+agreement 태그로 모으고, precision은 fix-gate 단계에서 확보한다.

## Decision Drivers

* tier 비대칭(ADR-0039) 허용 시에도 머지 정확도 유지
* exact intersection의 dead-code 문제 해소 (medium/low 거의 탈락)
* 업계 표준(Star Chamber union+tier 분류, arxiv F1 +43% union 기반) 정렬
* 단일 리뷰어 degenerate 케이스 명확화
* precision은 fix-gate로 확보 (머지에서 버리지 않음, 정보손실 없음)

## Considered Options

* (i) 현행 유지 (severity-gated intersection) — tier 비대칭 문제 미해결
* **(ii) union + agreement 태그 + fix-gate** ← 선택
* (iii) 항상 union, 태그 없이 PR 코멘트 전체 보고만 — precision 0

## Decision Outcome

Chosen option: "(ii) union + agreement 태그 + fix-gate", because findings를 버리지 않고(union) agreement 태그(`both`/`single`)로 신뢰도를 표시한 뒤, precision은 Step 6 fix-gate에서 `severity × agreement` 기준으로 확보한다. tier 비대칭, dead-code, 단일 리뷰어 세 문제를 동시에 해소하며 Mozilla Star Chamber 실무 패턴과 정렬된다.

### 5c 새 머지 규칙

1. **Union 수집**: Self와 Peer 양쪽 findings 모두 포함.
2. **퍼지 dedup**: `(file:line ±2줄, category)` 기준 중복 제거. 양쪽 발견 시 통합.
3. **Agreement 태그 부여** (main thread):
   - `both`: 양쪽 발견
   - `single`: 한쪽만 발견

단일 리뷰어 상황: 전 항목 `single` 태그.

### Step 6 fix-gate 규칙

| severity | agreement | 처리 |
|----------|-----------|------|
| critical, high | both 또는 single | **자동수정** (union/minority-veto) |
| medium, low | both | **자동수정** |
| medium, low | single | **코멘트 보고만** (수정 안 함) |

### Consequences

* Good, because tier 비대칭(ADR-0039) 허용 — union은 능력대등 가정 없음, 강한 쪽 finding 생존
* Good, because medium/low single finding이 PR 코멘트에 보존 (정보손실 없음)
* Good, because exact intersection dead-code 제거 — 구멍 1/2/3 동시 해소
* Good, because Mozilla Star Chamber 실무 패턴 및 arxiv 앙상블 연구 정렬
* Bad, because PR 코멘트에 single finding이 추가로 보고되어 코멘트 길이 증가 가능
* Bad, because main thread가 agreement 태그 계산을 직접 수행 (추가 로직)

### Confirmation

- `plugins/git/skills/review/SKILL.md` Step 5c가 union+퍼지dedup+agreement 태그 규칙으로 대체됨
- `plugins/git/skills/review/SKILL.md` Step 6에 severity×agreement fix-gate 표 존재
- `plugins/git/skills/review/SKILL.md` Step 7 comment body에 `both:<b> single:<s>` 분포 기록
- `.claude/rules/git-rules.md`에 [ADR-0040] 태그 규칙 존재 (intersection 규칙 삭제)

## Pros and Cons of the Options

### (i) 현행 유지 (severity-gated intersection)

* Good, because 변경 없음
* Bad, because exact `file:line` intersection → medium/low 거의 탈락 (dead-code)
* Bad, because tier 비대칭 시 능력대등 전제 파괴 (구멍 2)
* Bad, because 단일 리뷰어 시 medium/low 처리 미정의 (구멍 3)

### (ii) union + agreement 태그 + fix-gate (선택)

* Good, because 구멍 1/2/3 모두 해소
* Good, because 업계 표준 정렬
* Good, because 정보 보존 + precision은 fix-gate에서 확보
* Bad, because PR 코멘트 길이 증가 가능

### (iii) 항상 union, 코멘트 전체 보고만

* Good, because 구현 단순
* Bad, because auto-fix precision 0 — 노이즈 전부 수정됨
* Bad, because 실용성 없음

## More Information

- ADR-0033: `0033-git-review-parallel-subagent-cross-review.md` (머지 규칙 부분 superseded)
- ADR-0039: `0039-git-review-tier-selectable-models.md` (tier 비대칭 도입 → 이 ADR의 직접 동기)
- Mozilla.ai Star Chamber: union 기반 tier 분류 실무 사례 (consensus/majority/individual)
- arxiv 2511.15714: majority-vote ensemble F1 0.55→0.73, union+agreement 기반
- arxiv 2509.01494: ACR multi-review 전략 F1 +43.67%
- `plugins/git/skills/review/SKILL.md` — 강제 구현
- `.claude/rules/git-rules.md` — 강제 규칙
