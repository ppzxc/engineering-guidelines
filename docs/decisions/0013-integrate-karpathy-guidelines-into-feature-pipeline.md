# feature-pipeline에 karpathy-guidelines 정신 통합

* Status: superseded by ADR-0018
* Date: 2026-05-13
* Decision Makers: ppzxc
* Consulted: -
* Informed: -

## Context and Problem Statement

`/workflow:feature-pipeline` 7단계 파이프라인은 형식(worktree, TDD 태그, Gemini 검증)은 갖췄지만, 각 단계에서 "단순함, 외과적 변경, 가정 표면화, 검증 가능한 성공 기준"이 명시적으로 강제되지 않는다. LLM 코딩의 흔한 실수(과도한 추상화, 요청 외 인접 코드 수정, 막연한 성공 기준)를 줄이기 위해 `andrej-karpathy-skills:karpathy-guidelines` 스킬의 4원칙을 파이프라인에 통합할 필요가 있다.

## Decision Drivers

* LLM 코딩에서 "단순함 우선"과 "외과적 변경"이 지켜지지 않으면 불필요한 코드가 늘어난다
* TDD 게이트가 형식 체크만 하고 "검증 가능한 성공 기준"은 확인하지 않는다
* karpathy-guidelines는 이미 글로벌 마켓플레이스에 설치되어 있어 invoke 비용이 낮다

## Considered Options

* Option A: S1 grill-me 직후 1회 invoke + 각 단계 인라인 가드레일 (본 결정)
* Option B: 각 단계마다 invoke (S3, S5, S6에서 별도 호출)
* Option C: SKILL.md 본문에 4원칙 인라인 요약만 넣고 invoke 없음

## Decision Outcome

Chosen option: "Option A — S1 직후 1회 invoke + 인라인 가드레일", because invoke는 컨텍스트 로드 1회로 충족되고, 각 단계별 원칙 매핑은 인라인 체크리스트로 강제하는 것이 중복 호출 없이 효율적이다.

### Consequences

* Good, because S1 종료 시점에 karpathy 원칙이 컨텍스트에 로드되어 후속 단계 전체에 영향을 미친다
* Good, because 미설치 환경에서도 인라인 요약으로 정신은 동작한다
* Bad, because invoke가 실패하면(미설치) 명시적 경고 로직이 필요하다

### Confirmation

`plugins/workflow/skills/feature-pipeline/SKILL.md`에서 다음을 확인:
- S1 완료 직후 `andrej-karpathy-skills:karpathy-guidelines` invoke 지시가 있는가
- S3 plan 작성 체크리스트에 Simplicity First 항목이 있는가
- S5 TDD 게이트에 Goal-Driven Execution 검증 가능한 성공 기준 체크가 있는가
- S6 subagent 지시문에 Surgical Changes 가드레일이 있는가
- 본문 끝에 4원칙 인라인 요약이 있는가

## Pros and Cons of the Options

### Option A: S1 직후 1회 invoke + 인라인 가드레일

* Good, because invoke 횟수 최소화 (1회)
* Good, because 미설치 fallback이 자연스럽게 인라인 요약으로 동작
* Neutral, because invoke 실패 시 사용자 경고 필요

### Option B: 각 단계마다 invoke

* Good, because 각 단계에서 원칙이 명시적으로 상기됨
* Bad, because 중복 invoke로 노이즈 증가
* Bad, because 미설치 환경에서 3단계 모두 실패

### Option C: 인라인 요약만

* Good, because 외부 의존성 없음
* Bad, because karpathy-guidelines 스킬 업데이트가 SKILL.md에 자동 반영되지 않음
* Bad, because invoke라는 명시적 신호 없이 가이드라인이 묻힘

## More Information

- karpathy-guidelines 원본: `andrej-karpathy-skills:karpathy-guidelines` (글로벌 마켓플레이스)
- 관련 rules: `.claude/rules/workflow-rules.md` `[ADR-0013]` 항목
- 참고 ADR: [ADR-0011](0011-add-feature-pipeline-orchestrator.md) — feature-pipeline 오케스트레이터 도입 배경
- Refined by: [ADR-0017](0017-concentrate-karpathy-guardrails-in-s6-subagent-prompt.md) — paste-only 규약 하에서 §2/§4를 S6 인라인으로 집중 매핑
