---
status: accepted
date: 2026-04-04
decision-makers: ppzxc
---

# Adopt AIP Filter Expression, Mandatory FieldMask, and Partial Response

## Context and Problem Statement

v0.0.9에서 핵심 5개 AIP 패턴(Field Behavior, ETag, State Enum, Soft Delete, Dry Run) 구현 완료 후
TODO.md의 추가 3개 항목을 검토했다. 각 항목에 대해 기존 방식 유지 또는 AIP 방식 전면 전환 중
하나를 결정해야 한다:

1. **필터링**: 개별 쿼리 파라미터 6종 vs. AIP-160 단일 `filter` 표현식
2. **FieldMask**: updateMask 선택 지원(ADR-0005 결정) vs. AIP-161 방식 필수화
3. **Partial Response**: 미구현(`Coming soon`) vs. AIP-157 기본 규칙 추가

## Decision Drivers

* 표현력 증가 — 개별 파라미터로는 부정(`NOT`), 복합 OR/AND 조합, 중첩 필드 필터가 불가능
* 데이터 무결성 — updateMask 없이 PATCH 시 body 기반 업데이트는 클라이언트 실수로 의도치 않은 필드 변경 가능
* 응답 최적화 — 클라이언트가 필요한 필드만 수신하여 페이로드 크기 절감
* ADR-0005 번복 — updateMask 필수화가 "클라이언트 부담 과다"로 기각됐으나, 명시적 계약이 주는 안전성이 부담보다 크다는 재평가

## Considered Options

* AIP-160: Option A — 기존 개별 파라미터 유지 / Option B — `filter` 표현식으로 전면 교체
* AIP-161: Option A — 선택 지원 유지 + 상세 동작 규칙 추가 / Option B — 필수화(AIP 원본)
* AIP-157: Option A — 기본 규칙 추가 / Option B — 계속 미구현

## Decision Outcome

Chosen option:
- **AIP-160**: Option B — `filter` 표현식으로 전면 교체
- **AIP-161**: Option B — updateMask 필수화 (ADR-0005 부분 번복)
- **AIP-157**: Option A — 기본 규칙 추가

개별 파라미터 방식은 단순 필터에는 충분하지만 표현력 한계가 명확하고, 단일 `filter` 파라미터로
통일하면 문법이 일관되어 클라이언트 라이브러리 구현도 단순해진다. updateMask 필수화는 클라이언트
부담이 있지만 PATCH의 의도를 명시적으로 선언하여 부분 업데이트 버그 클래스를 원천 차단한다.

### Consequences

* Good, because `filter` 표현식으로 `NOT`, 복합 OR/AND, 중첩 필드 필터 표현 가능
* Good, because updateMask 필수화로 PATCH가 수정할 필드를 명시적 계약으로 선언
* Good, because Partial Response로 불필요한 필드 전송 제거, 모바일/저대역폭 클라이언트 최적화
* Bad, because `filter` 파라미터 파서를 서버에서 구현해야 함
* Bad, because updateMask 필수화로 기존 PATCH 클라이언트 수정 필요 (ADR-0005 번복 영향)
* Bad, because `fields` 파라미터 처리 로직 추가 필요

### Confirmation

`plugins/api/skills/restful-guidelines/SKILL.md`에서:
- PATCH 섹션에 `updateMask` 필수 규칙 및 Field Behavior 상호작용이 명시되어 있는지
- Filtering 섹션이 `filter` 표현식 문법(비교/논리/괄호/dot notation)으로 구성되어 있는지
- Partial Response 섹션이 `fields` 파라미터 규칙(id 항상 포함, dot notation, 400 에러)을 정의하는지

## Pros and Cons of the Options

### AIP-160 Option A: 개별 파라미터 유지

* Good, because 서버 파서 구현 불필요, 프레임워크 기본 쿼리 파싱으로 처리 가능
* Good, because Stripe, GitHub 등 업계 다수와 동일한 방식
* Bad, because `NOT` 조건, 복합 OR/AND 조합 표현 불가
* Bad, because 새 필터 조건 추가 시마다 파라미터 명명 규칙을 별도로 결정해야 함

### AIP-160 Option B: `filter` 표현식 전면 교체 (채택)

* Good, because 단일 파라미터로 임의 복잡도의 필터 표현 가능
* Good, because Google AIP, Microsoft OData, Zalando와 일관성
* Bad, because 서버에 표현식 파서 구현 필요
* Bad, because URL 인코딩 시 `%20`, `%3E` 등으로 가독성 저하 가능

### AIP-161 Option A: 선택 지원 유지 + 상세 규칙

* Good, because 클라이언트 하위 호환성 유지
* Bad, because updateMask 없는 PATCH에서 클라이언트 실수로 의도치 않은 필드가 초기화될 위험

### AIP-161 Option B: updateMask 필수화 (채택)

* Good, because PATCH 요청마다 수정 의도를 명시적으로 선언 — 실수에 의한 필드 덮어쓰기 방지
* Good, because Field Behavior(AIP-203)와의 상호작용 규칙을 명확히 정의 가능
* Bad, because 기존 PATCH 구현 클라이언트가 수정 필요

## More Information

* 이 결정은 [ADR-0005](0005-adopt-aip-resource-oriented-design-and-colon-custom-methods.md)의
  "Option C: AIP 전면 도입 — FieldMask 필수" 기각 결정을 부분적으로 번복한다.
  updateMask 필수화에 한해 ADR-0005 Cons 항목 "FieldMask 필수화의 구현 부담이 큼"을 재평가하여 채택.
* [Google AIP-160](https://google.aip.dev/160) — Filtering
* [Google AIP-161](https://google.aip.dev/161) — Field masks
* [Google AIP-157](https://google.aip.dev/157) — Partial responses
