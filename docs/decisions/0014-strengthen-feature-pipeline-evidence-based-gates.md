# feature-pipeline 오케스트레이션 강화: 외부 증거 기반 게이트 도입

* Status: accepted
* Date: 2026-05-14
* Decision Makers: ppzxc
* Consulted: Gemini Pro (cross-check)
* Informed: AI agents using workflow:feature-pipeline

## Context and Problem Statement

`/workflow:feature-pipeline`을 호출해도 7단계 전체 흐름이 실제로 수행되지 않는다. 실측 근거: 최근 plan 6개 모두 컨벤션 경로(`docs/plans/<slug>.md`) 대신 기본 경로(`/root/.claude/plans/`)에 적재되었고, 동일 6개 plan 모두 `## Cross-check Feedback` 섹션을 포함하지 않았다. SKILL.md v0.0.10은 선언적 정책 문서이며 실행 가능한 검증 hook이 0개였다 — 모든 강제가 "LLM이 지시를 읽고 따른다"는 가정에만 기댔다.

## Decision Drivers

* plan 경로 불일치로 S6 subagent가 plan을 찾지 못하는 사슬 실패 방지
* S4 Gemini cross-check 결과가 plan 파일에 기록되지 않아 피드백 반영 추적 불가
* S1.5 karpathy invoke가 TodoWrite 7단계 외 sub-step으로 처리되어 추적 불가능했음 (`TodoWrite`가 유효하지 않은 구식 도구 이름이어서 todo 등록 자체가 실패)
* Gate 1/2/3에 사용자 응답 대기 절차가 없어 LLM이 단독으로 gate를 통과

## Considered Options

* 옵션 1: 현상 유지 + 문서 보강만 (경고 문구 강화)
* 옵션 2: SKILL.md에 외부 증거 기반 검증 명령(grep, pwd, git rev-parse) 삽입
* 옵션 3: 별도 검증 스크립트/hook 파일로 위임

## Decision Outcome

Chosen option: "옵션 2: SKILL.md에 외부 증거 기반 검증 명령 삽입", because 스크립트/hook은 플랫폼 의존성을 만들고 SKILL.md 자체로 완결되지 않아 새 환경에서 사용하기 어렵다. 옵션 1은 선언적 텍스트가 이미 실패했음이 실측 증거로 확인되어 효과가 없다. 옵션 2는 기존 SKILL.md 구조를 유지하면서 외부 증거(파일 경로, grep 결과)로 단계 완료를 검증한다.

### Consequences

* Good, because plan 경로 불일치가 S3 시작 전에 즉시 감지된다
* Good, because S4 결과 누락이 Gate 2 전 grep 검증으로 발각된다
* Good, because S1.5가 독립 TaskCreate 항목으로 등재되어 추적 가능해진다
* Good, because `TodoWrite` → `TaskCreate` 명칭 정정으로 도구 호출 실패 근본 원인 제거
* Bad, because SKILL.md 행수가 약 200→230줄로 증가
* Bad, because LLM 자기보고 환각 회귀는 텍스트 강화만으로 근본 해결 불가능 (장기 완화: hook 기반 강제)

### Confirmation

* `grep -nE '(pwd|git rev-parse|grep -E)' plugins/workflow/skills/feature-pipeline/SKILL.md` → 최소 3건
* `grep -c '\[S1\.5\]' plugins/workflow/skills/feature-pipeline/SKILL.md` → ≥ 2건 (todo 블록 + 본문)
* `grep 'TaskCreate' plugins/workflow/skills/feature-pipeline/SKILL.md` → ≥ 1건
* `grep '## S7' plugins/workflow/skills/feature-pipeline/SKILL.md` → 1건
* `grep '\[ADR-0014\]' .claude/rules/workflow-rules.md` → 3건
* End-to-end: 신규 세션에서 `/workflow:feature-pipeline` 호출 후 plan이 `docs/plans/<slug>.md` 경로에 생성되고 `## Cross-check Feedback` 섹션을 포함하는지 확인

## Pros and Cons of the Options

### 옵션 1: 현상 유지 + 문서 보강

* Good, because SKILL.md 크기 유지
* Bad, because 실측 증거(6/6 실패)로 이미 효과 없음이 확인됨

### 옵션 2: SKILL.md에 외부 증거 기반 검증 명령 삽입

* Good, because SKILL.md 단일 파일로 완결
* Good, because 플랫폼 독립적 (grep, pwd, git rev-parse는 어디서나 동작)
* Neutral, because LLM이 grep 결과를 무시하고 진행하는 회귀 가능성 존재
* Bad, because SKILL.md 행수 증가

### 옵션 3: 별도 검증 스크립트/hook 위임

* Good, because 강제력이 가장 강함
* Bad, because 플랫폼/환경별 설정 필요로 이식성 저하
* Bad, because SKILL.md 자체로 완결되지 않아 새 설치 시 추가 작업 필요

## More Information

* 관련 ADR: [ADR-0011](0011-add-feature-pipeline-orchestrator.md) — feature-pipeline 최초 도입
* 관련 ADR: [ADR-0013](0013-integrate-karpathy-guidelines-into-feature-pipeline.md) — karpathy 통합
* 강제 규칙: `.claude/rules/workflow-rules.md` (`[ADR-0014]` 태그 항목)
