# RESTful API 설계 가이드라인

> [English](README.md)

RESTful API 설계 가이드라인이다.

---

## 프로필 가이드 (Profile Guide)

각 규칙에는 `[T1]`, `[T2]`, `[T3]` 태그가 붙어 있다. 사용자가 프로필을 지정하면 해당 티어(Tier) 이하의 규칙만 적용한다.

| 프로필 | 포함 티어 | 대상 | 규칙 수 |
|--------|-----------|------|---------|
| **Essential** | T1 전용 | 모든 API — 첫날부터 적용 | ~87 |
| **Standard** | T1 + T2 | 프로덕션 운영 단계 | ~121 |
| **Full** | T1 + T2 + T3 | 대규모/엔터프라이즈 API | ~146 |

**티어 분류 기준 (ADR-0010):**
- **T1 (Essential):** 후행 도입 시 하위 호환성 파괴 위험 / 보안 필수 / HTTP 표준 / API 계약의 근간
- **T2 (Standard):** 프로덕션 운영 편의, 후행 도입 가능
- **T3 (Full):** 엔터프라이즈/고급 패턴, 특정 도메인 한정

---

## 목차

1. [개요](#1-개요)
   - [규범 수준 표기](#규범-수준-표기)
2. [URL 설계](#2-url-설계)
3. [HTTP 메서드 & 상태 코드](#3-http-메서드--상태-코드)
4. [HTTP 헤더](#4-http-헤더)
5. [JSON 데이터 포맷](#5-json-데이터-포맷)
6. [에러 응답](#6-에러-응답)
7. [리소스 스키마 & 필드 규칙](#7-리소스-스키마--필드-규칙)
8. [CRUD 처리](#8-crud-처리)
9. [액션](#9-액션)
10. [컬렉션 & 페이지네이션](#10-컬렉션--페이지네이션)
11. [필터링 & 정렬](#11-필터링--정렬)
12. [Partial Response & 리소스 확장](#12-partial-response--리소스-확장)
13. [일괄 작업 (Bulk Operations)](#13-일괄-작업-bulk-operations)
14. [API 버전 관리](#14-api-버전-관리)
15. [Deprecation](#15-deprecation)
16. [속도 제한 & 재시도](#16-속도-제한--재시도)
17. [캐싱](#17-캐싱)
18. [장기 실행 작업](#18-장기-실행-작업)
19. [Idempotency-Key](#19-idempotency-key)
20. [OpenAPI 스펙](#20-openapi-스펙)
21. [인증 & 보안](#21-인증--보안)
22. [참고 자료](#22-참고-자료)

---

## 1. 개요

### 목적

- 모든 RESTful API의 일관성, 예측 가능성, 유지보수성을 보장한다.
- API는 개발자가 소비하는 제품이다.
  - 직관적으로 이해 가능해야 한다.
  - 오류 발생 시 명확한 메시지를 제공해야 한다.
  - 버전이 바뀌어도 하위 호환성을 유지해야 한다.
- Roy Fielding의 RESTful 원칙을 따른다.
  - HATEOAS는 구현하지 않는다.

### 규범 수준 표기

이 문서에서 사용하는 "MUST", "MUST NOT", "SHOULD", "MAY", "DO NOT" 키워드는 [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119) 및 [RFC 8174](https://datatracker.ietf.org/doc/html/rfc8174)에 따라 해석한다.

| 기호 | 수준 | 설명 |
|------|------|------|
| ✅ **필수** | MUST / DO | 반드시 준수해야 하는 규칙 |
| ⚠️ **권장** | SHOULD / MAY | 가능하면 준수하는 것이 좋은 규칙 |
| ❌ **금지** | MUST NOT / DO NOT | 사용하지 말아야 하는 패턴 |

---

## 2. URL 설계

- **리소스 중심 설계** — API는 리소스(명사)를 중심으로 설계한다. URL 경로는 리소스 계층 구조를 표현하며, 행위는 HTTP 메서드와 커스텀 메서드로 표현한다.
- 모든 리소스는 최소한 GET(조회)을 지원해야 한다. `[T1]`
- **표준 메서드**(GET, POST, PATCH, DELETE)를 우선하며, 표준 메서드로 표현할 수 없는 경우에만 커스텀 메서드를 사용한다. `[T1]`
- 데이터베이스 구조를 API 스키마에 그대로 노출하지 않는다. `[T1]`

- **kebab-case** 사용: `/user-profiles`, `/product-categories/123`. `[T1]`
- 컬렉션 이름은 **복수형 명사** 사용: `/articles` (O), `/article` (X). `[T1]`
- **경로에 동사 포함 금지** — CRUD는 HTTP 메서드로, 그 외의 액션은 `POST`와 콜론(`:`) 구문을 사용한다 (리소스 수준: `/{resource}/{id}:{action}`, 컬렉션 수준: `/{resource}:{action}`). `[T1]`
- **파일 확장자 금지** (`.json`, `.xml`). `[T1]`
- **Trailing slash 금지** — `/articles/` 대신 `/articles`를 사용한다. `[T1]`
- **camelCase** 쿼리 파라미터 사용: `pageSize=20&sortOrder=desc`. `[T1]`
- 경로 세그먼트에는 ASCII 영소문자, 숫자, 하이픈만 사용한다. `[T1]`
- 배열 값은 파라미터 이름을 반복하여 전달한다: `?tag=tech&tag=design`. `[T1]`
- **서브리소스 중첩 제한** — 최대 1단계까지만 중첩한다: `/{parent}/{parentId}/{child}/{childId}`. `[T2]`

**중첩 깊이 규칙:** `[T2]`
부모 아래에 최대 하나의 서브리소스만 중첩한다. 더 깊은 관계는 최상위 경로로 승격시킨다.

| 상황 | ✅ Do | ❌ Don't |
|-----------|-------|---------|
| 주문 내 항목 | `/orders/{orderId}/items/{itemId}` | `/users/{userId}/orders/{orderId}/items/{itemId}` |
| 주문 항목의 리뷰 | `/order-items/{orderItemId}/reviews/{reviewId}` | `/users/{userId}/orders/{orderId}/items/{itemId}/reviews/{reviewId}` |

---

## 3. HTTP 메서드 & 상태 코드

| 메서드 | 용도 | 멱등성 | 안전성 |
|--------|---------|-----------|------|
| GET | 조회 | ✅ | ✅ |
| POST | 생성 / 커스텀 메서드 실행 | ❌ | ❌ |
| PUT | 전체 내용 대체 (파일/바이너리 업로드 등) | ✅ | ❌ |
| PATCH | 부분 수정 (기본 수정 메서드) | ❌ | ❌ |
| DELETE | 삭제 | ✅ | ❌ |
| HEAD | 메타데이터만 조회 (본문 없음) | ✅ | ✅ |
| OPTIONS | 허용된 메서드/CORS 정보 조회 | ✅ | ✅ |

- **HEAD:** 클라이언트는 전체 본문을 다운로드하지 않고 리소스 존재 여부나 수정 시각을 확인하기 위해 HEAD를 사용해야 한다. `[T2]`
- **OPTIONS:** 서버는 CORS 프리플라이트를 위해 OPTIONS를 지원해야 하며, `Allow` 헤더를 통해 지원 메서드를 명시해야 한다. `[T2]`
- GET, HEAD, DELETE 요청에는 요청 본문(body)을 포함하지 않는다. `[T1]`

**2xx 성공:**
- `200 OK` — 표준 성공. `[T1]`
- `201 Created` — 생성 성공; `Location` 헤더에 새 리소스 URL을 포함한다. `[T1]`
- `202 Accepted` — 요청 접수됨, 처리 미완료; 비동기 작업 등에 사용한다. `[T2]`
- `204 No Content` — 성공했으나 응답 본문 없음 (DELETE 등). `[T1]`

**4xx 클라이언트 오류:**
- `400 Bad Request` — 잘못된 요청, 유효성 검사 실패. `[T1]`
- `401 Unauthorized` — 인증 누락 또는 만료. `[T1]`
- `403 Forbidden` — 인증되었으나 권한 없음. `[T1]`
- `404 Not Found` — 리소스 존재하지 않음. `[T1]`
- `409 Conflict` — 리소스 중복 (ID 중복 또는 유니크 제약 위반). `[T1]`
- `412 Precondition Failed` — `If-Match` ETag 불일치 (조건부 요청 실패). `[T1]`
- `422 Unprocessable Entity` — 의미론적 유효성 검사 실패. `[T1]`
- `429 Too Many Requests` — 속도 제한 초과. `[T1]`

**5xx 서버 오류:**
- `500 Internal Server Error` — 서버 내부 오류. `[T1]`
- `503 Service Unavailable` — 일시적 서비스 중단. `[T1]`

---

## 4. HTTP 헤더

- 본문이 있는 경우 `Content-Type: application/json` 필수. `[T1]`
- 콘텐츠 협상을 위해 `Accept: application/json` 사용. `[T1]`
- 201 Created 응답 시 `Location` 헤더 필수. `[T1]`
- 컬렉션 크기 제공 시 `Total-Count` 헤더 사용. `[T2]`
- 페이지네이션 네비게이션을 위해 RFC 8288 `Link` 헤더 사용. `[T2]`
- **커스텀 헤더에 `X-` 접두사 금지** (RFC 6648) — 모든 신규 커스텀 헤더는 접두사 없이 정의한다. `[T1]`
- 캐싱 전략 명시를 위해 `Cache-Control` 헤더 사용. `[T2]`
- **Request-Id 헤더:** 서버는 모든 응답에 고유한 요청 식별자(UUID v4)를 포함해야 한다. `[T1]`
- **ETag:** 리소스 버전을 나타내는 불투명 문자열; 서버 응답에 포함한다. `[T1]`
- **If-Match:** 클라이언트는 낙관적 동시성 제어를 위해 수정/삭제 요청 시 ETag 값을 전송한다. `[T1]`

---

## 5. JSON 데이터 포맷

- **camelCase** 필드 이름 사용: `userId`, `createdAt`, `isActive`. `[T1]`
- snake_case나 약어를 사용하지 않는다. `[T1]`
- 값이 `null`이거나 없는 필드는 응답에서 완전히 제외한다. `[T1]`
- 날짜/시간은 RFC 3339 문자열로 표현하며, 서버 응답은 항상 UTC(`Z`)를 사용한다. `[T1]`
- 표준 리소스 필드: `id`, `createdAt` (생성 전용), `updatedAt` (읽기 전용). `[T1]`
- 서버는 요청 본문에 포함된 읽기 전용 필드를 무시해야 한다. `[T1]`

**상태 Enum 패턴 (AIP-216):** `[T1]`
- 상태 필드 이름은 반드시 `state`로 한다 (`status` 아님).
- 첫 번째 Enum 값은 항상 `STATE_UNSPECIFIED`여야 한다.
- `state`는 OUTPUT_ONLY이며, 커스텀 메서드를 통해서만 전이된다.

---

## 6. 에러 응답

✅ **필수**: 모든 에러 응답은 RFC 7807 / RFC 9457 표준을 따르며 `application/problem+json`을 사용한다.

```json
{
  "type": "https://api.example.com/errors/validation-failed",
  "title": "Validation Failed",
  "status": 400,
  "code": "VALIDATION_ERROR",
  "detail": "요청 데이터 유효성 검사에 실패했습니다.",
  "instance": "/users",
  "traceId": "abc-123-xyz",
  "details": [
    {
      "@type": "type.googleapis.com/google.rpc.BadRequest",
      "fieldViolations": [
        {
          "field": "user.email",
          "description": "올바른 이메일 주소 형식이 아닙니다."
        }
      ]
    }
  ]
}
```

- **기계 판독 가능한 코드:** `code` 문자열 필드(UPPER_SNAKE_CASE)를 포함한다. `[T1]`
- **필드 수준 에러 (AIP-193 방식):** 다형성 객체를 포함하는 `details` 배열을 사용한다. `[T1]`
- 모든 유효성 검사 실패 항목을 한 번에 반환한다. `[T1]`
- `traceId`는 `Request-Id` 응답 헤더 값과 일치해야 한다. `[T1]`
- 내부 구현 상세 정보(스택 트레이스 등)를 노출하지 않는다. `[T1]`

---

## 7. 리소스 스키마 & 필드 규칙

**필드 동작 어노테이션 (AIP-203):** `[T1]`
OpenAPI 스펙의 `x-field-behavior` 확장을 사용하여 필드 동작을 선언한다.

| 어노테이션 | 의미 |
|-----------|---------|
| `REQUIRED` | 클라이언트가 반드시 제공해야 함 |
| `OUTPUT_ONLY` | 서버가 설정; 클라이언트는 제공 불가 (무시됨) |
| `INPUT_ONLY` | 클라이언트가 제공; 응답에서는 제외됨 |
| `IMMUTABLE` | 생성 후 변경 불가 |
| `OPTIONAL` | 선택적으로 제공 가능 |
| `IDENTIFIER` | 리소스 식별자; 변경 불가 |

---

## 8. CRUD 처리

**표준 메서드 응답 규칙:**
- POST (Create): `201 Created` + 전체 리소스 + `Location` 헤더. `[T1]`
- PATCH (Update): 수정된 전체 리소스 반환. `[T1]`
- DELETE: `204 No Content` (본문 없음). `[T1]`

**PATCH (부분 수정 — 기본):** `[T1]`
- `updateMask` 쿼리 파라미터 필수: 쉼표로 구분된 필드 경로 — `?updateMask=title,content`.
- `updateMask`에 명시된 필드만 수정한다.
- 빈 mask 또는 잘못된 필드 경로 → `400 Bad Request`.

**낙관적 동시성 제어 (AIP-154):** `[T1]`
- 리소스에 `etag` 필드를 포함한다 (OUTPUT_ONLY).
- 수정/삭제 요청 시 `If-Match: {etag}` 헤더를 통해 전송한다.
- ETag 불일치 시 `412 Precondition Failed`를 반환한다.

---

## 9. 액션

**비 CRUD 액션 (AIP-136):** `[T1]`
단순 필드 업데이트 이상의 부수 효과가 있는 작업은 콜론 구문과 `POST`를 사용한다.

```
POST /orders/{id}:cancel
POST /reports:generate
```

---

## 10. 컬렉션 & 페이지네이션

- 컬렉션 응답은 **최상위 JSON 배열** `[]`을 반환한다. `[T1]`
- **빈 컬렉션:** `200 OK` + `[]`를 반환하며, 절대 `404 Not Found`를 사용하지 않는다. `[T1]`

**토큰 기반 페이지네이션 (AIP-158, 권장):** `[T2]`
- `pageSize`와 `pageToken`(불투명 토큰)을 사용한다.
- `Link` 헤더에 `rel="next"`, `prev`, `first` 등을 포함한다.

---

## 11. 필터링 & 정렬

❌ 개별 쿼리 파라미터로 필터링하지 않는다.

**필터 표현식 (AIP-160):** `[T1]`
- 문법: `?filter=status = "ACTIVE" AND price >= 1000`.
- 연산자: `=`, `!=`, `<`, `>`, `<=`, `>=`, `AND`, `OR`, `NOT`, `has()`.
- 유효하지 않은 filter 표현식 → `400 Bad Request`.

**정렬:** `?orderBy=createdAt:desc,title:asc`. `[T2]`

---

## 12. Partial Response & 리소스 확장

**Partial Response (AIP-157):** `[T2]`
- `fields` 쿼리 파라미터 사용: `?fields=id,title,author.name`.
- `id`는 항상 포함된다.

**리소스 확장 (Expand/Embed):** `[T2]`
- `expand` 쿼리 파라미터 사용: `?expand=author`.
- **전체 엔티티 제한 필수:** 단일 응답에서 확장되는 전체 엔티티 수에 대한 하한선(예: 최대 100개)을 강제해야 한다. `[T1]`
- 제한 초과 시 `400 Bad Request` 반환.

---

## 13. 일괄 작업 (Bulk Operations)

✅ **필수**: 컬렉션 URL 뒤에 콜론 구문을 사용하여 커스텀 메서드로 표현한다. `[T3]`
- `batchCreate`, `batchGet`, `batchUpdate`, `batchDelete`.
- 원자적(atomic) 또는 비원자적 작업 여부를 명시한다.

---

## 14. API 버전 관리

❌ **URL 경로에 버전을 포함하는 것은 금지된다.** `[T1]`

✅ **헤더 버전 관리 필수:** `[T1]`
```
Api-Version: 2024-01-20
```

- 버전 헤더가 없는 요청은 반드시 **`400 Bad Request`**를 반환해야 한다. `[T1]`
- 응답에는 항상 적용된 버전이 포함된다. `[T1]`
- 이전 버전은 최소 6개월 동안 유지한다. `[T2]`

---

## 15. Deprecation

- 응답 헤더 포함: `Deprecation: true`, `Sunset`, `Link`. `[T1]`
- 종료일 최소 6개월 전에 공지해야 한다. `[T1]`

---

## 16. 속도 제한 & 재시도

- **응답 헤더:** `RateLimit: limit=N, remaining=N, reset=N`. `[T2]`
- **429 Too Many Requests:** `Retry-After` 헤더와 RFC 9457 본문을 포함한다. `[T2]`
- **클라이언트 재시도 전략:** 지수 백오프(Exponential Backoff)와 지터(Jitter)를 사용한다. `[T2]`

---

## 17. 캐싱

- `Cache-Control` 헤더 사용. `[T2]`
- 모든 변경 가능한 리소스에 대해 `ETag`를 제공한다. `[T2]`

---

## 18. 장기 실행 작업

- 요청 시 도메인 리소스를 즉시 생성하고 `201 Created` + `Location` 헤더를 반환한다. `[T3]`
- `status` 필드 포함: `PENDING`, `IN_PROGRESS`, `COMPLETED`, `FAILED`. `[T3]`

---

## 19. Idempotency-Key

- 중복 실행 위험이 있는 POST 엔드포인트에 `Idempotency-Key` 헤더를 지원한다. `[T3]`
- UUID v4를 사용하며, 최소 24시간 동안 유효해야 한다. `[T3]`

---

## 20. OpenAPI 스펙

- 모든 API는 OpenAPI 3.0+ 스펙을 단일 진실 원천(SSOT)으로 유지한다. `[T2]`
- `description`과 `operationId`가 필수다. `[T2]`
- CI에서 린터를 사용하여 스펙 준수 여부를 자동으로 검증해야 한다. `[T1]`

---

## 21. 인증 & 보안

- **HTTPS 필수.** `[T1]`
- **보안 헤더 필수:** `X-Content-Type-Options: nosniff`, `Strict-Transport-Security`. `[T1]`
- Bearer 토큰 또는 API Key 인증에 `Authorization` 헤더 사용. `[T1]`

**BOLA (Broken Object Level Authorization) 방지:** `[T1]`
- 서버는 모든 개별 리소스 접근(`/{resource}/{id}`)에 대해 소유권 및 권한을 검증해야 한다.

**BOPA (Broken Object Property Authorization) 방지:** `[T1]`
- 서버는 DTO 계층에서 허용 목록(Allowlist)을 사용해야 한다. `PATCH` 본문이나 `updateMask`를 통해 보호된 필드가 수정되지 않도록 방어한다.

---

## 22. 참고 자료

- [Google API Improvement Proposals (AIP)](https://google.aip.dev)
- [RFC 9457: Problem Details for HTTP APIs](https://datatracker.ietf.org/doc/html/rfc9457)
- [OWASP API Security Top 10](https://owasp.org/www-project-api-security/)
