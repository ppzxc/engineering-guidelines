---
status: accepted
date: 2026-04-06
decision-makers: ppzxc
consulted:
informed:
---

# Adopt Tiered API Profile System for Incremental Adoption

## Context and Problem Statement

API 플러그인(`plugins/api/`)은 21개 주제, ~156개 규칙을 하나의 SKILL.md에 담고 있다. 평가 커버리지 97%+를 달성하여 스펙 완성도는 높으나, 모든 규칙이 동등하게 강제되는 구조로 인해 소규모 팀이나 기존 프로젝트 마이그레이션 시 채택 장벽이 크다. "처음부터 모든 규칙을 적용하라"는 접근은 현실적으로 불가능하여 스펙 자체가 무시되는 결과를 초래한다. 팀 성숙도와 프로젝트 단계에 따라 점진적으로 도입할 수 있는 구조가 필요하다.

## Decision Drivers

* 후행 도입 시 하위 호환성을 파괴하는 규칙은 처음부터 강제해야 한다 (`Api-Version` 헤더, URL 패턴, 에러 포맷 등).
* 구현 비용이 높은 규칙(AIP-160 filter, updateMask, OpenAPI 린팅)을 필수로 강제하면 초기 도입이 불가능하다.
* 단일 문서를 유지하면서 점진적 도입 경로를 제공해야 한다.
* 규칙 간 의존성이 높아 파일 분리 시 맥락 손실이 발생한다.

## Considered Options

* Option A: Tiered + Profile 시스템 — 규칙에 T1/T2/T3 태그를 부여하고 Profile Guide로 점진적 도입 경로 제공
* Option B: Modular Split — SKILL.md를 5~7개 독립 스킬 파일로 분리
* Option C: 현상 유지 — 변경 없이 전체 스펙 유지

## Decision Outcome

Chosen option: "Option A: Tiered + Profile 시스템", because 기존 규칙을 삭제하지 않으면서 팀 성숙도별 점진적 도입 경로를 제공하고, 단일 문서의 참조 편의성을 유지하기 때문이다.

### Consequences

* Good, because 소규모 팀도 T1(Essential) 규칙부터 단계적으로 도입 가능하다.
* Good, because 기존 사용자에게 Breaking Change 없이 메타데이터만 추가된다.
* Good, because 에이전트가 프로필을 지정받으면 해당 Tier 이하 규칙만 선택 적용할 수 있다.
* Bad, because 156개 규칙에 수동 태깅이 필요하며 분류 기준의 주관성이 개입할 수 있다.
* Bad, because 에이전트가 태그를 무시할 경우 프로필 필터링이 동작하지 않는다 (폴백: Profile별 섹션 분리).

### Confirmation

* SKILL.md 내 모든 규칙에 `[T1]`, `[T2]`, `[T3]` 태그가 존재하는지 확인한다.
* Tier별 카운트 T1 ~80 / T2 ~45 / T3 ~31이 목표 범위 내인지 확인한다.
* `api-rules.md`의 모든 규칙에 `[T1]`과 `[ADR-0010]` 태그가 추가되었는지 확인한다.

## Pros and Cons of the Options

### Option A: Tiered + Profile 시스템

* Good, because 단일 문서 유지 — 규칙 간 교차 참조 맥락 보존
* Good, because 비파괴적 변경 — 기존 규칙 내용 수정 없음
* Good, because 팀 로드맵 제공 — Essential → Standard → Full 순서로 성장 경로 명확
* Neutral, because 태그가 텍스트 메타데이터이므로 자동 강제화는 불가능
* Bad, because 문서 길이가 증가하여 인지 부하가 일부 남음

### Option B: Modular Split

* Good, because 필요한 스킬만 선택 활성화 가능
* Good, because 각 파일이 50~80줄로 가독성 향상
* Bad, because 규칙 간 의존성이 높음 — CRUD → ETag → Caching → Versioning 체인에서 맥락 손실
* Bad, because 버전 관리 포인트 증가 (plugin.json 구조 변경, 기존 사용자 Breaking Change)
* Bad, because 스킬 간 교차 참조가 복잡해짐

### Option C: 현상 유지

* Good, because 작업 없음
* Bad, because 채택 장벽이 해결되지 않아 스펙이 사실상 무시됨
* Bad, because 모든 규칙이 동등하게 강제되어 우선순위 판단 불가

## Tier 분류 기준

규칙은 아래 기준에 따라 T1/T2/T3로 분류한다.

### T1 (Essential) — 모든 프로젝트에서 첫날부터 적용

다음 중 하나 이상 해당하는 규칙:

| 기준 | 예시 |
|------|------|
| 후행 도입 시 하위 호환성 파괴 | `Api-Version` 헤더, URL 패턴, 에러 포맷 구조 |
| 보안 필수 (위반 시 즉각적 취약점) | HTTPS, BOLA/BOPA 방지, 인증 헤더 |
| HTTP 표준 준수 (RFC 위반) | 상태 코드 의미, Content-Type, 메서드 시맨틱 |
| API 계약의 근간 (변경 시 전체 클라이언트 영향) | 필드명 컨벤션, 날짜 포맷, null 처리 |

### T2 (Standard) — 프로덕션 운영 단계에서 적용

구현 비용이 중간 수준이며, 후행 도입 시에도 기존 클라이언트에 영향이 없는 규칙:
페이지네이션 상세, 캐싱, CORS, Health Check, 레이트 리미팅, 버전관리 세부 정책 등.

### T3 (Full) — 대규모/엔터프라이즈 API에서 적용

구현 비용이 높거나 특정 도메인에서만 필요한 규칙:
Bulk Operations, Long-Running Operations, Webhooks, Soft Delete, Dry Run, OpenAPI CI 확장 등.

## More Information

* 이 결정에 따라 추가된 Tier 태그는 `.claude/rules/api-rules.md`에서 `[ADR-0010]`으로 참조된다.
* 에이전트 태그 무시 문제가 확인될 경우 Option B(Modular Split) 부분 적용을 재검토한다.
* Gemini Flash 크로스체크 피드백 반영: 버전 동기화 4곳 명시, ADR 태그 일관성 유지.
* 관련 ADR: ADR-0005 (AIP 리소스 중심 설계), ADR-0008 (filter/updateMask), ADR-0009 (보안/버저닝)
