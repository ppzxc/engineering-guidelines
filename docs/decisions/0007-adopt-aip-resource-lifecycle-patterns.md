---
status: accepted
date: 2026-04-04
decision-makers: ppzxc
---

# Adopt AIP Resource Lifecycle Patterns (2nd Wave)

## Context and Problem Statement

ADR-0005에서 Google AIP의 1차 도입(AIP-136 콜론 커스텀 메서드, AIP-121/131~135 리소스 중심 설계)을 완료했다.
그러나 `plugins/api/skills/restful-guidelines/SKILL.md`에는 리소스 수명주기 전반에서 빈번히 필요한
패턴 5가지가 여전히 미정의 상태다: 필드 분류 체계, 안전한 동시 수정, 상태 관리, 소프트 삭제, 사전 검증.
이 갭으로 인해 구현자가 매번 독자적인 패턴을 고안하여 API 일관성이 저하된다.

2차 AIP 도입 범위를 결정하여 수명주기 관련 설계 공백을 표준화한다.

## Decision Drivers

* 필드 분류 불명확 — REQUIRED/OUTPUT_ONLY 등 구분 없이 필드를 기술하여 클라이언트 혼란 발생
* 동시 수정 충돌 — Last-Write-Wins 방식의 데이터 손실 위험
* 상태 필드 비일관성 — 상태 Enum 명명 규칙이 API마다 상이
* 소프트 삭제 패턴 부재 — 복구 가능한 삭제 구현 방식이 표준화되지 않음
* 파괴적 작업 사전 검증 부재 — 대규모 변경 전 영향 범위 미리보기 불가

## Considered Options

* Option A: AIP 전면 도입 — Google AIP의 모든 패턴 적용
* Option B: 핵심 5개 선별 도입 — 실용적 수명주기 패턴만 채택
* Option C: 현행 유지 — 추가 도입 없음

## Decision Outcome

Chosen option: "Option B", because 실무에서 빈번히 요구되는 5개 패턴만 선별 도입하여
구현 부담을 최소화하면서 핵심 설계 공백을 제거할 수 있기 때문이다.

채택한 5개 AIP:

| AIP | 패턴 | 핵심 규칙 |
|-----|------|-----------|
| AIP-203 | Field Behavior Annotations | REQUIRED / OUTPUT_ONLY / INPUT_ONLY / IMMUTABLE / OPTIONAL / IDENTIFIER 6종 |
| AIP-154 | ETag 기반 낙관적 동시성 제어 | `If-Match` 헤더 + ETag 불일치 시 `412 Precondition Failed` |
| AIP-216 | State Enum 표준 패턴 | `state` 필드, `STATE_UNSPECIFIED` 기본값 필수 |
| AIP-164 | Soft Delete | `deleteTime`, `expireTime` 필드 + `undelete` 커스텀 메서드 |
| AIP-163 | Change Validation / Dry Run | `?validateOnly=true` 쿼리 파라미터 |

### Consequences

* Good, because 필드 가시성(AIP-203)으로 클라이언트가 읽기 전용/필수 필드를 OpenAPI 스펙에서 즉시 파악 가능
* Good, because ETag 낙관적 동시성(AIP-154)으로 동시 수정 충돌로 인한 데이터 손실 방지
* Good, because State Enum 표준화(AIP-216)로 상태 필드 명명이 API 전체에서 일관됨
* Good, because Soft Delete(AIP-164)로 실수 삭제 복구 경로가 표준화됨
* Good, because Dry Run(AIP-163)으로 파괴적 작업 전 영향 범위를 안전하게 미리 확인 가능
* Bad, because ETag 구현 시 서버 측 ETag 생성·검증 로직 추가 필요
* Bad, because Soft Delete 도입 시 DB 스키마에 `deleteTime` 컬럼 및 필터링 쿼리 추가 필요
* Bad, because validateOnly 엔드포인트는 실제 커밋 없이 검증만 수행하는 별도 코드 경로 필요

### 의도적 미채택 AIP

| AIP | 미채택 이유 |
|-----|------------|
| AIP-122/123 | gRPC 리소스 이름 체계 중심 — REST URL 설계가 이미 대체 |
| AIP-191 | protobuf 파일 구성 전용 — REST/JSON API와 무관 |
| AIP-161 FieldMask 필수화 | 클라이언트가 업데이트 마스크를 매번 명시해야 하는 구현 부담 과다 |
| AIP-159 | `$` 접두사 혼합 파라미터가 REST URL 라우팅 호환성 저해 |
| AIP-217 | 분산 시스템 위치 기반 라우팅 — 현재 프로젝트 범위 초과 |

### Confirmation

`plugins/api/skills/restful-guidelines/SKILL.md`에서 다음 항목이 포함되었는지 확인한다:

* 필드 어노테이션 6종(AIP-203) 설명
* ETag + `If-Match` 동시성 제어(AIP-154) 패턴 기술
* `state` 필드 및 `STATE_UNSPECIFIED`(AIP-216) 명시
* Soft Delete 필드명 및 `undelete` 커스텀 메서드(AIP-164) 기술
* `validateOnly=true` Dry Run 패턴(AIP-163) 기술

## Pros and Cons of the Options

### Option A: AIP 전면 도입

* Good, because Google AIP 생태계와 완전 일치
* Good, because gRPC-gateway, Google Cloud API와 최대 호환
* Bad, because AIP-161 FieldMask 필수화 등 클라이언트 구현 부담이 큼
* Bad, because AIP-122/123 리소스 이름 체계가 기존 REST URL 설계와 충돌
* Bad, because protobuf 전용 AIP(AIP-191 등)는 REST/JSON 환경에서 적용 불가

### Option B: 핵심 5개 선별 도입 (채택)

* Good, because 실무 빈도가 높은 패턴만 선별하여 비용 대비 효과 최대화
* Good, because REST/JSON 환경에서 직접 적용 가능한 패턴으로 한정
* Good, because 기존 ADR-0005 결정(콜론 커스텀 메서드, PATCH 기본)과 충돌 없음
* Neutral, because 미채택 AIP는 향후 필요 시 3차 도입으로 재검토 가능
* Bad, because 전면 도입 대비 AIP 생태계 도구 자동화 혜택이 제한적

### Option C: 현행 유지

* Good, because 추가 구현 부담 없음
* Good, because 현재 운영 중인 API에 변경 영향 없음
* Bad, because 동시 수정 충돌 위험이 지속됨
* Bad, because 상태/삭제/검증 패턴이 API마다 상이하여 클라이언트 혼란 지속
* Bad, because 소프트 삭제 미표준화로 복구 불가능한 삭제 사고 위험 잔존

## More Information

* 이 결정은 [ADR-0005](0005-adopt-aip-resource-oriented-design-and-colon-custom-methods.md)의 후속 결정이다.
* [Google AIP-203](https://google.aip.dev/203) — Field behavior documentation
* [Google AIP-154](https://google.aip.dev/154) — Resource freshness (ETag)
* [Google AIP-216](https://google.aip.dev/216) — States
* [Google AIP-164](https://google.aip.dev/164) — Soft delete
* [Google AIP-163](https://google.aip.dev/163) — Change validation
