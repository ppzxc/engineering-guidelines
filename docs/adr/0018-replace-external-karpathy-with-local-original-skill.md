# 외부 karpathy 의존 제거 및 로컬 workflow:karpathy-original 스킬 신설

* Status: accepted
* Date: 2026-05-18
* Decision Makers: ppzxc
* Consulted: -
* Informed: -

## Context and Problem Statement

feature-pipeline은 ADR-0013에서 외부 `andrej-karpathy-skills:karpathy-guidelines` 스킬(4원칙)을 S1.5에서 invoke하고, ADR-0017에서 §2/§3/§4를 S6 subagent 지시문에 인라인 paste했다. 그러나 원문이 11원칙으로 확장되었고, 4원칙 paraphrase 인라인은 원문 무결성을 훼손한다. 외부 의존은 미설치 환경 fallback 분기와 paraphrase 인라인 요약을 필요로 하며, paste-only 규약(ADR-0015) 하에서 S6 subagent까지 원문 11원칙이 도달하려면 로컬 단일 권위 출처가 필요하다.

## Decision Drivers

* 원문 11원칙을 1자도 변형 없이(verbatim) S6 subagent에 강제 전달
* 외부 의존 제거로 미설치 환경 fallback 분기 소멸 및 관리 단순화
* paste-only 규약(ADR-0015) 하에서 스킬 본문과 S6 paste 본문이 동일 텍스트여야 drift 없음

## Considered Options

* Option A. 로컬 스킬 `workflow:karpathy-original` 신설 + S1.5 invoke + S6에 원문 11원칙 verbatim paste
* Option B. 로컬 스킬 신설하되 S6에는 §2/§3/§4 요약만 paste (ADR-0017 연장)

## Decision Outcome

Chosen option: "Option A", because 원문 verbatim 요구사항을 충족하려면 S6 paste도 11원칙 전체여야 하고, 스킬 본문과 S6 paste 본문이 동일 텍스트일 때만 drift 없이 단일 출처 원칙이 유지된다.

Supersedes: [ADR-0013](0013-integrate-karpathy-guidelines-into-feature-pipeline.md), [ADR-0017](0017-concentrate-karpathy-guardrails-in-s6-subagent-prompt.md)

### Consequences

* Good, because 외부 의존·fallback 분기·4원칙 paraphrase 축약 테이블이 모두 소멸한다.
* Good, because §1/§5~§11이 S1.5(invoke) 및 S6(paste)를 통해 처음으로 강제 경로를 확보한다.
* Bad, because S6 subagent 프롬프트 본문이 약 30~40줄 증가한다 (plan 파일에는 적재되지 않으므로 ADR-0016/0020의 사이즈 가드와 충돌 없음).
* Bad, because 향후 11원칙 수정 시 스킬 본문과 S6 paste 본문을 동시에 갱신해야 한다 (workflow-rules.md drift 금지 규칙으로 명문화).

### Confirmation

```bash
# 새 스킬 11섹션 무결성
grep -cE '^## [0-9]+\. ' plugins/workflow/skills/karpathy-original/SKILL.md   # 기대: 11

# 외부 의존 잔존 0건
! grep -rn 'andrej-karpathy-skills\|karpathy-guidelines' plugins/ docs/ .claude/ README*.md

# feature-pipeline 갱신 확인
grep -n 'workflow:karpathy-original' plugins/workflow/skills/feature-pipeline/SKILL.md  # S1.5 + S6 최소 2건
grep -n 'Rule of 3' plugins/workflow/skills/feature-pipeline/SKILL.md                   # §11 S6 paste 도달 증거

# workflow-rules.md drift 금지 규칙 존재
grep 'drift 금지.*ADR-0018' .claude/rules/workflow-rules.md
```

## Pros and Cons of the Options

### Option A. 로컬 스킬 신설 + verbatim paste

* Good, because 원문 무결성 보장 — 스킬 본문이 곧 S6 paste 원본
* Good, because user-invocable 슬래시(`/workflow:karpathy-original`)도 제공
* Bad, because S6 paste 본문 크기 증가

### Option B. 로컬 스킬 신설 + §2/§3/§4 요약만 paste

* Good, because S6 paste 본문 크기 최소화
* Bad, because 원문 verbatim 요구사항 위배 — §1/§5~§11이 S6에 도달하지 않음

## More Information

* §5(한국어 콜론 금지)는 원문 자체에 "When the user writes in Korean" 조건이 명시되어 있어 영어 작업 subagent에서 자동으로 비활성화된다.
* §7(Plan + Checklist + Context Storage)의 "designated directories"는 본 프로젝트에서 `docs/plans/<slug>.md`(ADR-0011/0015), `.claude/rules/*.md`(rules-maintenance.md), `docs/adr/*.md`(rules-maintenance.md)로 매핑된다.
* 향후 개선 검토: 스킬 본문에서 자동 추출해 S6 prompt에 주입하는 빌드 스크립트 (현 PR 범위 밖).
* 관련 ADR: [ADR-0011](0011-add-feature-pipeline-orchestrator.md), [ADR-0014](0014-strengthen-feature-pipeline-evidence-based-gates.md), [ADR-0015](0015-remove-writing-plans-from-feature-pipeline.md), [ADR-0016](0016-avoid-plan-mode-in-feature-pipeline.md)
* 규칙 파일: [`.claude/rules/workflow-rules.md`](../../.claude/rules/workflow-rules.md)
