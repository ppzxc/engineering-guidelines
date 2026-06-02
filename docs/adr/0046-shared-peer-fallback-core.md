# Peer-CLI 공통 인프라를 _shared/references/peer-fallback-core.md로 추출

* Status: accepted
* Date: 2026-06-02
* Decision Makers: ppzxc

## Context and Problem Statement

`plugins/git/skills/review/references/peer-review-cli.md`(311줄)와 `plugins/llm/skills/auto/references/peer-cli.md`(191줄)에 동일한 인프라 블록이 중복된다: pre-flight `timeout 3 <cli> --version`, host fallback matrix 패턴, CLI 호출 헤더(stdin pipe/injection 방지), mktemp+trap+timeout 호출 골격, sentinel 처리 표. 두 파일을 독립적으로 수정하면 불일치(sentinel 문법 차이 등)가 발생한다.

## Decision Drivers

* DRY — 공통 인프라 변경 시 1곳만 수정
* sentinel 문법 불일치 해소 (AGY_NOT_FOUND: vs CLI_NOT_FOUND: 혼용)
* 신규 CLI 추가 시 단일 파일만 갱신

## Considered Options

* **추출**: `plugins/_shared/references/peer-fallback-core.md` 신규, 두 peer-cli 파일에서 공통 블록 제거 후 참조
* **인라인 유지**: 두 파일에 중복 그대로 유지
* **단순 주석**: 참조 주석만 추가, 실제 블록은 그대로 유지

## Decision Outcome

Chosen option: "추출", because 공통 블록을 1곳으로 통합하면 sentinel 문법 표준화와 향후 CLI 추가/변경이 단일 파일 수정으로 완결된다.

### Consequences

* Good, because pre-flight / sentinel 카탈로그를 1곳에서 관리
* Good, because sentinel 통합 prefix `CLI_NOT_FOUND:<cli>` 표준화로 파일 간 불일치 제거
* Bad, because peer-cli 파일을 읽을 때 peer-fallback-core.md도 함께 참조해야 함

### Confirmation

```bash
ls plugins/_shared/references/peer-fallback-core.md
grep -c 'CLI_NOT_FOUND:agy' plugins/git/skills/review/references/peer-review-cli.md   # ≥0 (old AGY_NOT_FOUND 미존재)
grep -c 'AGY_NOT_FOUND'     plugins/git/skills/review/references/peer-review-cli.md   # 0
grep -c 'AGY_NOT_FOUND'     plugins/llm/skills/auto/references/peer-cli.md            # 0
```

## Pros and Cons of the Options

### 추출

* Good, because 단일 SOT — 변경 파급 최소화
* Good, because sentinel 문법 표준화 강제 가능
* Bad, because 파일 참조 깊이 1단계 증가

### 인라인 유지

* Good, because 각 파일 자체 완결
* Bad, because 불일치 재발 방지 불가 (sentinel 문법 등)
* Bad, because CLI 추가 시 N개 파일 동시 수정 필요

### 단순 주석

* Neutral, because 읽기 편의 개선
* Bad, because 실제 중복 제거 안 됨, 불일치 재발 위험 동일

## More Information

* [ADR-0022](0022-bidirectional-peer-cross-review.md) — 자기 호스트 제외 규칙
* [ADR-0034](0034-llm-plugin-4way-and-context-map-deprecation.md) — llm 4-way 폴백 체인
* `.claude/rules/git-rules.md` — `[ADR-0046]` 태그
* `.claude/rules/llm-rules.md` — `[ADR-0046]` 태그
