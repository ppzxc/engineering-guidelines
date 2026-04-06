# RESTful API Guidelines

> [English](README.md)

RESTful API 설계 가이드라인이다.

---

## 목차

1. [개요](#1-개요)
   - [규범 수준 표기](#규범-수준-표기)
2. [REST Basics](#2-rest-basics)
   - [URL 설계](#21-url-설계)
   - [HTTP 메서드 & 상태 코드](#22-http-메서드--상태-코드)
   - [쿼리 파라미터](#23-쿼리-파라미터)
   - [HTTP 헤더](#24-http-헤더)
   - [JSON 데이터 포맷](#25-json-데이터-포맷)
   - [에러 응답](#26-에러-응답)
3. [REST Design](#3-rest-design)
   - [리소스 스키마 & 필드 규칙](#31-리소스-스키마--필드-규칙)
   - [CRUD 처리](#32-crud-처리)
   - [액션](#33-액션)
   - [컬렉션 & 페이지네이션](#34-컬렉션--페이지네이션)
   - [필터링 & 정렬](#35-필터링--정렬)
   - [Partial Response](#36-partial-response)
   - [Expand/Embed](#37-expandembed)
   - [Bulk Operations](#38-bulk-operations)
4. [API 운영](#4-api-운영)
   - [4.1 API 버전 관리](#41-api-버전-관리)
   - [4.2 Deprecation](#42-deprecation)
   - [4.3 속도 제한](#43-속도-제한)
   - [4.4 장기 실행 작업](#44-장기-실행-작업)
   - [4.5 Idempotency-Key](#45-idempotency-key)
5. [인증 & 보안](#5-인증--보안)
   - [5.1 인증 방식](#51-인증-방식)
   - [5.2 401 vs 403 구분](#52-401-vs-403-구분)
   - [5.3 Webhooks](#53-webhooks)
6. [Health Check](#6-health-check)
7. [OpenAPI Specification](#7-openapi-specification)
   - [7.1 API First](#71-api-first)
   - [7.2 스펙 품질](#72-스펙-품질)
   - [7.3 스키마 매핑](#73-스키마-매핑)
   - [7.4 확장 & 검증](#74-확장--검증)
8. [참고 자료](#7-참고-자료)

---

## 1. 개요

### 목적

- 모든 RESTful API의 일관성, 예측 가능성, 유지보수성을 보장한다.
- API는 개발자가 소비하는 제품이다.
  - 직관적으로 이해 가능해야 한다.
  - 오류 발생 시 명확한 메시지를 제공해야 한다.
  - 버전이 바뀌어도 하위 호환성을 유지해야 한다.
- Roy Fielding의 RESTful 원칙 ([Architectural Styles and the Design of Network-based Software Architectures](https://roy.gbiv.com/pubs/dissertation/fielding_dissertation.pdf))을 참고한다.
  - HATEOAS는 구현하지 않는다.

### 적용 범위

- 조직 내 신규 개발되는 모든 HTTP/HTTPS API
- 기존 API 개선 시 가능한 한 적용

### 규범 수준 표기

이 문서에서 사용하는 "MUST", "MUST NOT", "SHOULD", "MAY", "DO NOT" 키워드는 [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119) 및 [RFC 8174](https://datatracker.ietf.org/doc/html/rfc8174)에 따라 해석한다.

| 기호 | 수준 | 설명 |
|------|------|------|
| ✅ **필수** | MUST / DO | 반드시 준수해야 하는 규칙 |
| ⚠️ **권장** | SHOULD / MAY | 가능하면 준수하는 것이 좋은 규칙 |
| ❌ **금지** | MUST NOT / DO NOT | 사용하지 말아야 하는 패턴 |

---

## 2. REST Basics

### 2.1 URL 설계

#### 기본 구조

```
https://{host}/{service-root}/{resource}/{id}
https://{host}/{service-root}/{resource}/{id}/{sub-resource}/{sub-id}
```

예시:

```
# 단일 리소스
GET https://api.example.com/orders/550e8400-e29b-41d4-a716-446655440000

# 중첩 서브리소스 (최대 깊이)
GET https://api.example.com/orders/550e8400-e29b-41d4-a716-446655440000/items/6ba7b810-9dad-11d1-80b4-00c04fd430c8
```

#### URL 케이싱

✅ **필수**: URL 경로에는 소문자 kebab-case를 사용한다.

```
# Good
GET /user-profiles
GET /product-categories/123

# Bad
GET /userProfiles
GET /UserProfiles
GET /user_profiles
```

✅ **필수**: 리소스 컬렉션 이름은 복수형 명사를 사용한다.

```
# Good
GET /articles
GET /users/123/comments

# Bad
GET /article
GET /user/123/comment
```

❌ **금지**: URL에 동사를 포함하지 않는다. 액션은 HTTP 메서드로 표현한다.

```
# Bad
POST /createUser
GET /getArticles
DELETE /deleteComment/123

# Good
POST /users
GET /articles
DELETE /comments/123
```

❌ **금지**: URL에 파일 확장자(`.json`, `.xml`)를 포함하지 않는다. 콘텐츠 협상은 `Accept` 헤더를 사용한다.

#### URL 중첩 깊이

✅ **필수**: URL 중첩은 최대 2단계(리소스/ID/서브리소스/ID)까지 허용한다.

| 깊이 | 패턴 | 예시 | 허용 |
|------|------|------|------|
| 0 | `/{resource}` | `/articles` | ✅ |
| 1 | `/{resource}/{id}` | `/articles/123` | ✅ |
| 2 | `/{resource}/{id}/{sub}` | `/articles/123/comments` | ✅ |
| 2 | `/{resource}/{id}/{sub}/{subId}` | `/articles/123/comments/456` | ✅ |
| 3+ | `/{a}/{id}/{b}/{id}/{c}` | — | ❌ |

❌ **금지**: 3단계 이상 중첩하지 않는다. 깊은 관계는 최상위 리소스로 승격한다.

| 상황 | ✅ Do | ❌ Don't |
|------|-------|---------|
| 주문 내 항목 | `/orders/{orderId}/items/{itemId}` | `/users/{userId}/orders/{orderId}/items/{itemId}` |
| 주문 항목의 리뷰 | `/order-items/{itemId}/reviews/{reviewId}` | `/users/{userId}/orders/{orderId}/items/{itemId}/reviews/{reviewId}` |

---

#### 허용 문자

✅ **필수**: URL 경로 세그먼트에는 ASCII 영소문자, 숫자, 하이픈(`-`)만 사용한다.

✅ **필수**: 쿼리 파라미터 이름은 camelCase를 사용한다.

```
# Good
GET /articles?pageSize=20&sortOrder=desc

# Bad
GET /articles?page_size=20&sort_order=desc
```

---

#### URL 길이

⚠️ **권장**: URL은 2000자 이하로 유지한다. 그 이상이 필요한 경우 쿼리 파라미터를 요청 본문으로 이동하는 것을 고려한다.

---

### 2.2 HTTP 메서드 & 상태 코드

#### HTTP 메서드

| 메서드 | 의미 | 멱등성 | 안전성 |
|--------|------|--------|--------|
| GET | 리소스 조회 | ✅ | ✅ |
| POST | 리소스 생성 또는 액션 수행 | ❌ | ❌ |
| PUT | 리소스 완전 대체 | ✅ | ❌ |
| PATCH | 리소스 부분 수정 | ❌ | ❌ |
| DELETE | 리소스 삭제 | ✅ | ❌ |
| HEAD | 헤더만 조회 | ✅ | ✅ |

✅ **필수**: GET 요청은 서버 상태를 변경하지 않는다.

✅ **필수**: PUT 요청은 멱등적으로 동작한다 — 같은 요청을 여러 번 보내도 결과가 동일해야 한다.

⚠️ **권장**: 부분 수정에는 PUT 대신 PATCH를 사용한다.

❌ **금지**: GET, HEAD, DELETE 요청에 요청 본문(body)을 포함하지 않는다.

#### 상태 코드

✅ **필수**: 아래 표준 HTTP 상태 코드를 정확한 의미에 맞게 사용한다.

**2xx 성공**

| 코드 | 의미 | 사용 시점 |
|------|------|-----------|
| 200 OK | 성공 | GET, PUT, PATCH, POST(액션) 성공 |
| 201 Created | 생성됨 | POST로 리소스 생성 성공 |
| 204 No Content | 내용 없음 | DELETE 성공, 응답 본문 없음 |

**4xx 클라이언트 오류**

| 코드 | 의미 | 사용 시점 |
|------|------|-----------|
| 400 Bad Request | 잘못된 요청 | 요청 형식 오류, 유효성 검사 실패 |
| 401 Unauthorized | 인증 필요 | 인증 토큰 없음 또는 만료 |
| 403 Forbidden | 접근 금지 | 인증은 되었지만 권한 없음 |
| 404 Not Found | 찾을 수 없음 | 리소스 존재하지 않음 |
| 409 Conflict | 충돌 | 중복 리소스, 낙관적 잠금 실패 |
| 422 Unprocessable Entity | 처리 불가 | 의미론적 유효성 검사 실패 |
| 429 Too Many Requests | 요청 과다 | 속도 제한 초과 |

**5xx 서버 오류**

| 코드 | 의미 | 사용 시점 |
|------|------|-----------|
| 500 Internal Server Error | 서버 오류 | 예기치 못한 서버 오류 |
| 503 Service Unavailable | 서비스 불가 | 일시적 서버 과부하 또는 유지보수 |

✅ **필수**: 201 Created 응답에는 `Location` 헤더로 생성된 리소스의 URL을 포함한다.

```
HTTP/1.1 201 Created
Location: https://api.example.com/users/articles/456
Content-Type: application/json

{
  "id": "456",
  "title": "새 글 제목"
}
```

❌ **금지**: 오류 상황에 200 OK를 반환하지 않는다.

---

### 2.3 쿼리 파라미터

✅ **필수**: 쿼리 파라미터 이름은 camelCase를 사용한다.

✅ **필수**: 동일한 파라미터 이름을 반복하여 배열 값을 전달한다.

```
GET /articles?tag=tech&tag=design
```

⚠️ **권장**: 쿼리 파라미터는 선택적(optional)으로 설계한다. 필수 값은 경로(path)에 포함한다.

⚠️ **권장**: 쿼리 파라미터에 민감한 정보(비밀번호, 토큰 등)를 포함하지 않는다. 이는 서버 로그에 기록될 수 있다.

❌ **금지**: 서버 상태를 변경하는 작업에 쿼리 파라미터를 사용하지 않는다.

---

### 2.4 HTTP 헤더

#### 요청 헤더

✅ **필수**: 요청 본문이 있는 경우 `Content-Type` 헤더를 포함한다.

```
Content-Type: application/json
```

⚠️ **권장**: 응답 형식 협상을 위해 `Accept` 헤더를 사용한다.

```
Accept: application/json
```

#### 응답 헤더

✅ **필수**: 응답 본문이 있는 경우 `Content-Type` 헤더를 포함한다.

⚠️ **권장**: 캐싱 전략을 명시하기 위해 `Cache-Control` 헤더를 사용한다.

```
Cache-Control: no-cache
Cache-Control: max-age=3600
```

⚠️ **권장**: 컬렉션 페이지네이션 응답에는 RFC 8288 `Link` 헤더를 사용한다.

```
Link: <https://api.example.com/articles?pageSize=20&pageToken=abc>; rel="next",
      <https://api.example.com/articles?pageSize=20>; rel="first"
```

⚠️ **권장**: 전체 항목 수를 제공할 때 `Total-Count` 헤더를 사용한다.

```
Total-Count: 100
```

#### 커스텀 헤더

⚠️ **권장**: 커스텀 헤더 이름은 `X-` 접두사 없이 명확한 이름을 사용한다. RFC 6648(2012)에서 `X-` 접두사는 deprecated됐다.

```
Request-Id: abc-123
Correlation-Id: xyz-789
```

> **참고**: `X-Request-Id`, `X-Correlation-Id` 등 기존에 사실상 표준처럼 굳어진 헤더는 레거시 호환을 위해 허용된다. 신규 커스텀 헤더에는 `X-` 접두사를 붙이지 않는다.

#### 요청 추적

✅ **필수**: 모든 응답에 `Request-Id` 헤더(UUID v4)를 포함한다.

```
Request-Id: 550e8400-e29b-41d4-a716-446655440000
```

- 클라이언트가 `Request-Id`를 전송하면 서버는 이를 수용하거나 새로 생성한다
- 마이크로서비스 간 `Request-Id`를 전파하여 분산 추적에 활용한다
- 모든 서비스 로그에 `Request-Id`를 포함하여 디버깅 상관관계를 확보한다
- 에러 응답(RFC 9457)의 `traceId` 필드는 `Request-Id` 헤더 값과 일치해야 한다

❌ **금지**: 표준 HTTP 헤더의 의미를 재정의하지 않는다.

---

### 2.5 JSON 데이터 포맷

#### 필드 네이밍

✅ **필수**: JSON 필드 이름은 camelCase를 사용한다.

```json
// Good
{
  "userId": "123",
  "createdAt": "2024-01-20T10:00:00Z",
  "isActive": true
}

// Bad
{
  "user_id": "123",
  "created_at": "2024-01-20T10:00:00Z",
  "is_active": true
}
```

✅ **필수**: 필드 이름은 영소문자로 시작한다.

❌ **금지**: 필드 이름에 약어를 남용하지 않는다. 명확한 전체 단어를 우선한다.

```json
// Bad
{
  "usr": "john",
  "ts": "2024-01-20T10:00:00Z",
  "cnt": 5
}

// Good
{
  "username": "john",
  "timestamp": "2024-01-20T10:00:00Z",
  "count": 5
}
```

#### 타입 시스템

##### Boolean

✅ **필수**: Boolean 값에는 JSON `true`/`false`를 사용한다. 문자열 `"true"`/`"false"` 또는 숫자 `1`/`0`을 사용하지 않는다.

✅ **필수**: Boolean 필드 이름은 `is`, `has`, `can` 등의 접두사를 사용한다.

```json
{
  "isActive": true,
  "hasPermission": false,
  "canEdit": true
}
```

##### Number

✅ **필수**: 숫자 값은 JSON number 타입을 사용한다.

⚠️ **권장**: JavaScript의 안전한 정수 범위(2^53 - 1)를 초과하는 큰 정수는 문자열로 반환한다.

```json
{
  "count": 42,
  "price": 19.99,
  "largeId": "9007199254740993"
}
```

##### String

⚠️ **권장**: 빈 문자열(`""`)과 `null`을 구분하여 사용한다. 의미 있는 "값 없음"에는 필드를 제외하고, 의도적으로 빈 값임을 나타낼 때만 빈 문자열을 사용한다.

#### 날짜와 시간

✅ **필수**: 모든 날짜/시간 값은 RFC 3339 형식(ISO 8601 프로파일)의 문자열로 표현한다.

✅ **필수**: 시간대(timezone)가 있는 경우 반드시 포함한다. UTC인 경우 `Z`를 사용한다.

✅ **필수**: 서버 응답의 모든 시간 값은 UTC(`Z`)로 반환한다. 클라이언트가 로컬 시간대로 변환한다.

⚠️ **권장**: 클라이언트 요청의 시간 값도 UTC(`Z`)로 전송한다. 오프셋이 포함된 경우 서버가 UTC로 정규화하여 저장한다.

⚠️ **권장**: 날짜만 필요한 필드(생년월일 등)는 `YYYY-MM-DD` 형식을 사용하며 시간대를 포함하지 않는다.

❌ **금지**: Unix timestamp(epoch milliseconds/seconds)를 기본 시간 형식으로 사용하지 않는다.

##### 서버 응답 예시

```json
{
  "createdAt": "2024-01-20T10:00:00Z",
  "scheduledAt": "2024-01-25T00:30:00Z",
  "birthDate": "1990-05-15"
}
```

##### 클라이언트 요청 예시

```json
// ⚠️ 권장: UTC
{ "scheduledAt": "2024-01-25T00:30:00Z" }

// 허용: 오프셋 포함 → 서버가 UTC로 정규화 저장
{ "scheduledAt": "2024-01-25T09:30:00+09:00" }
```

##### 서버 정규화 규칙

✅ **필수**: 클라이언트가 오프셋이 포함된 시간을 전송하면, 서버는 이를 UTC로 변환하여 저장한다. 에러를 반환하지 않는다.

✅ **필수**: 서버가 정규화한 후의 응답은 항상 UTC(`Z`)로 반환한다.

⚠️ **권장**: 시간대 정보가 비즈니스적으로 중요한 경우(예: 사용자의 원래 시간대 보존), 별도의 `timeZone` 필드를 사용한다.

```json
{
  "scheduledAt": "2024-01-25T00:30:00Z",
  "timeZone": "Asia/Seoul"
}
```

#### Enum 처리

✅ **필수**: Enum 값은 UPPER_SNAKE_CASE 문자열을 사용한다.

```json
{
  "status": "PUBLISHED",
  "priority": "HIGH"
}
```

⚠️ **권장**: 클라이언트가 알 수 없는 Enum 값을 수신할 수 있도록 설계한다. 새로운 Enum 값이 추가될 때 기존 클라이언트가 깨지지 않도록 처리한다.

❌ **금지**: Enum 값으로 숫자나 불명확한 약어를 사용하지 않는다.

```json
// Bad
{
  "status": 1,
  "priority": "hi"
}

// Good
{
  "status": "PUBLISHED",
  "priority": "HIGH"
}
```

---

### 2.6 에러 응답

#### 에러 응답 구조

✅ **필수**: 모든 에러 응답은 RFC 7807 / RFC 9457 (Problem Details for HTTP APIs) 표준을 따른다.

✅ **필수**: 에러 응답의 `Content-Type`은 `application/problem+json`을 사용한다.

```json
{
  "type": "https://api.example.com/errors/resource-not-found",
  "title": "리소스를 찾을 수 없음",
  "status": 404,
  "detail": "요청한 게시글을 찾을 수 없습니다.",
  "instance": "/articles/999",
  "traceId": "abc-123-xyz"
}
```

| 필드 | 필수 여부 | 설명 |
|------|-----------|------|
| `type` | ✅ 필수 | 에러 유형을 식별하는 URI (문서 링크 역할, `about:blank` 허용) |
| `title` | ✅ 필수 | 에러 유형의 짧은 요약 (사람이 읽을 수 있는 텍스트) |
| `status` | ✅ 필수 | HTTP 상태 코드 (숫자) |
| `detail` | ✅ 필수 | 이 요청에 대한 구체적인 에러 설명 (사용자가 이해할 수 있는 언어) |
| `instance` | ⚠️ 권장 | 문제가 발생한 요청 경로 |
| `errors` | ⚠️ 권장 | 확장 필드 — 필드 수준 유효성 검사 상세 목록 |
| `traceId` | ⚠️ 권장 | 확장 필드 — `Request-Id` 응답 헤더 값과 일치해야 한다 |

> **참조**: [RFC 7807](https://datatracker.ietf.org/doc/html/rfc7807), [RFC 9457](https://datatracker.ietf.org/doc/html/rfc9457)

⚠️ **권장**: 유효성 검사 실패 시 모든 오류 필드를 한 번에 반환한다 (하나씩 반환하지 않는다).

```json
{
  "type": "https://api.example.com/errors/validation-failed",
  "title": "유효성 검사 실패",
  "status": 400,
  "detail": "요청 데이터 유효성 검사에 실패했습니다.",
  "instance": "/articles",
  "errors": [
    { "field": "title", "message": "제목은 필수 입력값입니다." },
    { "field": "content", "message": "본문은 10자 이상이어야 합니다." }
  ],
  "traceId": "abc-123-xyz"
}
```

❌ **금지**: 에러 응답에 스택 트레이스, 내부 시스템 경로, DB 오류 메시지 등 내부 구현 정보를 노출하지 않는다.

---

## 3. REST Design

### 3.1 리소스 스키마 & 필드 규칙

리소스는 서비스가 노출하는 핵심 엔티티다. 각 리소스는 고유한 URL을 통해 접근 가능해야 한다.

✅ **필수**: 모든 리소스는 고유 식별자(`id`)를 가진다.

✅ **필수**: 리소스 스키마는 일관된 구조를 유지한다.

**표준 리소스 필드**

| 필드 | 타입 | 설명 |
|------|------|------|
| `id` | string | 리소스 고유 식별자 |
| `createdAt` | string (RFC 3339) | 생성 시각 |
| `updatedAt` | string (RFC 3339) | 마지막 수정 시각 |

예시:

```json
{
  "id": "123",
  "title": "RESTful API 설계",
  "content": "...",
  "createdAt": "2024-01-15T09:00:00Z",
  "updatedAt": "2024-01-20T14:30:00Z"
}
```

⚠️ **권장**: 리소스 식별자는 불투명한(opaque) 문자열로 설계한다. 클라이언트가 식별자 구조를 파싱하거나 의존하지 않도록 한다.

❌ **금지**: 응답에 null 값 필드를 포함하지 않는다. 값이 없는 필드는 응답에서 제외한다.

```json
// Bad
{
  "id": "123",
  "title": "제목",
  "deletedAt": null
}

// Good
{
  "id": "123",
  "title": "제목"
}
```

#### 필드 변경 가능성

필드는 생성 후 변경 가능 여부에 따라 분류된다.

| 분류 | 설명 | 예시 |
|------|------|------|
| **생성 시 지정 (Create-only)** | 생성 시에만 설정 가능, 이후 변경 불가 | `id`, `createdAt` |
| **읽기 전용 (Read-only)** | 서버가 관리, 클라이언트 수정 불가 | `updatedAt` |
| **변경 가능 (Mutable)** | 클라이언트가 수정 가능 | `title`, `content` |

✅ **필수**: 서버가 관리하는 읽기 전용 필드(`id`, `createdAt`, `updatedAt`)를 클라이언트가 요청 본문에 포함하더라도 이를 무시한다.

⚠️ **권장**: API 문서에서 각 필드의 변경 가능성을 명시한다.

#### 상태 Enum 패턴 (AIP-216)

리소스의 수명주기 상태를 표현할 때는 전용 `state` 필드를 사용한다 (`status` 아님).

✅ **필수**: 상태 필드 이름은 `state`로 한다 (`status`는 HTTP 상태 코드와 혼동됨).

✅ **필수**: 첫 번째 Enum 값은 반드시 `STATE_UNSPECIFIED`여야 한다 (알 수 없는/기본 상태).

✅ **필수**: `state` 필드는 `OUTPUT_ONLY` — 클라이언트가 PATCH로 직접 변경 금지.

✅ **필수**: 상태 전이는 커스텀 메서드(예: `:activate`, `:deactivate`)로만 수행한다. `state` 필드를 직접 PATCH하는 것은 금지.

⚠️ **권장**: 일반 패턴: `ACTIVE` / `INACTIVE`, `PENDING` / `RUNNING` / `SUCCEEDED` / `FAILED`.

```json
{
  "id": "job-123",
  "state": "RUNNING"
}
```

```
# 올바른 방법: 커스텀 메서드로 상태 전이
POST /jobs/123:cancel

# 금지: state 필드 직접 PATCH
PATCH /jobs/123?updateMask=state
{ "state": "CANCELLED" }   ← 금지
```

---

### 3.2 CRUD 처리

#### POST — 리소스 생성

✅ **필수**: 새 리소스 생성 성공 시 201 Created와 생성된 리소스를 반환한다.

```
POST /articles
Content-Type: application/json

{
  "title": "새 글 제목",
  "content": "본문 내용"
}

---

HTTP/1.1 201 Created
Location: /articles/456
Content-Type: application/json

{
  "id": "456",
  "title": "새 글 제목",
  "content": "본문 내용",
  "createdAt": "2024-01-20T10:00:00Z",
  "updatedAt": "2024-01-20T10:00:00Z"
}
```

#### PUT — 리소스 완전 대체

✅ **필수**: PUT 요청은 리소스 전체를 대체한다. 요청 본문에 포함되지 않은 변경 가능 필드는 기본값 또는 null로 처리한다.

✅ **필수**: PUT 요청은 멱등적으로 동작해야 한다.

#### PATCH — 부분 수정 (AIP-161)

✅ **필수**: 모든 PATCH 요청은 수정할 필드를 지정하는 `updateMask` 쿼리 파라미터를 포함해야 한다.

```
PATCH /articles/456?updateMask=title,content
Content-Type: application/json

{
  "title": "수정된 제목",
  "content": "새 본문"
}
```

✅ **필수**: `updateMask`에 명시된 필드만 수정한다. mask에 없는 필드는 변경하지 않는다.

✅ **필수**: 200 OK와 수정된 전체 리소스를 반환한다.

⚠️ **권장**: `updateMask=*`는 요청 본문에 포함된 모든 mutable 필드를 업데이트한다.

✅ **필수**: 빈 `updateMask` → 400 Bad Request. 잘못된 필드 경로 → 400 Bad Request.

⚠️ **권장**: 중첩 필드 경로에는 dot notation을 사용한다: `?updateMask=address.city`.

**Field Behavior와 `updateMask` 상호작용:**

| 필드 어노테이션 | mask에 포함 시 동작 |
|---|---|
| `OUTPUT_ONLY` | 무시 (에러 아님) |
| `IMMUTABLE` | 값 변경 시 `400 Bad Request` |
| `REQUIRED` | 요청 본문에 반드시 포함 |
| `OPTIONAL` | 본문 생략 가능 (기존 값 유지) |

#### DELETE — 리소스 삭제

✅ **필수**: 삭제 성공 시 204 No Content를 반환한다.

⚠️ **권장**: 이미 삭제된 리소스에 대한 재삭제 요청은 404 Not Found 또는 204 No Content를 반환한다. 서비스 특성에 따라 결정한다.

⚠️ **권장**: 하위 리소스의 연쇄 삭제를 위해 `force` 쿼리 파라미터를 지원한다.

```
DELETE /projects/123?force=true
```

#### Soft Delete (AIP-164)

즉시 영구 삭제 대신 복구 가능한 삭제가 필요한 리소스에 적용한다.

✅ **필수**: `deleteTime` (삭제 시각)과 `expireTime` (영구 삭제 예정 시각) 필드를 추가한다 (둘 다 `OUTPUT_ONLY`).

✅ **필수**: 복구 엔드포인트: `POST /{resource}/{id}:undelete`.

✅ **필수**: List 응답은 기본적으로 soft-deleted 리소스를 제외한다. `?showDeleted=true`로 포함.

⚠️ **권장**: Get은 soft-deleted 리소스를 정상 반환한다 (`deleteTime` 포함).

⚠️ **권장**: 보존 기간(기본 30일) 이후 자동 영구 삭제.

```
# Soft delete
DELETE /articles/123

# 복구
POST /articles/123:undelete

# 삭제된 항목 포함 목록 조회
GET /articles?showDeleted=true
```

#### Change Validation / Dry Run (AIP-163)

실제 변경 없이 Create 또는 Update 요청을 사전 검증한다.

⚠️ **권장**: `?validateOnly=true` 쿼리 파라미터를 지원한다.

✅ **필수**: `validateOnly=true`이면 검증만 수행 — 리소스 변경 없음, 부수 효과 없음.

✅ **필수**: 검증 성공 시 실제 실행과 유사한 응답 반환 (서버 생성 필드 제외 가능).

✅ **필수**: 검증 실패 시 동일한 RFC 9457 에러 형식 반환.

```
# 생성 없이 검증만 수행
POST /articles?validateOnly=true
Content-Type: application/json

{ "title": "새 글" }

---

HTTP/1.1 200 OK
{ "id": null, "title": "새 글" }   # id 미포함 (아직 생성 안 됨)
```

---

### 3.3 액션 (AIP-136)

CRUD로 표현하기 어려운 동작(예: 승인, 전송, 잠금)에는 액션 패턴을 사용한다.

✅ **필수**: 액션은 리소스 URL 뒤에 `:action` 형태로 표현한다.

```
POST /articles/123:publish
POST /users/456:deactivate
POST /orders/789:cancel
```

✅ **필수**: 액션 엔드포인트에는 POST 메서드를 사용한다.

⚠️ **권장**: 액션 이름은 동사 원형을 사용한다 (publish, cancel, approve).

**액션 응답 상태 코드:**

| 시나리오 | 상태 코드 | 응답 본문 |
|----------|-----------|-----------|
| 동기 액션 — 리소스 변경 | `200 OK` | 변경된 리소스 |
| 동기 액션 — 응답 본문 없음 | `204 No Content` | 없음 |
| 비동기 액션 — fire-and-forget | `202 Accepted` | 없음 또는 최소 응답 |
| 비동기 액션 — 폴링 가능 작업 생성 | `201 Created` + `Location` 헤더 | 생성된 작업 리소스 |

**요청 예시:**

```
POST /articles/123:publish
Content-Type: application/json

{}

---

HTTP/1.1 200 OK
Content-Type: application/json

{
  "id": "123",
  "status": "PUBLISHED",
  "publishedAt": "2024-01-20T15:00:00Z"
}
```

---

### 3.4 컬렉션 & 페이지네이션

#### 컬렉션 응답 구조

✅ **필수**: 컬렉션 조회 응답 본문은 리소스 배열(top-level JSON array)을 반환한다.

```
HTTP/1.1 200 OK
Link: <https://api.example.com/articles?pageSize=20&pageToken=abc>; rel="next",
      <https://api.example.com/articles?pageSize=20>; rel="first",
      <https://api.example.com/articles?pageSize=20&pageToken=xyz>; rel="last"
Total-Count: 100

[
  { "id": "1", "title": "첫 번째 글" },
  { "id": "2", "title": "두 번째 글" }
]
```

| 헤더 | 필수 여부 | 설명 |
|------|-----------|------|
| `Link` | ⚠️ 권장 | 페이지네이션 네비게이션 (RFC 8288) |
| `Total-Count` | ⚠️ 권장 | 전체 항목 수 |

| rel 값 | 설명 |
|--------|------|
| `next` | 다음 페이지 |
| `prev` | 이전 페이지 |
| `first` | 첫 번째 페이지 |
| `last` | 마지막 페이지 |

#### 빈 컬렉션 응답

✅ **필수**: 컬렉션에 항목이 없을 때 `200 OK` + 빈 배열 `[]`을 반환한다. 빈 컬렉션에 `404 Not Found`를 사용하지 않는다.

⚠️ **권장**: 빈 컬렉션에도 `Total-Count: 0` 헤더를 포함한다.

```
HTTP/1.1 200 OK
Content-Type: application/json
Total-Count: 0

[]
```

> **참고**: 컬렉션 엔드포인트는 비어 있어도 리소스 자체는 존재한다 ([RFC 9110](https://datatracker.ietf.org/doc/html/rfc9110)). `404 Not Found`는 엔드포인트 자체가 존재하지 않는다는 의미이지, 컬렉션이 비어 있다는 의미가 아니다.

#### 커서 기반 페이지네이션 (권장)

⚠️ **권장**: 대용량 데이터에는 오프셋 기반 대신 커서 기반 페이지네이션을 사용한다.

**요청:**

```
GET /articles?pageSize=20&pageToken=eyJwYWdlIjoyf...
```

**응답:**

```
HTTP/1.1 200 OK
Link: <https://api.example.com/articles?pageSize=20&pageToken=abc>; rel="next",
      <https://api.example.com/articles?pageSize=20>; rel="first"

[
  { "id": "1", "title": "첫 번째 글" },
  ...
]
```

✅ **필수**: 다음 페이지가 없을 때 `Link` 헤더에서 `rel="next"`를 제외한다.

✅ **필수**: `pageToken`은 불투명한 값이다. 클라이언트는 `pageToken`을 파싱하거나, 직접 조합하거나, 내부 형식에 대해 가정해서는 안 된다.

✅ **필수**: 서버는 `pageToken`의 인코딩을 사전 고지 없이 변경할 수 있다.

> **참고**: 이는 리소스 식별자의 불투명성 원칙과 동일하다 — 클라이언트가 구조적으로 의존해서는 안 되는 불투명한 문자열.

#### 오프셋 기반 페이지네이션

소규모 데이터셋에서는 오프셋 기반 페이지네이션도 허용된다.

**요청:**

```
GET /articles?page=2&pageSize=20
```

**응답:**

```
HTTP/1.1 200 OK
Link: <https://api.example.com/articles?pageSize=20&page=1>; rel="first",
      <https://api.example.com/articles?pageSize=20&page=1>; rel="prev",
      <https://api.example.com/articles?pageSize=20&page=3>; rel="next",
      <https://api.example.com/articles?pageSize=20&page=5>; rel="last"
Total-Count: 100

[
  { "id": "21", "title": "스물한 번째 글" },
  ...
]
```

⚠️ **권장**: 기본 페이지 크기(`pageSize`)는 20으로 설정한다.

⚠️ **권장**: 최대 페이지 크기는 100으로 제한한다.

✅ **필수**: `pageSize`가 1 미만이면 `400 Bad Request`를 반환한다.

⚠️ **권장**: `pageSize`가 최대 허용값을 초과하면 에러 대신 최대값으로 자른다. 적용된 `pageSize`를 응답에 포함한다.

```
# 요청: pageSize=500 (최대값 100)
# 서버가 pageSize=100으로 적용

HTTP/1.1 200 OK
Link: <https://api.example.com/articles?pageSize=100&pageToken=abc>; rel="next"

[ ... 100개 항목 ... ]
```

#### 키셋 페이지네이션

⚠️ **권장**: 대규모 데이터셋에서 일관된 성능이 중요한 경우 키셋 페이지네이션을 사용한다.

키셋 페이지네이션은 마지막 항목의 정렬 키를 커서로 사용하여, 페이지 깊이와 무관하게 O(1) 조회 성능을 달성한다.

**요청:**

```
GET /articles?pageSize=20&orderBy=createdAt:desc&after=eyJjcmVhdGVkQXQiOi...
```

**응답:**

```
HTTP/1.1 200 OK
Link: <https://api.example.com/articles?pageSize=20&orderBy=createdAt:desc&after=eyJjcmVhdGVkQXQiOi...>; rel="next"

[
  { "id": "455", "createdAt": "2024-01-20T09:55:00Z" },
  ...
  { "id": "440", "createdAt": "2024-01-15T08:00:00Z" }
]
```

✅ **필수**: 키셋 커서(`after`/`before`)는 불투명한 토큰이어야 한다 — 클라이언트가 직접 조합하면 안 된다.

⚠️ **권장**: 복합 정렬 키는 불투명한 커서에 인코딩한다.

> **트레이드오프**: 키셋 페이지네이션은 임의 페이지로 점프할 수 없다. 임의 페이지 접근이 필요하면 오프셋 페이지네이션을 사용한다.

---

### 3.5 필터링 & 정렬

#### 필터링

✅ **필수**: `filter` 쿼리 파라미터에 구조화된 표현식 문자열을 사용한다 (AIP-160).

**filter 표현식 문법:**

```
GET /articles?filter=status = "PUBLISHED" AND authorId = "user-123"
```

**연산자:**

| 유형 | 연산자 | 예시 |
|---|---|---|
| 비교 | `=`, `!=`, `<`, `>`, `<=`, `>=` | `?filter=price >= 100` |
| 논리 | `AND`, `OR`, `NOT` | `?filter=status = "ACTIVE" AND NOT archived = true` |
| 그룹핑 | `( )` | `?filter=(status = "ACTIVE" OR status = "PENDING") AND price < 1000` |

**값 타입:**

- 문자열 및 타임스탬프: 큰따옴표 — `?filter=createdAt > "2024-01-01T00:00:00Z"`
- 숫자: 따옴표 없이 — `?filter=price >= 100`
- 불리언: `true` / `false` — `?filter=isPublished = true`
- 중첩 필드: dot notation — `?filter=author.name = "Kim"`
- 반복 필드 포함 여부: `has()` — `?filter=has(tags, "golang")`

**예시:**

```
# 단일 조건
GET /articles?filter=status = "PUBLISHED"

# 복수 조건 (AND)
GET /articles?filter=status = "PUBLISHED" AND authorId = "user-123"

# OR 조건
GET /articles?filter=status = "PUBLISHED" OR status = "DRAFT"

# 그룹 복합 조건
GET /articles?filter=(status = "PUBLISHED" OR status = "DRAFT") AND createdAt > "2024-01-01T00:00:00Z"

# 부정
GET /articles?filter=NOT status = "DELETED"

# 날짜 범위
GET /articles?filter=createdAt >= "2024-01-01T00:00:00Z" AND createdAt < "2024-02-01T00:00:00Z"

# 숫자 범위
GET /products?filter=price >= 100 AND price <= 500

# 중첩 필드
GET /articles?filter=author.name = "Kim"

# 반복 필드 포함 여부
GET /articles?filter=has(tags, "golang")
```

❌ **금지**: 개별 쿼리 파라미터로 필터링하지 않는다 (예: `?status=PUBLISHED`, `?createdAfter=...`).

✅ **필수**: 유효하지 않은 filter 표현식 → 400 Bad Request (RFC 9457 에러 본문 포함).

#### 정렬

⚠️ **권장**: 정렬은 `orderBy` 파라미터를 사용하며, 필드명과 방향을 조합하여 표현한다.

```
GET /articles?orderBy=createdAt:desc
GET /articles?orderBy=title:asc
GET /articles?orderBy=createdAt:desc,title:asc
```

⚠️ **권장**: 기본 정렬 기준은 API 문서에 명시한다.

---

### 3.6 Partial Response

✅ **필수**: `fields` 쿼리 파라미터로 클라이언트가 응답에 포함할 필드를 선택할 수 있도록 지원한다 (AIP-157).

```
GET /articles/123?fields=id,title,author.name
```

✅ **필수**: `fields` 값과 무관하게 `id`는 항상 응답에 포함한다.

⚠️ **권장**: 중첩 필드는 dot notation으로 선택한다.

```
GET /articles/123?fields=id,author.name,author.email
```

✅ **필수**: List 응답에서도 각 항목에 `fields` 필터를 적용한다.

✅ **필수**: `INPUT_ONLY` 필드는 `fields` 파라미터와 무관하게 항상 응답에서 제외한다.

⚠️ **권장**: ETag는 전체 리소스를 기준으로 한다 (partial view와 무관).

✅ **필수**: `fields`에 존재하지 않는 필드명 → 400 Bad Request.

**예시:**

```
GET /articles?fields=id,title,author.name

---

HTTP/1.1 200 OK
Content-Type: application/json

[
  {
    "id": "123",
    "title": "REST API 설계",
    "author": {
      "name": "Kim"
    }
  }
]
```

---

### 3.7 Expand/Embed

✅ **필수**: 연관된 리소스를 응답에 포함하기 위해 `expand` 쿼리 파라미터를 지원한다.

```
GET /articles/123?expand=author,comments.author
```

✅ **필수**: N+1 쿼리 폭발 및 DoS 공격(Unrestricted Resource Consumption)을 방지하기 위해, 서버는 단일 응답에서 반환되는 **전체 확장 엔티티 수**에 대해 엄격한 상한선(예: 최대 100개)을 강제해야 한다.

✅ **필수**: 확장 요청이 최대 엔티티 제한을 초과하는 경우 `400 Bad Request`를 반환한다.

⚠️ **권장**: 최대 확장 깊이는 3단계로 제한한다.

---

### 3.8 Bulk Operations

일괄 작업은 네트워크 오버헤드를 줄이기 위해 단일 요청으로 여러 리소스를 처리할 수 있게 한다.

✅ **필수**: 리소스 컬렉션 URL 뒤에 콜론 기호를 사용한 커스텀 메서드로 일괄 작업을 표현한다.

| 메서드 | 목표 | 엔드포인트 |
|--------|------|------------|
| `batchCreate` | 여러 리소스 생성 | `POST /{resources}:batchCreate` |
| `batchGet` | ID로 여러 리소스 조회 | `POST /{resources}:batchGet` |
| `batchUpdate` | 여러 리소스 수정 | `POST /{resources}:batchUpdate` |
| `batchDelete` | 여러 리소스 삭제 | `POST /{resources}:batchDelete` |

✅ **필수**: 요청 본문에는 처리할 항목 또는 ID 배열이 포함되어야 한다.

✅ **필수**: 일괄 작업이 원자적(atomic, all-or-nothing)인지 또는 비원자적(부분 성공 허용)인지 명시해야 한다.

✅ **필수**: 비원자적 작업의 경우, 응답은 항목별 성공 또는 실패를 표현할 수 있는 구조를 사용해야 한다(실패한 항목에 대해 RFC 9457 에러 객체 포함).

---

## 4. API 운영

### 4.1 API 버전 관리

#### 버전 표기

❌ **금지**: API 버전을 URL 경로에 포함하지 않는다.

> **이유**: URL은 리소스 식별자다. `/v1/articles`와 `/v2/articles`는 같은 리소스인데 URL이 달라지므로 REST 원칙에 어긋난다. 또한 URL 버전은 클라이언트가 코드를 전면 교체해야 하는 부담을 준다. 헤더 버전은 클라이언트가 버전을 점진적으로 마이그레이션할 수 있고, 버전 미지정 시 서버가 기본 버전을 적용하는 유연성을 제공한다.

✅ **필수**: `Api-Version` 헤더에 ISO 8601 (`YYYY-MM-DD`) 형식의 날짜로 버전을 지정한다.

```
Api-Version: 2024-01-20
```

⚠️ **권장**: 버전 헤더가 없는 요청에는 최신 안정 버전을 적용하고, 응답에 적용된 버전을 명시한다.

```
HTTP/1.1 200 OK
Api-Version: 2024-01-20
```

#### 하위 호환성

✅ **필수**: 동일 버전 내에서 하위 호환성을 유지한다.

**하위 비호환 변경** (새 `Api-Version` 날짜 필요):

| 분류 | 예시 |
|------|------|
| 제거 | 엔드포인트, 필드, enum 값 제거 |
| 이름 변경 | 필드 또는 엔드포인트 이름 변경 |
| 타입 변경 | 필드 타입, 포맷 변경 (예: `string` → `int`) |
| 제약 강화 | `optional` → `required`, 새 필수 필드 추가, 검증 규칙 추가 |
| 의미 변경 | 상태 코드 의미 변경, 기본값 변경, 정렬 순서 변경 |

**하위 호환 변경** (버전 업 불필요):

| 분류 | 예시 |
|------|------|
| 추가 | 새 엔드포인트, 새 선택적 필드, 새 enum 값, 새 쿼리 파라미터 |
| 완화 | `required` → `optional`, 검증 규칙 완화 |
| 메타데이터 | 응답 속성 순서 변경, description 수정 |

#### 호환성 원칙

✅ **필수**: 클라이언트는 응답의 알 수 없는 필드를 무시해야 한다 (tolerant reader 패턴).

✅ **필수**: 서버는 요청의 알 수 없는 필드를 무시해야 한다.

✅ **필수**: Enum은 open-ended로 취급한다 — 클라이언트는 알 수 없는 enum 값을 정상 처리해야 한다.

⚠️ **권장**: 버전 업 전 최소 6개월 이전 버전을 유지한다.

---

### 4.2 Deprecation

✅ **필수**: Deprecated된 API에는 응답 헤더로 알림을 제공한다.

```
Deprecation: true
Sunset: Sat, 01 Jan 2025 00:00:00 GMT
Link: <https://api.example.com/users/articles>; rel="successor-version"
```

⚠️ **권장**: Deprecation 공지는 종료일 최소 6개월 전에 알린다.

⚠️ **권장**: Deprecated API 호출 시 `Deprecation`, `Sunset`, `Link` 헤더로 클라이언트에 공지한다.

```
HTTP/1.1 200 OK
Deprecation: true
Sunset: Sat, 01 Jan 2025 00:00:00 GMT
Link: <https://api.example.com/users/articles>; rel="successor-version"

[
  { "id": "1", "title": "항목 1" },
  ...
]
```

---

### 4.3 속도 제한

API 서버는 클라이언트별 요청 빈도를 제한하여 서비스 안정성을 보장한다.

#### 응답 헤더

✅ **필수**: 속도 제한이 적용되는 모든 응답에 다음 헤더를 포함한다.

**레거시 헤더 (X-RateLimit-\*)**

| 헤더 | 설명 | 예시 |
|------|------|------|
| `X-RateLimit-Limit` | 시간 창(window) 내 허용되는 최대 요청 수 | `100` |
| `X-RateLimit-Remaining` | 현재 시간 창에서 남은 요청 수 | `99` |
| `X-RateLimit-Reset` | 시간 창이 초기화되는 시각 (Unix timestamp, 초 단위) | `1742342450` |

**IETF 표준 헤더 ([draft-ietf-httpapi-ratelimit-headers-10](https://datatracker.ietf.org/doc/draft-ietf-httpapi-ratelimit-headers/), Internet-Draft, Standards Track)**

| 헤더 | 설명 | 예시 |
|------|------|------|
| `RateLimit` | 현재 속도 제한 상태 (Structured Field) | `limit=100, remaining=99, reset=50` |
| `RateLimit-Policy` | 적용 중인 속도 제한 정책 | `100;w=3600` |

> **참고**: `RateLimit` 헤더의 `reset` 값은 시간 창 초기화까지 남은 **초(delta-seconds)**이며, `X-RateLimit-Reset`은 **Unix timestamp**이다. 혼동에 주의한다.
>
> **`RateLimit-Policy` 구조**: `100;w=3600` — `100`은 허용 최대 요청 수, `w=3600`은 시간 창 크기(window, 초 단위). 모든 응답에 포함한다.

**정상 응답 예시:**

```
HTTP/1.1 200 OK
Content-Type: application/json
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 99
X-RateLimit-Reset: 1742342450
RateLimit: limit=100, remaining=99, reset=50
RateLimit-Policy: 100;w=3600

[
  { "id": "1", "title": "항목 1" }
]
```

#### 429 Too Many Requests 응답

✅ **필수**: 속도 제한 초과 시 `429 Too Many Requests`를 반환한다.

✅ **필수**: 429 응답에 `Retry-After` 헤더를 포함한다. 값은 재시도까지 대기해야 하는 초(delta-seconds)를 사용한다.

✅ **필수**: 429 응답 본문은 RFC 7807/9457 Problem Details 구조를 사용한다.

**429 응답 예시:**

```
HTTP/1.1 429 Too Many Requests
Content-Type: application/problem+json
Retry-After: 50
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1742342450
RateLimit: limit=100, remaining=0, reset=50
RateLimit-Policy: 100;w=3600
```

```json
{
  "type": "https://api.example.com/errors/too-many-requests",
  "title": "속도 제한 초과",
  "status": 429,
  "detail": "허용된 요청 한도를 초과했습니다. 50초 후에 다시 시도해 주세요."
}
```

#### 클라이언트 재시도 전략

✅ **필수**: 클라이언트는 429 응답 수신 시 `Retry-After` 헤더 값만큼 대기한 후 재시도한다.

⚠️ **권장**: `Retry-After` 헤더가 없거나 기타 일시적 오류(503 등) 발생 시, 지수 백오프(exponential backoff) + 지터(jitter) 전략을 사용한다. `attempt`는 1부터 시작하는 재시도 횟수(1 = 첫 번째 재시도).

```
wait_time = min(maxDelay, baseDelay × 2^(attempt - 1)) + random(0, jitterRange)
```

예시: attempt=1 → `min(60, 1 × 2^0) + random(0,1)` = 1~2초

| 파라미터 | 권장 값 | 설명 |
|----------|---------|------|
| `baseDelay` | 1초 | 첫 번째 재시도 대기 시간 |
| `maxDelay` | 60초 | 최대 대기 시간 상한 |
| `jitterRange` | 0 ~ 1초 | 무작위 지연 (thundering herd 방지) |
| 최대 재시도 횟수 | 3 ~ 5회 | 무한 재시도 방지 |

❌ **금지**: 429 응답 수신 시 즉시 재시도하거나 고정 간격으로 반복 재시도하지 않는다.

❌ **금지**: `Retry-After` 헤더가 있을 때 해당 값을 무시하고 자체 대기 시간을 사용하지 않는다.

---

### 4.4 장기 실행 작업

즉시 완료되지 않는 작업(보고서 생성, 데이터 가져오기 등)은 도메인 리소스를 즉시 생성하고 리소스의 상태 필드로 처리 진행 상황을 추적한다.

✅ **필수**: 장기 실행 작업 요청 시 도메인 리소스를 즉시 생성하고 `201 Created` + `Location` 헤더를 반환한다.

✅ **필수**: 도메인 리소스에 `status` 필드를 포함하여 처리 상태를 표현한다.

⚠️ **권장**: 상태값은 다음을 사용한다.

| 상태 | 설명 |
|------|------|
| `PENDING` | 작업 대기 중 |
| `IN_PROGRESS` | 작업 처리 중 |
| `COMPLETED` | 작업 완료 |
| `FAILED` | 작업 실패 |

⚠️ **권장**: `FAILED` 상태인 경우 리소스에 RFC 7807/9457 에러 구조를 포함한다.

**예시:**

```
# 작업 시작 — 도메인 리소스 즉시 생성
POST /reports  →  201 Created
                  Location: /reports/123
                  { "id": "123", "status": "PENDING" }

# 상태 조회 (폴링)
GET /reports/123  →  { "id": "123", "status": "IN_PROGRESS" }
GET /reports/123  →  { "id": "123", "status": "COMPLETED", ... }
GET /reports/123  →  { "id": "123", "status": "FAILED", "error": { ... } }
```

❌ **금지**: 별도의 범용 `/operations` 리소스를 사용하지 않는다. 도메인 리소스 자체에서 상태를 추적한다.

---

### 4.5 Idempotency-Key

POST는 멱등하지 않아 네트워크 오류 후 재시도하면 리소스가 중복 생성될 수 있다. 결제, 주문, 이메일 발송 등 중복 실행이 위험한 API에는 `Idempotency-Key` 헤더를 사용한다.

✅ **필수**: 중복 실행 위험이 있는 POST 엔드포인트는 `Idempotency-Key` 헤더를 지원한다.

```
POST /orders
Content-Type: application/json
Idempotency-Key: a8098c1a-f86e-11da-bd1a-00112444be1e

{
  "productId": "123",
  "quantity": 2
}
```

**서버 동작:**
- 처음 요청: 정상 처리 후 결과 저장
- 같은 키로 재요청: 새로 처리하지 않고 저장된 결과 그대로 반환
- 키가 다른 동일 요청: 별도 요청으로 처리

✅ **필수**: `Idempotency-Key` 값은 클라이언트가 생성한 UUID v4를 사용한다.

⚠️ **권장**: 동일 키로 재요청 시 원래 응답과 동일한 상태 코드 및 본문을 반환한다.

⚠️ **권장**: `Idempotency-Key`의 유효 기간은 최소 24시간으로 설정한다.

❌ **금지**: `Idempotency-Key` 없이 결제·주문 등 금전적 영향을 주는 POST 엔드포인트를 설계하지 않는다.

---

## 5. 인증 & 보안

### 5.1 인증 방식

#### Bearer Token (JWT)

✅ **필수**: 인증 토큰은 `Authorization` 헤더를 사용한다. 쿼리 파라미터나 요청 본문에 포함하지 않는다.

```
Authorization: Bearer eyJhbGciOiJSUzI1NiJ9...
```

#### API Key

⚠️ **권장**: API Key 인증은 `Authorization` 헤더를 사용한다.

```
Authorization: ApiKey your-api-key-here
```

❌ **금지**: API Key를 쿼리 파라미터로 전달하지 않는다. URL은 서버 로그에 기록될 수 있다.

```
# Bad
GET /articles?apiKey=secret-key
```

---

### 5.2 401 vs 403 구분

| 상태 코드 | 의미 | 사용 시점 |
|-----------|------|-----------|
| `401 Unauthorized` | 인증 실패 | 토큰 없음, 토큰 만료, 토큰 형식 오류 |
| `403 Forbidden` | 인가 실패 | 인증은 됐지만 해당 리소스/액션에 대한 권한 없음 |

✅ **필수**: 401 응답에는 `WWW-Authenticate` 헤더를 포함한다.

```
HTTP/1.1 401 Unauthorized
WWW-Authenticate: Bearer realm="api", error="token_expired"
Content-Type: application/problem+json

{
  "type": "https://api.example.com/errors/unauthorized",
  "title": "인증이 필요합니다",
  "status": 401,
  "detail": "액세스 토큰이 만료되었습니다."
}
```

⚠️ **권장**: 403 응답에서 리소스의 존재 여부를 노출하지 않는다. 보안상 민감한 리소스는 존재하지 않는 것처럼 404로 응답할 수 있다.

```
HTTP/1.1 403 Forbidden
Content-Type: application/problem+json

{
  "type": "https://api.example.com/errors/forbidden",
  "title": "접근이 거부되었습니다",
  "status": 403,
  "detail": "이 리소스에 접근할 권한이 없습니다."
}
```

---

### 5.3 Webhooks

✅ **필수**: 웹훅 이벤트에 대해 일관된 페이로드 래퍼를 사용한다.

```json
{
  "id": "evt_123",
  "type": "article.published",
  "created": "2024-01-20T10:00:00Z",
  "data": { ... }
}
```

✅ **필수**: 공유 비밀 키(Shared Secret)를 사용한 HMAC-SHA256으로 페이로드를 서명한다. 서명은 `X-Hub-Signature-256` 헤더에 포함한다.

⚠️ **권장**: 웹훅 핸들러는 중복 이벤트를 안전하게 처리할 수 있도록 멱등성을 가져야 한다.

---

## 6. Health Check

✅ **필수**: 서비스 가용성을 모니터링하기 위해 `GET /health` 엔드포인트를 제공한다.

✅ **필수**: 서비스가 정상이면 `200 OK`와 `{"status": "UP"}`을 반환한다.

⚠️ **권장**: 단순 생존 확인(liveness)과 준비 완료 확인(readiness)을 구분한다. 준비 완료 확인은 DB, 캐시 등 의존성 상태를 점검해야 한다.

---

## 7. OpenAPI Specification

### 7.1 API First

✅ **필수**: 모든 API는 OpenAPI 3.0+ 스펙을 단일 진실 원천(SSOT)으로 유지한다.

⚠️ **권장**: 구현 전 OpenAPI 스펙을 먼저 정의한다 (API First 접근법).

### 7.2 스펙 품질

✅ **필수**: 모든 엔드포인트, 파라미터, 스키마 속성에 `description` 필드를 포함한다.

✅ **필수**: 모든 operation에 고유한 `operationId`를 부여한다 — 코드 생성 및 문서 자동화의 기반이 된다.

⚠️ **권장**: 주요 스키마와 파라미터에 `example` 또는 `examples`를 포함하여 문서 가독성을 높인다.

```yaml
# Good
paths:
  /articles:
    get:
      operationId: listArticles
      description: 페이지네이션된 게시글 목록을 조회한다.
      parameters:
        - name: pageSize
          in: query
          description: 페이지당 항목 수.
          schema:
            type: integer
            example: 20
```

### 7.3 스키마 매핑

✅ **필수**: 필드 동작을 OpenAPI 속성으로 매핑한다:

| 필드 동작 | OpenAPI 속성 |
|-----------|-------------|
| 읽기 전용 (예: `id`, `createdAt`) | `readOnly: true` |
| 생성 전용 (예: 한 번만 쓰는 필드) | `writeOnly: true` |
| Nullable (명시적으로 필요한 경우만) | `nullable: true` (OpenAPI 3.0); `type: ["string", "null"]` (OpenAPI 3.1) |

⚠️ **권장**: 필드 생략 원칙을 따른다 — `nullable` 사용을 최소화하고, `null` 대신 필드를 생략한다.

✅ **필수**: RFC 9457 Problem Details를 공유 `$ref` 컴포넌트로 정의한다.

```yaml
components:
  schemas:
    ProblemDetail:
      type: object
      required: [type, title, status, detail]
      properties:
        type:
          type: string
          format: uri
          description: 에러 유형을 식별하는 URI.
          example: "https://api.example.com/errors/validation-failed"
        title:
          type: string
          description: 에러 유형의 짧은 요약.
        status:
          type: integer
          description: HTTP 상태 코드.
        detail:
          type: string
          description: 구체적인 에러 설명.
        instance:
          type: string
          description: 문제가 발생한 요청 경로.
        traceId:
          type: string
          description: Request-Id 응답 헤더 값과 일치.
```

### 7.4 확장 & 검증

⚠️ **권장**: 비공개 엔드포인트는 `x-internal: true` 확장으로 마킹한다.

⚠️ **권장**: CI에서 Spectral, Zally 등 린터를 사용하여 스펙 가이드라인 준수를 자동 검증한다.

---

## 8. 참고 자료

**Google API Improvement Proposals (AIP):**

- [AIP-121: Resource-oriented design](https://google.aip.dev/121)
- [AIP-136: Custom methods](https://google.aip.dev/136)
- [AIP-154: Resource freshness validation (ETags)](https://google.aip.dev/154)
- [AIP-157: Partial responses](https://google.aip.dev/157)
- [AIP-160: Filtering](https://google.aip.dev/160)
- [AIP-161: Field masks](https://google.aip.dev/161)
- [AIP-163: Change validation](https://google.aip.dev/163)
- [AIP-164: Soft delete](https://google.aip.dev/164)
- [AIP-203: Field behavior documentation](https://google.aip.dev/203)
- [AIP-216: States](https://google.aip.dev/216)

**RFCs & 표준:**

- [RFC 2119 - Key words for use in RFCs to Indicate Requirement Levels](https://datatracker.ietf.org/doc/html/rfc2119)
- [RFC 8174 - Ambiguity of Uppercase vs Lowercase in RFC 2119 Key Words](https://datatracker.ietf.org/doc/html/rfc8174)
- [RFC 3339 - Date and Time on the Internet](https://datatracker.ietf.org/doc/html/rfc3339)
- [RFC 9110: HTTP Semantics](https://datatracker.ietf.org/doc/html/rfc9110)
- [RFC 8288 - Web Linking](https://datatracker.ietf.org/doc/html/rfc8288)
- [RFC 6585 - Additional HTTP Status Codes (429)](https://datatracker.ietf.org/doc/html/rfc6585#section-4)
- [RFC 8594: The Sunset HTTP Header Field](https://datatracker.ietf.org/doc/html/rfc8594)
- [RFC 9745: The Deprecation HTTP Response Header Field](https://datatracker.ietf.org/doc/html/rfc9745)
- [draft-ietf-httpapi-ratelimit-headers-10: RateLimit Header Fields for HTTP](https://datatracker.ietf.org/doc/draft-ietf-httpapi-ratelimit-headers/)

**업계 가이드라인 & 기타:**

- [Microsoft Azure REST API Guidelines](https://github.com/microsoft/api-guidelines/blob/vNext/azure/Guidelines.md)
- [JSON:API Specification](https://jsonapi.org/)
- [Architectural Styles and the Design of Network-based Software Architectures - Roy Fielding](https://roy.gbiv.com/pubs/dissertation/fielding_dissertation.pdf)
- [Day1, 2-2. 그런 REST API로 괜찮은가](https://www.youtube.com/watch?v=RP_f5dMoHFc)
