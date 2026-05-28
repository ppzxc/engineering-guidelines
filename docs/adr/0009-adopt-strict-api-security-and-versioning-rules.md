---
status: accepted
date: 2026-04-05
decision-makers: ppzxc
consulted:
informed:
---

# Adopt Strict API Security (OWASP Top 10) and Versioning Rules

## Context and Problem Statement

기존 API 설계 가이드라인은 RESTful 원칙과 Google AIP를 수용하였으나, OWASP API Security Top 10 관점의 방어 규정이 누락되었거나 약했습니다 (예: BOLA 방지, BOPA 방지, Expand N+1 폭탄). 또한 버전 헤더 누락 시 최신 버전을 제공하는 하위 호환성 파괴 모순과 ETag-Partial Response 간의 모순이 존재했습니다. 안전하고 견고한 API 스펙을 보장하기 위해 강력한 통제(MUST) 기반의 보안 규칙을 도입해야 합니다.

## Decision Drivers

* API의 하위 호환성은 클라이언트 요청 헤더 누락 여부와 무관하게 보장되어야 한다.
* OWASP API Security Top 10 (BOLA, BOPA) 취약점을 원천 차단해야 한다.
* 성능 저하 및 자원 고갈(DoS)을 유발하는 설계 허점을 막아야 한다.

## Considered Options

* Option 1: 엄격한 표준 통제 (Strict Enforcement) - 규칙 위반 시 400 에러 및 강력한 MUST 규정 적용.
* Option 2: 유연한 점진적 도입 (Progressive Adoption) - 핵심 도메인 외에는 권고(SHOULD) 수준으로 적용.

## Decision Outcome

Chosen option: "Option 1: 엄격한 표준 통제 (Strict Enforcement)", because 잠재적인 보안 사고와 호환성 붕괴를 원천 차단하는 가장 견고한 설계 원칙을 세우는 것이 API 가이드라인의 본질적 목적에 부합하기 때문입니다.

### Consequences

* Good, because 보안 취약점(BOLA, 대량 할당 등)이 아키텍처 수준에서 방어됨.
* Good, because 하위 호환성 보장이 엄격해짐 (버전 헤더 강제화).
* Bad, because 기존 유연한 API에 익숙한 클라이언트 개발자는 초기 적용 시 엄격한 규정(헤더 필수 등)에 불편을 느낄 수 있음.

### Confirmation

API 플러그인의 `README.md` 및 `SKILL.md` 문서 내에 `MUST` 키워드로 해당 규칙들이 명시되었는지 수동 리뷰한다.

## More Information

해당 결정에 따라 추출된 규칙은 `.claude/rules/api-rules.md` (신규) 파일에 저장되어 향후 API 검토 시 강제된다.
