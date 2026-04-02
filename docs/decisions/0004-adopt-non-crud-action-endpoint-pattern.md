# Adopt Non-CRUD Action Endpoint Pattern

## Status

superseded by [ADR 0005](0005-adopt-aip-resource-oriented-design-and-colon-custom-methods.md)

## Context and Problem Statement

`api:restful-guidelines` 스킬의 URL Design 섹션은 "No verbs in URLs"를 규정하면서,
HTTP Methods 섹션에서 POST의 목적을 "Create / execute"로 명시하고 있었다.
실무에서 주문 취소(`cancel`), 결제 승인(`approve`), 비밀번호 재설정(`reset-password`) 같은
비-CRUD 작업은 표준 HTTP 메서드만으로 깔끔하게 표현할 수 없다.

PATCH로 상태 필드를 변경하는 방식(`PATCH /orders/{id}` + `{"status":"cancelled"}`)은
단순 필드 수정으로 위장하지만, 실제로는 환불 처리, 알림 발송 등 복잡한 부작용을 수반한다.
이 모순을 해소할 명시적 action endpoint 패턴이 필요하다.

## Decision Drivers

* "No verbs" 규칙과 실무 action endpoint 간의 모순 해소
* side-effect가 있는 작업의 의도를 URL에서 명시적으로 표현
* 업계 주류 API(Stripe, Shopify, GitHub)와의 일관성
* HTTP 라이브러리/프록시 호환성

## Considered Options

* Option A: PATCH 오용 — `PATCH /orders/{id}` + `{"status":"cancelled"}`
* Option B: POST + verb sub-path — `POST /orders/{id}/cancel` (Stripe/Shopify 패턴)
* Option C: POST + colon syntax — `POST /orders/{id}:cancel` (Google Cloud 패턴)

## Decision Outcome

Chosen option: "Option B", because Stripe, Shopify, GitHub 등 업계 주류 API가 채택한 패턴이며,
HTTP 표준과의 호환성이 가장 높고, 개발자에게 가장 익숙한 형태이기 때문이다.

### Consequences

* Good: action의 의도가 URL에서 명시적으로 드러남 — `POST /orders/{id}/cancel`
* Good: side-effect를 수반하는 작업이 단순 필드 수정과 구분됨
* Good: Stripe (`/charges/{id}/capture`), Shopify (`/orders/{id}/cancel`), GitHub (`/pulls/{number}/merge`)와 일관
* Good: 콜론 없이 표준 URL 구문만 사용하여 모든 HTTP 라이브러리/프록시와 호환
* Bad: "No verbs in URLs" 원칙의 예외를 도입하여 규칙 해석에 판단이 필요해짐 — SKILL.md에 명확한 DO/DON'T 테이블로 완화

## Pros and Cons of the Options

### Option A: PATCH 오용

* Good: 기존 "No verbs" 규칙 유지
* Bad: side-effect(환불, 알림 등)가 단순 필드 변경으로 위장됨
* Bad: API 소비자가 `status` 변경의 부작용을 예측할 수 없음
* Bad: 여러 다른 action을 동일한 `PATCH` 엔드포인트에서 처리하게 됨

### Option B: POST + verb sub-path (Stripe/Shopify 패턴)

* Good: 업계 최다 채택 패턴 — Stripe, Shopify, GitHub, Twilio
* Good: 표준 URL 구문 사용, 모든 HTTP 도구와 호환
* Good: action의 의도가 URL에서 즉시 파악 가능
* Bad: "No verbs" 원칙의 예외 필요

### Option C: POST + colon syntax (Google Cloud 패턴)

* Good: Google Cloud API Design Guide에서 공식 권장
* Good: 리소스 경로와 action을 구분 기호(`:`)로 명확히 분리
* Bad: Google 고유 패턴으로 범용성이 낮음
* Bad: 일부 HTTP 라이브러리/프록시에서 URL 경로 내 콜론을 특수 문자로 처리하여 호환성 문제 발생 가능
* Bad: RFC 3986에서 콜론은 scheme 구분에 사용되는 문자로, path segment에서의 사용이 혼란을 유발할 수 있음
