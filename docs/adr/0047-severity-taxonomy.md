# Severity Taxonomy 통합 — _shared/references/severity-taxonomy.md

* Status: accepted
* Date: 2026-06-03
* Decision Makers: ppzxc

## Context and Problem Statement

`git:review`(4-level: critical/high/medium/low)와 `llm:auto`(3-level: H/M/L)의 severity 어휘가 5곳에 분산 정의된다: `subagent-output-schema.md`, `peer-review-cli.md`(프롬프트 인라인), `git:review SKILL.md`(프롬프트 인라인), `peer-cli.md`(H/M/L 인라인). 어휘가 분산되면 정의 불일치 위험이 생기고 변경 시 여러 파일을 동시에 수정해야 한다.

## Decision Drivers

* DRY — severity 어휘 SOT 단일화
* H/M/L alias와 4-level 표준의 명시적 매핑 제공
* 향후 level 추가/변경 시 1곳만 수정

## Considered Options

* **추출**: `plugins/_shared/references/severity-taxonomy.md` 신규, 5곳에서 인라인 정의 제거 후 참조
* **인라인 유지**: 5곳에 각자 정의 유지
* **단일 파일 통합**: 한 플러그인 파일(예: subagent-output-schema.md)을 SOT로 지정하고 나머지에서 참조

## Decision Outcome

Chosen option: "추출", because 크로스플러그인(git+llm) 공유 어휘이므로 `_shared/`가 유일하게 적합한 위치이며, 기존 `peer-fallback-core.md` 패턴(ADR-0046)과 일관된다.

### Consequences

* Good, because severity 어휘를 1곳에서 관리, H/M/L alias 명시 매핑 제공
* Good, because `_shared/` 패턴 일관성 유지
* Bad, because 머지 공식은 각 파일 유지 — llm:auto Union/Intersection과 git:review severity×agreement fix-gate는 게이팅 축이 달라 통합 불가

### Confirmation

```bash
ls plugins/_shared/references/severity-taxonomy.md
grep -c 'critical=security' plugins/git/skills/review/references/peer-review-cli.md  # 0
grep -c 'critical=security' plugins/git/skills/review/SKILL.md                       # 0
grep -c 'H=high'            plugins/llm/skills/auto/references/peer-cli.md           # 0
```

## Pros and Cons of the Options

### 추출

* Good, because 크로스플러그인 SOT — 변경 파급 최소화
* Good, because H/M/L alias 명시 매핑으로 모호성 제거
* Bad, because 파일 참조 깊이 1단계 증가

### 인라인 유지

* Good, because 각 파일 자체 완결
* Bad, because 5곳 중 어느 하나라도 불일치 발생 시 발견 어려움

### 단일 파일 통합

* Neutral, because 기존 파일 재활용 가능
* Bad, because 크로스플러그인 공유를 플러그인 내부 파일이 담는 것은 경계 위반

## More Information

* [ADR-0046](0046-shared-peer-fallback-core.md) — `_shared/references/` 패턴 선례
* [ADR-0034](0034-llm-plugin-4way-and-context-map-deprecation.md) — llm:auto 4-way 폴백
* 머지 공식 통합 금지 근거: llm:auto Union/Intersection vs git:review severity×agreement — 게이팅 축이 다름
