# Adopt AIP Resource-Oriented Design and Colon Custom Methods

## Status

accepted — Supersedes [ADR 0004](0004-adopt-non-crud-action-endpoint-pattern.md)

## Context and Problem Statement

`api:restful-guidelines` 스킬은 Non-CRUD 액션에 슬래시 기반 sub-path 패턴(`POST /{resource}/{id}/{action}`)을
사용하고, PUT과 PATCH를 동등하게 허용하고 있었다. 또한 리소스 중심 설계(Resource-oriented design)가
명시적 최상위 원칙으로 선언되어 있지 않았다.

Google AIP(API Improvement Proposals)의 핵심 원칙을 부분적으로 도입하여:
1. 리소스 중심 설계를 최상위 원칙으로 명시한다 (AIP-121)
2. 커스텀 액션을 콜론 구문으로 교체하여 리소스 경로와 액션을 명확히 분리한다 (AIP-136)
3. PATCH를 기본 수정 메서드로, PUT은 콘텐츠 전체 교체에만 예외 허용한다 (AIP-131~135)

## Decision Drivers

* 리소스 경로와 액션의 명확한 시각적 분리 — 콜론(`:`)이 구분자 역할
* Google AIP 생태계(gRPC-gateway, Google Cloud API)와의 정렬
* 표준 메서드 우선 원칙 확립 — GET, POST, PATCH, DELETE를 우선 사용
* PUT의 역할 제한 — 새 필드 추가 시 데이터 손실 위험 방지
* RFC 3986 §3.3 부분 준수 — 절대 경로의 path segment 내 콜론은 허용되는 문자 (단, 상대 경로의 첫 번째 segment에는 사용 불가)

## Considered Options

* Option A: 현상 유지 — 슬래시 패턴 + PUT/PATCH 동등 허용
* Option B: AIP 부분 도입 — 콜론 커스텀 메서드 + PATCH 기본 + PUT 예외 허용
* Option C: AIP 전면 도입 — PUT 완전 배제 + FieldMask 필수

## Decision Outcome

Chosen option: "Option B", because 리소스/액션 분리와 PATCH 기본화의 실익을 얻으면서도,
파일 업로드 등 PUT이 의미론적으로 적합한 경우를 예외로 허용하여 실용성을 유지할 수 있기 때문이다.

### Consequences

* Good: 커스텀 액션이 리소스 경로와 시각적으로 분리됨 — `/orders/{id}:cancel`
* Good: `api:restful-guidelines` 스킬의 URL Design, HTTP Methods, Non-CRUD Actions, CRUD Behavior 섹션이 이 결정을 직접 구현함
* Good: AIP 생태계(gRPC-gateway, Google Cloud)와 정렬
* Good: PATCH 기본화로 새 필드 추가 시 데이터 손실 위험 원천 차단
* Good: 파일/바이너리 업로드에 PUT 예외 허용으로 실용성 유지
* Bad: Express.js, Rails 등 `:param` 구문 프레임워크에서 라우팅 설정 시 추가 처리 필요
* Bad: 일부 OpenAPI 코드 생성기에서 콜론 경로 처리 미흡 가능
* Bad: ADR 0004의 결정을 번복하여 기존 참조 문서와 불일치 발생

### Compatibility Notes

콜론(`:`)은 RFC 3986 path segment에서 명시적으로 허용되는 문자이며, HTTP 클라이언트(axios, fetch,
OkHttp, requests 등)와 주요 프록시(nginx, Envoy, Kong)에서 정상 처리된다.
다만 다음 환경에서 주의가 필요하다:

* **Express.js/Rails**: `:param` 구문과 충돌 — 정규식 라우트 사용
* **OpenAPI 코드 생성기**: 콜론 경로 지원 여부 확인 필요
* **AWS API Gateway (REST v1)**: 리소스 경로에 콜론 포함 시 추가 설정 필요

## Pros and Cons of the Options

### Option A: 현상 유지

* Good: 모든 HTTP 라이브러리/프록시와 100% 호환
* Good: Stripe, Shopify, GitHub 등 업계 다수 API와 일치
* Bad: 리소스 경로와 액션이 동일한 슬래시로 구분되어 시각적 구분 부재
* Bad: PUT의 데이터 손실 위험이 가이드에 명시되지 않음

### Option B: AIP 부분 도입 (채택)

* Good: 콜론으로 리소스/액션 명확 분리
* Good: AIP 생태계 정렬
* Good: PATCH 기본 + PUT 예외로 안전성과 실용성 균형
* Bad: 일부 프레임워크에서 라우팅 추가 처리 필요

### Option C: AIP 전면 도입

* Good: AIP와 완전 일치
* Good: PUT 배제로 데이터 손실 위험 완전 제거
* Bad: 파일 업로드 등 PUT이 적합한 실무 케이스를 커버하지 못함
* Bad: FieldMask 필수화의 구현 부담이 큼
