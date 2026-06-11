# restful-api 티어 분류 휴리스틱 정립 및 규칙 재분류

* Status: accepted
* Date: 2026-06-11
* Decision Makers: ppzxc

## Context and Problem Statement

AIP-121/136/216을 restful-api 가이드라인에 보강(PR #145·#146)하면서 신규 규칙에 T1/T2/T3을 부여했다. 그러나 ADR-0010은 티어의 추상 기준(하위호환 위험/보안/HTTP 표준/핵심 계약 = T1 등)만 정의할 뿐, "같은 성격의 규칙을 일관되게 어느 티어에 넣는가"를 판정하는 운용 휴리스틱이 없다. 그 결과 자가 점검에서 동일 성격 규칙이 서로 다른 티어로 분류된 비일관 사례가 다수 발견됐다 — 예: 커스텀 동사 네이밍은 T2인데 다른 모든 네이밍 규칙(경로·쿼리·필드·상태값)은 T1, 상태 미니멀리즘이 운영 편의(T2)로 분류, OpenAPI CI 검증이 계약도 아닌데 T1.

## Decision Drivers

* 동일 성격 규칙의 티어 일관성
* 향후 신규 규칙 추가 시 재론 없이 즉시 판정 가능한 기준
* ADR-0010의 추상 기준을 운용 가능한 휴리스틱으로 구체화
* 프로파일(Essential/Standard/Full) 멤버십의 예측 가능성

## Considered Options

* **휴리스틱 명문화 + 비일관 규칙 재분류** (본 ADR)
* **케이스별 임의 판단 유지** (현행)
* **외부 표준(AIP/Google 자체 우선순위)에 티어 위임**

## Decision Outcome

Chosen option: "휴리스틱 명문화 + 재분류". ADR-0010 기준을 다음 판정 휴리스틱으로 구체화한다:

| 규칙 성격 | 티어 | 이유 |
|---|---|---|
| 네이밍/포맷 (경로·필드·커스텀 동사·상태값) | **T1** | 출시 후 rename = 하위호환 파괴 |
| 와이어 포맷·상태코드 의미 | **T1** | 늦게 변경 시 파괴(semantic change) |
| 보안 가드 (기능 제공 시 필수) | **T1** | OWASP/DoS 방어 필수 |
| 기능 "제공 여부" | **T2** | 가산적 — 나중 도입해도 비파괴 |
| 기능 "제공 시 문법/계약" | **T1** | 일단 출시되면 하드 계약 |
| 프로세스·거버넌스·advisory | **T2~T3** | API 계약이 아님 |
| 고급·도메인 한정 패턴 | **T3** | 특정 도메인에만 적용 |

이 휴리스틱으로 비일관 규칙을 재분류했다(PR #147·#148):

| 규칙 | 변경 | 적용 휴리스틱 |
|---|---|---|
| 커스텀 동사 네이밍 (AIP-136) | T2 → T1 | 네이밍 = 파괴 |
| 상태 미니멀리즘 (AIP-216) | T2 → T3 | advisory/거버넌스 |
| OpenAPI 자동 CI 검증 | T1 → T2 | 프로세스(계약 아님) |
| 필터 표현식 제공 (AIP-160) | T1 → T2 | 기능 제공 = 가산적 |
| 필터 문법 준수 (신규 분리) | (신규) → T1 | 제공 시 문법 = 계약 |
| 단순 일치 필터 | T1 → T2 | 기능 제공 = 가산적 |
| 리소스 확장 DoS 한도 | (묵시) → T1 | 보안 가드 |
| 캐싱 ETag 표기 | (정리) | 제공 의무 T1 · 재검증 동작 T2 분리 |

### Consequences

* Good, because 신규 규칙 티어를 휴리스틱으로 즉시·일관 판정 가능
* Good, because 동일 성격 규칙의 티어 모순 제거
* Neutral, 티어 규칙 수: Essential ~90 / Standard ~131 / Full ~158로 조정
* Bad, because 프로파일 멤버십이 변동 — Essential에 커스텀 동사 네이밍·확장 DoS 한도가 새로 포함되고, OpenAPI CI 검증은 Standard로 내려감(일회성)

### Confirmation

```bash
# 네이밍 규칙은 T1
grep -n "Custom verb naming" plugins/guideline/skills/restful-api/SKILL.md    # `[T1]`
# CI 검증은 T2
grep -n "Automated validation" plugins/guideline/skills/restful-api/SKILL.md  # `[T2]`
# 필터 문법 계약(T1) 분리 존재
grep -c "Filter syntax is a contract" plugins/guideline/skills/restful-api/SKILL.md  # 1
# 프로파일 카운트
grep -E "~90|~131|~158" plugins/guideline/skills/restful-api/SKILL.md
```

## Pros and Cons of the Options

### 휴리스틱 명문화 + 재분류

* Good, because 일관성·재론 방지·예측 가능
* Bad, because 기존 프로파일 멤버십 변동(일회성)

### 케이스별 임의 판단 유지

* Good, because 추가 문서 불필요
* Bad, because 비일관 누적, 신규 규칙마다 재론 발생

### 외부 표준에 티어 위임

* Neutral, because 권위 있는 근거 확보
* Bad, because AIP는 REST/HTTP 전용 티어 개념이 없어 직접 매핑 불가

## More Information

* 본 ADR은 ADR-0010(T1/T2/T3 티어 프로필 시스템)을 **구체화**하며, ADR-0005(AIP 리소스 중심 설계·콜론 커스텀 메서드), ADR-0007(AIP 리소스 수명주기), ADR-0008(AIP filter/updateMask/Partial Response)에서 도입된 규칙들의 티어를 재정렬한다. supersede 관계는 없다.
* 콘텐츠 보강 PR: #145(AIP-121·AIP-136), #146(AIP-216 강조점). 티어 재분류 PR: #147(1차), #148(2차).
* guideline 플러그인 v0.8.2 기준.
