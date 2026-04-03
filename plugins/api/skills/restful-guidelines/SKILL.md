---
description: "Use when designing, implementing, or reviewing REST APIs — URL structure, HTTP methods, status codes, JSON format, error responses, and headers. Source: github.com/ppzxc/restful-api-guidelines"
user-invocable: true
---

# RESTful API Guidelines

Source: https://github.com/ppzxc/restful-api-guidelines

Keywords MUST, SHOULD, MAY follow RFC 2119/8174.

---

## URL Design

**Resource-oriented design** — API는 리소스(명사) 중심으로 설계한다. URL 경로는 리소스의 계층 구조를 표현하며, 행위는 HTTP 메서드와 커스텀 메서드로 표현한다.
- 모든 리소스는 최소한 GET(조회)을 지원해야 한다
- **표준 메서드**(GET, POST, PATCH, DELETE)를 우선 사용하고, 표현 불가능한 경우에만 커스텀 메서드를 사용한다
- API 스키마를 데이터베이스 구조와 동일하게 설계하지 않는다

- **kebab-case** for path segments: `/user-profiles`, `/product-categories/123`
- **Plural nouns** for collections: `/articles` not `/article`
- **No verbs in resource paths** — use HTTP methods for CRUD; non-CRUD actions use `POST` with colon syntax (resource-level: `/{resource}/{id}:{action}`, collection-level: `/{resource}:{action}`)
- **No file extensions** (`.json`, `.xml`)
- **No trailing slash** — `/articles` not `/articles/`
- **camelCase** for query parameters: `pageSize=20&sortOrder=desc`
- ASCII lowercase letters, numerals, and hyphens only in path segments
- Repeat parameter names for arrays: `?tag=tech&tag=design`
- **Single sub-resource nesting** — `/{parent}/{parentId}/{child}/{childId}` e.g., `/users/42/profiles/7`

**Nesting depth rule:**

Nest at most one sub-resource under a parent. For deeper relationships, promote to a flat top-level route.

| Situation | ✅ Do | ❌ Don't |
|-----------|-------|---------|
| Order items under an order | `/orders/{orderId}/items/{itemId}` | `/users/{userId}/orders/{orderId}/items/{itemId}` |
| Reviews on an order item | `/order-items/{orderItemId}/reviews/{reviewId}` | `/users/{userId}/orders/{orderId}/items/{itemId}/reviews/{reviewId}` |
| Delivery zones under address | `/addresses/{addressId}/delivery-zones/{zoneId}` | `/users/{userId}/addresses/{addressId}/delivery-zones/{zoneId}` |

## HTTP Methods & Status Codes

| Method | Purpose | Idempotent | Safe |
|--------|---------|-----------|------|
| GET | Retrieve | Yes | Yes |
| POST | Create / execute custom method | No | No |
| PUT | Full content replacement (file/binary upload) | Yes | No |
| PATCH | Partial update (default update method) | No | No |
| DELETE | Remove | Yes | No |

GET, HEAD, DELETE must not include request bodies.

**2xx Success:**
- `200 OK` — standard success
- `201 Created` — creation success; include `Location` header with new resource URL
- `202 Accepted` — request accepted, processing not complete; used for async or deferred operations
- `204 No Content` — success with no body (DELETE, etc.)

**4xx Client Error:**
- `400 Bad Request` — malformed request, validation failure
- `401 Unauthorized` — missing/expired authentication
- `403 Forbidden` — authenticated but not authorized
- `404 Not Found` — resource doesn't exist
- `409 Conflict` — duplicate resource (same ID or unique constraint violation)
- `412 Precondition Failed` — `If-Match` etag mismatch (conditional request failed)
- `422 Unprocessable Entity` — semantic validation failure
- `429 Too Many Requests` — rate limit exceeded

**5xx Server Error:**
- `500 Internal Server Error` — unexpected failure
- `503 Service Unavailable` — temporary unavailability

## Headers

- `Content-Type: application/json` for bodies
- `Accept: application/json` for content negotiation
- `Location` header on 201 Created
- `Total-Count` for collection size
- RFC 8288 `Link` header for pagination
- **No `X-` prefix on custom headers** (RFC 6648/BCP 178) — `X-` was intended for experimental headers but causes naming conflicts when they become standards. All new APIs MUST define custom headers without this prefix. Exception: legacy headers already standardized with `X-` (e.g., `X-Forwarded-For`) retain their names for compatibility
- `Cache-Control` header specifies caching strategy
- `Request-Id` header — server MUST include a unique request identifier (UUID v4) in every response; if the client sends `Request-Id`, the server SHOULD adopt it or generate a new one
- Propagate `Request-Id` across microservices for distributed tracing
- Log `Request-Id` in all service logs for debugging correlation
- `ETag` — 리소스 버전을 나타내는 불투명 문자열; 서버가 응답에 포함
- `If-Match` — 클라이언트가 Update/Delete 시 etag 값을 전달; 낙관적 동시성 제어에 사용

## JSON Format

- **camelCase** field names: `userId`, `createdAt`, `isActive`
- Never snake_case or abbreviations
- Omit null/missing fields entirely (do not send `"field": null`)
- Date/time values as RFC 3339 strings; server responses in UTC (`Z`)
- Standard resource fields: `id`, `createdAt` (create-only), `updatedAt` (read-only)
- Servers must ignore read-only fields in request bodies

**State Enum 패턴 (AIP-216):** 리소스 상태 표현 시:
- 상태 필드명은 `state` (not `status` — HTTP 상태 코드와 혼동 방지)
- 첫 번째 Enum 값은 항상 `STATE_UNSPECIFIED` (초기/알 수 없는 상태)
- `state`는 OUTPUT_ONLY — PATCH로 직접 변경 금지, 상태 전이는 커스텀 메서드로만
- 일반 패턴 예시: `ACTIVE/INACTIVE`, `PENDING/RUNNING/SUCCEEDED/FAILED`

## Error Response (RFC 7807/9457 Problem Details)

```json
{
  "type": "https://api.example.com/errors/resource-not-found",
  "title": "Resource Not Found",
  "status": 404,
  "detail": "User-friendly explanation",
  "instance": "/articles/999",
  "traceId": "abc-123-xyz"
}
```

- `Content-Type: application/problem+json`
- Include **all** validation failures at once, not incrementally
- Never expose stack traces, internal paths, or DB errors
- `traceId` value MUST match the `Request-Id` response header for consistent debugging

## Resource Schema & Field Rules

- Standard resource fields: `id`, `createdAt` (create-only), `updatedAt` (read-only)
- Resource identifiers are opaque strings — clients must not parse structure
- Omit null/missing fields entirely (do not send `"field": null`)
- Servers must ignore read-only fields in request bodies

**Field Behavior Annotations** (AIP-203) — 필드 동작을 OpenAPI 스키마에서 `x-field-behavior` 확장 필드로 명시한다.

| Annotation | 의미 | Create 시 서버 동작 | Update 시 서버 동작 |
|-----------|------|-------------------|-------------------|
| `REQUIRED` | 클라이언트가 반드시 제공 | 누락 시 `400 Bad Request` | 누락 시 `400 Bad Request` |
| `OUTPUT_ONLY` | 서버가 설정, 클라이언트 제공 불가 | 요청 값 무시 | 요청 값 무시 |
| `INPUT_ONLY` | 클라이언트가 제공, 응답에 미포함 | 처리 후 응답에서 제외 | 처리 후 응답에서 제외 |
| `IMMUTABLE` | 생성 후 변경 불가 | 클라이언트 제공 허용 | 변경 시도 시 `400 Bad Request` |
| `OPTIONAL` | 선택적으로 제공 | 기본값 적용 | 미포함 시 기존 값 유지 |
| `IDENTIFIER` | 리소스 식별자, 변경 불가 | 클라이언트 제공 허용 (선택) | 변경 시도 시 `400 Bad Request` |

OpenAPI 매핑: `OUTPUT_ONLY` → `readOnly: true`, `INPUT_ONLY` → `writeOnly: true`, 기타 annotation → `x-field-behavior` 확장.

## CRUD Behavior

**Standard method response rules:**
- POST (Create): return `201` with full resource + `Location` header
- PATCH (Update): return the updated resource
- DELETE: return `204` with no body

**POST (Create):** Return `201` with full resource + `Location` header.
- Clients SHOULD be able to specify resource ID (optional).
- Duplicate creation MUST return `409 Conflict`.

**PATCH (Update — default):** Only modify fields present in body; others unchanged.
- Response MUST return the updated full resource.
- Optionally support `updateMask` query parameter to explicitly specify fields to update.

**낙관적 동시성 제어 (AIP-154):** 리소스는 `etag` 필드를 포함한다 (opaque string, 변경마다 갱신).

- Update/Delete 요청 시 `If-Match: {etag}` 헤더로 etag 전달
- etag 불일치 시 `412 Precondition Failed` 반환 (현재 리소스를 응답 본문에 포함)
- `If-Match` 헤더 미전달 시 무조건 실행 (opt-in 방식)

**PUT (Content Replace — exceptional use only):** Use only when full content replacement is semantically required (file upload, binary content, configuration replacement). MUST NOT be used for resource attribute updates — use PATCH instead.

**DELETE:** Return `204`; re-deletion policy is per-service (404 or 204).
- Optionally support `force` query parameter for cascading child resource deletion (`DELETE /resources/{id}?force=true`).

**Soft Delete (AIP-164):** 즉시 영구 삭제 대신 삭제 표시 후 복구 가능한 패턴이 필요한 경우:
- 리소스에 `deleteTime` (삭제 시각), `expireTime` (영구 삭제 예정 시각) 필드 추가 (OUTPUT_ONLY)
- 복구: `POST /{resource}/{id}:undelete` 커스텀 메서드
- List: 기본적으로 soft-deleted 리소스 제외, `?showDeleted=true`로 포함
- Get: soft-deleted 리소스 정상 반환 (`deleteTime` 포함)
- 보존 기간 경과(기본 30일) 후 자동 영구 삭제

**Change Validation / Dry Run (AIP-163):** Create/Update 요청의 사전 검증:
- `?validateOnly=true` 쿼리 파라미터
- `true`이면 검증만 수행 — 리소스 변경 없음, 부수 효과 없음
- 검증 성공 시 실제 실행과 유사한 응답 반환 (서버 생성 필드 제외 가능)
- 검증 실패 시 동일한 RFC 9457 에러 형식

## Actions

**Non-CRUD actions:**

Some operations carry side-effects that go beyond simple field updates (e.g., refunds,
notifications, state-machine transitions). Disguising them as PATCH masks intent and
couples unrelated concerns. Use `POST` with colon syntax to make the operation explicit
and clearly separate it from the resource path.
This applies equally to collection-level operations where no specific resource identifier exists (`POST /{resource}:{action}`).

| Action | ✅ Do | ❌ Don't | Why |
|--------|-------|---------|-----|
| Cancel an order | `POST /orders/{id}:cancel` | `PATCH /orders/{id}` with `{"status":"cancelled"}` | Cancellation triggers refund + notification — not a simple field update |
| Approve a review | `POST /reviews/{id}:approve` | `PUT /reviews/{id}/approval` | Approval may trigger publishing, scoring, or downstream workflows |
| Generate a report | `POST /reports:generate` | `GET /reports?generate=true` | Generation is a compute side-effect that may mutate state — not a safe retrieval |

Adopted pattern: Google AIP-136 (`/orders/{id}:cancel`), Google Cloud API (`/projects/{project}:setIamPolicy`).

> **콜론 구문 호환성 주의**: Express.js, Rails 등 `:`를 path parameter 구문으로 사용하는 프레임워크에서는 라우팅 설정 시 정규식 라우트 등 추가 처리가 필요하다. OpenAPI 명세에서 콜론 경로 지원 여부를 확인할 것.

**Action response status codes:**

| Scenario | Status Code | Response Body |
|----------|-------------|---------------|
| Sync action — resource updated | `200 OK` | Updated resource |
| Sync action — no response body | `204 No Content` | None |
| Async action — fire-and-forget | `202 Accepted` | None or minimal acknowledgement |

For async actions that create a pollable job resource, use `201 Created` + `Location` header instead (see [Long-Running Operations](#long-running-operations)).

## Collections & Pagination

- Collections return **top-level JSON array** `[]` — never wrapped in an envelope object
- **Empty collections**: return `200 OK` + `[]` — never `404`; include `Total-Count: 0`
- Use `Link` header (RFC 8288) with `rel="next"`, `prev`, `first`, `last` for navigation
- `Total-Count` header for total item count
- **Cursor-based** (recommended): `pageSize` + `pageToken` — `pageToken` is an opaque value, clients MUST NOT parse or construct it
- **Offset-based**: `page` + `pageSize` — acceptable for small datasets
- **Keyset**: `after`/`before` opaque cursor + `orderBy` — O(1) regardless of page depth; cannot jump to arbitrary pages
- Default `pageSize`: 20, max: 100
- `pageSize < 1` → `400 Bad Request`; `pageSize > max` → cap to max (no error)
- Exclude `rel="next"` when there is no next page

## Filtering & Sorting

- Equality: `?status=PUBLISHED&authorId=123`
- Date range: `After`/`Before` suffix — `?createdAfter=2024-01-01T00:00:00Z`
- Numeric range: `Min`/`Max` suffix — `?priceMin=100&priceMax=500`
- Multi-value (IN): repeat param = OR — `?status=a&status=b`
- Cross-param = AND: `?status=PUBLISHED&authorId=123`
- Contains: `?q=keyword` (full-text) or `?titleContains=keyword` (field)
- Sort: `?orderBy=createdAt:desc` / multi: `?orderBy=createdAt:desc,title:asc`

## API Versioning

**URL path versioning is PROHIBITED** — `/v1/articles` violates REST principles (same resource must have one URL)

**Header versioning is REQUIRED:**
```
Api-Version: 2024-01-20   (ISO 8601 date format)
```

> Header name uses no `X-` prefix per RFC 6648/BCP 178.

- Requests without version header receive the latest stable version
- Responses always include the applied version
- Maintain previous versions for minimum 6 months before deprecation

**Breaking changes** (require new `Api-Version` date):

| Category | Examples |
|----------|----------|
| Removal | endpoint, field, enum value removal |
| Rename | field or endpoint name change |
| Type change | field type or format change (e.g., string → int) |
| Constraint tightening | optional → required, new required field, stricter validation |
| Semantic change | status code meaning change, default value change, sort order change |

**Compatible changes** (no version bump):

| Category | Examples |
|----------|----------|
| Addition | new endpoint, new optional field, new enum value, new query parameter |
| Relaxation | required → optional, loosened validation |
| Metadata | response property order change, description update |

**Compatibility principles:**
- Clients MUST ignore unknown fields in responses (tolerant reader)
- Servers MUST ignore unknown fields in requests
- Enums are open-ended — clients MUST handle unknown values gracefully

## Deprecation

Deprecated APIs MUST include these response headers (RFC 9745, RFC 8594):

```
Deprecation: true
Sunset: Sat, 01 Jan 2025 00:00:00 GMT
Link: <https://api.example.com/new-resource>; rel="successor-version"
```

- Deprecation notice must be given at least 6 months before the sunset date

## Rate Limiting

- Response headers (always): `RateLimit: limit=N, remaining=N, reset=N` + `RateLimit-Policy: N;w=N`
- 429 Too Many Requests: include `Retry-After` (delta-seconds) + RFC 9457 Problem Details body
- Client retry: honor `Retry-After`; otherwise exponential backoff + jitter

## Long-Running Operations

- Return `201 Created` + `Location` header with domain resource immediately
- Include `status` field: `PENDING` → `IN_PROGRESS` → `COMPLETED` | `FAILED`
- Client polls `GET {Location}` to check progress
- On failure: include error details in response body

## Idempotency-Key

- Support `Idempotency-Key` header for POST endpoints where duplicate execution is risky (payments, orders)
- Client-generated UUID v4
- First request: process normally and store result
- Re-request with same key: return stored result without reprocessing
- Key validity: minimum 24 hours
- POST endpoints with financial impact MUST support `Idempotency-Key`

## OpenAPI Specification

All APIs MUST maintain an OpenAPI 3.0+ spec as the single source of truth (API First).

| Rule | Description |
|------|-------------|
| `description` required | Every endpoint, parameter, and schema property MUST have a `description` |
| `operationId` required | Every operation MUST have a unique `operationId` for code generation and documentation |
| `example` recommended | Key schemas and parameters SHOULD include `example` or `examples` |
| `readOnly`/`writeOnly` | Map create-only fields to `writeOnly`, read-only fields to `readOnly` |
| Minimize `nullable` | Follow field-omission principle; use `nullable` only when explicitly needed |
| Shared error schema | Define RFC 9457 Problem Details as a `$ref` shared component |
| Internal-only marking | Mark non-public endpoints with `x-internal: true` extension |
| Automated validation | SHOULD validate spec compliance in CI using linters (e.g., Spectral, Zally) |

## Authentication & Security

- `Authorization: Bearer {token}` for JWT authentication
- `Authorization: ApiKey {key}` for API Key authentication
- Never pass credentials in query parameters (logged by servers)
- `401 Unauthorized`: missing/expired authentication — include `WWW-Authenticate` header
- `403 Forbidden`: authenticated but not authorized
- Avoid storing sensitive data in query strings (they get logged)
