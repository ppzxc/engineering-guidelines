# feature-pipeline plan 파일 사이즈 캡 16KB 상향 및 플랜 생략 방어 강화

* Status: accepted
* Date: 2026-05-19
* Decision Makers: ppzxc
* Consulted: -
* Informed: AI agents using workflow:feature-pipeline

## Context and Problem Statement

ADR-0016이 도입한 "plan 파일 8KB 이하" 규칙은 측정된 임계치가 아닌 희망 목표였다. 채택 이후 실측 결과: 저장소 내 `docs/superpowers/plans/` 9건 중 89%, `/root/.claude/plans/` 66건 중 64%가 이미 8KB를 초과하며(중앙값 ~11–14KB) 규칙이 *조용히 위반* 중이다. 같은 감사에서 feature-pipeline 파이프라인에 plan 파일 없이 S6 subagent가 실행될 수 있는 HIGH 위험 경로 3건도 발견되었다: (1) S6의 `$PLAN_FILE` 존재 검증 부재, (2) S5 실패 시 Gate 3 우회 승인 허용, (3) STOP 표 "S1 다음은 S2" 잔재(ADR-0019 시퀀스와 모순).

## Decision Drivers

* 실측 중앙값(~11–14KB)에 정합하는 현실적 캡으로 교체하여 "모두가 지키지 않는 규칙" 해소
* 병리 범위(30–98KB, ADR-0016 측정)와의 안전 마진 유지
* plan 파일 없이 S6 실행 경로 차단 (플랜 생략 가능성 차단)
* ADR-0016 본문 immutable 원칙 유지

## Considered Options

* 옵션 1: 16KB 상향 + plan-skip HIGH 위험 3건 차단 (채택)
* 옵션 2: 8KB 유지 + 강제 검증(wc -c) 추가
* 옵션 3: 캡 폐지 + 컨텐츠 제약(헤더+태스크+요약만)만 유지

## Decision Outcome

Chosen option: "옵션 1: 16KB 상향 + plan-skip HIGH 위험 3건 차단", because 30KB 병리 범위 대비 2× 안전 마진을 유지하면서 실측 중앙값과 정합하고, plan-skip 위험을 동시에 차단하는 최소 범위 변경이다.

**3개 병행 결정:**

1. **사이즈 캡**: ADR-0016의 "8KB 이하" → "16KB 이하"로 갱신. 슬림화 원칙(헤더+태스크+cross-check 요약만)은 그대로 유지.
2. **S6 pre-flight 검증**: S6 subagent 디스패치 직전 `test -f "$PLAN_FILE" && [ -s "$PLAN_FILE" ]` 검증 추가. 실패 시 STOP.
3. **S5 실패 처리 명확화**: S5 TDD 게이트 실패 시 "Gate 3를 통해 에스컬레이션" → "즉시 STOP + 사용자 수정 요청 (Gate 3 진입 금지)"으로 강화.

### Consequences

* Good, because 실측 중앙값(~11–14KB)과 정합 — 위반률 해소
* Good, because 병리 범위(30KB) 대비 여전히 2× 안전 마진 확보
* Good, because S6 pre-flight로 plan 파일 부재 시 subagent 무한 오류 사이클 차단
* Good, because S5 실패 Gate 3 우회 경로 소멸 — 깨진 plan으로 S6 진입 불가
* Bad, because S4 Gemini cross-check 입력 S/N 비율이 8KB 캡 대비 소폭 저하 — 슬림화 원칙으로 보완
* Neutral, because 병리 범위(30KB)는 여전히 산문적 가드(빨간 신호 표)로만 차단됨

### Confirmation

```bash
# 1. 사이즈 캡 일관성 (8KB 잔존 0건)
grep -rn '8KB' .claude/rules/workflow-rules.md plugins/workflow/skills/feature-pipeline/SKILL.md
# expect: empty

# 2. 16KB 표현 ≥2건
grep -c '16KB' plugins/workflow/skills/feature-pipeline/SKILL.md
# expect: ≥ 2

# 3. S6 pre-flight 검증 존재
grep -nE 'test -f.*PLAN_FILE' plugins/workflow/skills/feature-pipeline/SKILL.md
# expect: ≥ 1

# 4. S5 STOP 명시
grep -nE 'STOP|Gate 3 진입 금지' plugins/workflow/skills/feature-pipeline/SKILL.md
# expect: S5 섹션 내 ≥1

# 5. ADR-0020 태그 ≥2건
grep -c 'ADR-0020' .claude/rules/workflow-rules.md
# expect: ≥ 2
```

## Pros and Cons of the Options

### 옵션 1: 16KB 상향 + plan-skip HIGH 위험 3건 차단 (채택)

* Good, because 실측 중앙값과 정합, 병리 범위 안전 마진 유지
* Good, because 최소 범위 변경으로 두 문제 동시 해소
* Neutral, because S4 S/N 비율 소폭 저하 (슬림화 원칙으로 완화)
* Bad, because 30KB 병리 범위는 여전히 소프트 가드만

### 옵션 2: 8KB 유지 + 강제 검증(wc -c) 추가

* Good, because 원래 의도(plan 파일 경량 유지) 완전 보존
* Bad, because 실측 중앙값(~11–14KB) 초과 plan이 모두 경고 대상 — 매 실행마다 노이즈
* Bad, because 8KB가 실질적으로 달성 불가능한 목표임이 반복 확인됨

### 옵션 3: 캡 폐지 + 컨텐츠 제약만 유지

* Good, because 수치 가드 불필요 — 슬림화 원칙만으로 충분
* Bad, because 명시적 상한 없이 30KB 병리 범위로 재유입될 수 있음
* Bad, because ADR-0016의 정신(reattach 페이로드 최소화)을 약화

## More Information

* Supersedes (부분): ADR-0016의 "8KB 이하" 수치만. ADR-0016 본문은 immutable 유지. 슬림화 원칙·ExitPlanMode 회피 결정은 그대로 승계.
* 관련 ADR: ADR-0011, ADR-0014, ADR-0016, ADR-0018, ADR-0019
* 적용 규칙: `.claude/rules/workflow-rules.md` `[ADR-0020]` 항목
* 발단: 실측 감사 (2026-05-19) — plan 파일 8KB 위반률 64–89%, plan-skip HIGH 위험 3건 발견
* 후속 후보 (MEDIUM/LOW, 본 ADR 범위 밖):
  - Gate 1 문구 "S3 진행 여부 확인"이 skip 응답 유도 가능 (LOW)
  - TaskCreate `completed` 전 산출물 존재 검증 규칙 부재 (MEDIUM)
  - S5 grep이 `$PLAN_FILE` 비존재를 "no behavioral tasks"로 오인 가능 (MEDIUM — S6 pre-flight가 부분 보완)
  - `## Skip 조건 — 없다` 목록에 "S3 plan 생략" 미열거 (LOW)
