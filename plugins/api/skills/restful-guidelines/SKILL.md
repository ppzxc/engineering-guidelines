---
description: "Use when designing, implementing, or reviewing REST APIs — URL structure, HTTP methods, status codes, JSON format, error responses, and headers. Source: github.com/ppzxc/restful-api-guidelines"
user-invocable: true
---

# RESTful API Guidelines

Source: https://github.com/ppzxc/restful-api-guidelines

Keywords MUST, SHOULD, MAY follow RFC 2119/8174.

---

## Profile Guide

규칙마다 `[T1]`, `[T2]`, `[T3]` 태그가 붙어 있다. 사용자가 프로필을 지정하면 **해당 Tier 이하의 규칙만 적용**한다.

| 프로필 | 포함 Tier | 대상 | 규칙 수 |
|--------|-----------|------|---------|
| **Essential** | T1 only | 모든 API — 첫날부터 | ~87 |
| **Standard** | T1 + T2 | 프로덕션 운영 단계 | ~121 |
| **Full** | T1 + T2 + T3 | 대규모/엔터프라이즈 API | ~146 |

**사용 예시:** "Essential 프로필로 이 API를 리뷰해줘" → T1 규칙만 체크한다.

**Tier 분류 기준 [ADR-0010]:**
- **T1 (Essential):** 후행 도입 시 하위 호환성 파괴 위험 / 보안 필수 / HTTP 표준 / API 계약 근간
- **T2 (Standard):** 프로덕션 운영 편의, 후행 도입 가능
- **T3 (Full):** 엔터프라이즈/고급 패턴, 특정 도메인 한정

---

## URL Design

**Resource-oriented design** — APIs are designed around resources (nouns). URL paths express resource hierarchy; behavior is expressed via HTTP methods and custom methods.
- Every resource MUST support at least GET (retrieval) `[T1]`
- Prefer **standard methods** (GET, POST, PATCH, DELETE); use custom methods only when standard methods cannot express the operation `[T1]`
- Do not mirror database structure in API schema `[T1]`

- **kebab-case** for path segments: `/user-profiles`, `/product-categories/123` `[T1]`
- **Plural nouns** for collections: `/articles` not `/article` `[T1]`
- **No verbs in resource paths** — use HTTP methods for CRUD; non-CRUD actions use `POST` with colon syntax (resource-level: `/{resource}/{id}:{action}`, collection-level: `/{resource}:{action}`) `[T1]`
- **No file extensions** (`.json`, `.xml`) `[T1]`
- **No trailing slash** — `/articles` not `/articles/` `[T1]`
- **camelCase** for query parameters: `pageSize=20&sortOrder=desc` `[T1]`
- ASCII lowercase letters, numerals, and hyphens only in path segments `[T1]`
- Repeat parameter names for arrays: `?tag=tech&tag=design` `[T1]`
- **Single sub-resource nesting** — `/{parent}/{parentId}/{child}/{childId}` e.g., `/users/42/profiles/7` `[T2]`

**Nesting depth rule:** `[T2]`

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
| HEAD | Retrieve metadata only (no body) | Yes | Yes |
| OPTIONS | Retrieve allowed methods/CORS info | Yes | Yes |

- **HEAD (M-8):** Clients SHOULD use HEAD to check resource existence or last-modified time without downloading the full body. `[T2]`
- **OPTIONS (M-8):** Servers MUST support OPTIONS for CORS preflight and SHOULD use it to describe supported methods via the `Allow` header. `[T2]`
- GET, HEAD, DELETE must not include request bodies. `[T1]`

**2xx Success:**
- `200 OK` — standard success `[T1]`
- `201 Created` — creation success; include `Location` header with new resource URL `[T1]`
- `202 Accepted` — request accepted, processing not complete; used for async or deferred operations `[T2]`
- `204 No Content` — success with no body (DELETE, etc.) `[T1]`

**4xx Client Error:**
- `400 Bad Request` — malformed request, validation failure `[T1]`
- `401 Unauthorized` — missing/expired authentication `[T1]`
- `403 Forbidden` — authenticated but not authorized `[T1]`
- `404 Not Found` — resource doesn't exist `[T1]`
- `409 Conflict` — duplicate resource (same ID or unique constraint violation) `[T1]`
- `412 Precondition Failed` — `If-Match` etag mismatch (conditional request failed) `[T1]`
- `422 Unprocessable Entity` — semantic validation failure `[T1]`
- `429 Too Many Requests` — rate limit exceeded `[T1]`

**5xx Server Error:**
- `500 Internal Server Error` — unexpected failure `[T1]`
- `503 Service Unavailable` — temporary unavailability `[T1]`

## Headers

- `Content-Type: application/json` for bodies `[T1]`
- `Accept: application/json` for content negotiation `[T1]`
- `Location` header on 201 Created `[T1]`
- `Total-Count` for collection size `[T2]`
- RFC 8288 `Link` header for pagination `[T2]`
- **No `X-` prefix on custom headers** (RFC 6648/BCP 178) — `X-` was intended for experimental headers but causes naming conflicts when they become standards. All new APIs MUST define custom headers without this prefix. Exception: legacy headers already standardized with `X-` (e.g., `X-Forwarded-For`) retain their names for compatibility `[T1]`
- `Cache-Control` header specifies caching strategy `[T2]`
- `Request-Id` header — server MUST include a unique request identifier (UUID v4) in every response; if the client sends `Request-Id`, the server SHOULD adopt it or generate a new one `[T1]`
- Propagate `Request-Id` across microservices for distributed tracing `[T1]`
- Log `Request-Id` in all service logs for debugging correlation `[T1]`
- `ETag` — opaque string representing the resource version; server includes in responses `[T1]`
- `If-Match` — client sends etag value on Update/Delete requests for optimistic concurrency control `[T1]`

## JSON Format

- **camelCase** field names: `userId`, `createdAt`, `isActive` `[T1]`
- Never snake_case or abbreviations `[T1]`
- Omit null/missing fields entirely (do not send `"field": null`) `[T1]`
- Date/time values as RFC 3339 strings; server responses in UTC (`Z`) `[T1]`
- Standard resource fields: `id`, `createdAt` (create-only), `updatedAt` (read-only) `[T1]`
- Servers must ignore read-only fields in request bodies `[T1]`

**State Enum Pattern (AIP-216):** `[T1]` For representing resource lifecycle state:
- State field name MUST be `state` (not `status` — avoid confusion with HTTP status codes)
- First enum value MUST always be `STATE_UNSPECIFIED` (initial/unknown state)
- `state` is OUTPUT_ONLY — direct PATCH updates are prohibited; state transitions via custom methods only
- Common patterns: `ACTIVE/INACTIVE`, `PENDING/RUNNING/SUCCEEDED/FAILED`

## Error Response (RFC 7807/9457 + AIP-193 Hybrid)

```json
{
  "type": "https://api.example.com/errors/validation-failed",
  "title": "Validation Failed",
  "status": 400,
  "code": "VALIDATION_ERROR",
  "detail": "The request contains invalid fields.",
  "instance": "/users",
  "traceId": "abc-123-xyz",
  "details": [
    {
      "@type": "type.googleapis.com/google.rpc.BadRequest",
      "fieldViolations": [
        {
          "field": "user.email",
          "description": "Must be a valid email address."
        }
      ]
    },
    {
      "@type": "type.googleapis.com/google.rpc.ErrorInfo",
      "reason": "INVALID_FIELD_VALUE",
      "domain": "api.example.com"
    }
  ]
}
```

- `Content-Type: application/problem+json` `[T1]`
- **Machine-readable code:** Include a `code` string field (UPPER_SNAKE_CASE) for client logic branching. `[T1]`
- **Field-level errors (AIP-193 style):** For 400/422 errors, include a `details` array with `@type` polymorphic objects. `[T1]`
  - `google.rpc.BadRequest`: contains `fieldViolations` (`field` path and `description`).
  - `google.rpc.ErrorInfo`: contains stable `reason` and `domain`.
- Include **all** validation failures at once, not incrementally. `[T1]`
- Never expose stack traces, internal paths, or DB errors. `[T1]`
- `traceId` value MUST match the `Request-Id` response header for consistent debugging. `[T1]`

## Resource Schema & Field Rules

- Standard resource fields: `id`, `createdAt` (create-only), `updatedAt` (read-only) `[T1]`
- Resource identifiers are opaque strings — clients must not parse structure `[T1]`
- Omit null/missing fields entirely (do not send `"field": null`) `[T1]`
- Servers must ignore read-only fields in request bodies `[T1]`

**Field Behavior Annotations** (AIP-203) `[T1]` — Declare field behavior in OpenAPI schema using the `x-field-behavior` extension field.

| Annotation | Meaning | Server behavior on Create | Server behavior on Update |
|-----------|---------|--------------------------|--------------------------|
| `REQUIRED` | Client must provide | Missing → `400 Bad Request` | Missing → `400 Bad Request` |
| `OUTPUT_ONLY` | Set by server; client must not provide | Request value ignored | Request value ignored |
| `INPUT_ONLY` | Client-provided; excluded from response | Excluded from response after processing | Excluded from response after processing |
| `IMMUTABLE` | Cannot change after creation | Client may provide | Value change attempt → `400 Bad Request` |
| `OPTIONAL` | Optionally provided | Default applied | Omitted → existing value preserved |
| `IDENTIFIER` | Resource identifier; cannot change | Client may provide (optional) | Value change attempt → `400 Bad Request` |

OpenAPI mapping: `OUTPUT_ONLY` → `readOnly: true`, `INPUT_ONLY` → `writeOnly: true`, other annotations → `x-field-behavior` extension. `[T1]`

## CRUD Behavior

**Standard method response rules:**
- POST (Create): return `201` with full resource + `Location` header `[T1]`
- PATCH (Update): return the updated resource `[T1]`
- DELETE: return `204` with no body `[T1]`

**POST (Create):** Return `201` with full resource + `Location` header. `[T1]`
- Clients SHOULD be able to specify resource ID (optional).
- Duplicate creation MUST return `409 Conflict`.

**PATCH (Update — default):** Only modify fields specified by `updateMask`; unlisted fields are unchanged. `[T1]`
- `updateMask` query parameter is REQUIRED: comma-separated field paths — `?updateMask=title,content`
- Response MUST return the updated full resource.
- `updateMask=*`: update all mutable fields present in the request body.
- Empty mask → `400 Bad Request`; unknown field path → `400 Bad Request`
- Nested fields use dot notation: `?updateMask=address.city`
- Field Behavior interactions with mask:
  - `OUTPUT_ONLY` in mask → silently ignored (not an error)
  - `IMMUTABLE` in mask + value changed → `400 Bad Request`
  - `REQUIRED` in mask → field must be present in body

**Optimistic Concurrency Control (AIP-154):** `[T1]` Include an `etag` field in the resource JSON schema (opaque string, OUTPUT_ONLY, updated on every change); the server also includes the same value in the `ETag` response header.

- Pass etag via `If-Match: {etag}` header on Update/Delete requests
- Etag mismatch → return `412 Precondition Failed` (include current resource in response body)
- If `If-Match` header is omitted → execute unconditionally (opt-in behavior)

**PUT (Content Replace — exceptional use only):** Use only when full content replacement is semantically required (file upload, binary content, configuration replacement). MUST NOT be used for resource attribute updates — use PATCH instead. `[T1]`

**DELETE:** Return `204`; re-deletion policy is per-service (404 or 204). `[T1]`
- Optionally support `force` query parameter for cascading child resource deletion (`DELETE /resources/{id}?force=true`).

**Soft Delete (AIP-164):** `[T3]` When a recoverable deletion pattern is needed instead of immediate permanent deletion:
- Add `deleteTime` (deletion timestamp) and `expireTime` (scheduled permanent deletion time) fields to the resource (OUTPUT_ONLY)
- Restore: `POST /{resource}/{id}:undelete` custom method
- List: exclude soft-deleted resources by default; include with `?showDeleted=true`
- Get: return soft-deleted resources normally (include `deleteTime`)
- Automatically permanently deleted after retention period (default 30 days)

**Change Validation / Dry Run (AIP-163):** `[T3]` Pre-validation for Create/Update requests:
- `?validateOnly=true` query parameter
- When `true`: validation only — no resource changes, no side effects
- On validation success: return a response similar to actual execution (server-generated fields may be excluded)
- On validation failure: same RFC 9457 error format

## Actions

**Non-CRUD actions:** `[T1]`

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

> **Colon syntax compatibility note**: Frameworks such as Express.js and Rails that use `:` for path parameter syntax require additional routing configuration (e.g., regex routes). Verify colon path support in your OpenAPI specification.

**Action response status codes:** `[T1]`

| Scenario | Status Code | Response Body |
|----------|-------------|---------------|
| Sync action — resource updated | `200 OK` | Updated resource |
| Sync action — no response body | `204 No Content` | None |
| Async action — fire-and-forget | `202 Accepted` | None or minimal acknowledgement |

For async actions that create a pollable job resource, use `201 Created` + `Location` header instead (see [Long-Running Operations](#long-running-operations)).

## Collections & Pagination

- Collections return **top-level JSON array** `[]` — never wrapped in an envelope object `[T1]`
- **Empty collections**: return `200 OK` + `[]` — never `404`; include `Total-Count: 0` `[T1]`
- Use `Link` header (RFC 8288) with `rel="next"`, `prev`, `first`, `last` for navigation `[T2]`
- `Total-Count` header for total item count `[T2]`

### API 표면 계약 — 페이지네이션 방식

#### Token-based Pagination (AIP-158, 권장) `[T2]`

불투명 토큰(`pageToken`)을 사용한다. 클라이언트는 토큰 내부 구조를 파싱하거나 직접 생성해서는 안 된다.

**파라미터:**
- `pageSize` — 페이지당 항목 수 (기본값 20, 최대 100)
- `pageToken` — 이전 응답의 `nextPageToken` 값 (첫 페이지는 생략)

**요청/응답 흐름:**

```
# 첫 페이지
GET /articles?pageSize=20

200 OK
Total-Count: 58
Link: <https://api.example.com/articles?pageSize=20&pageToken=eyJpZCI6MjB9>; rel="next"
[ { "id": "1", ... }, ..., { "id": "20", ... } ]
```

```
# 다음 페이지
GET /articles?pageSize=20&pageToken=eyJpZCI6MjB9

200 OK
Total-Count: 58
Link: <https://api.example.com/articles?pageSize=20&pageToken=eyJpZCI6NDB9>; rel="next",
      <https://api.example.com/articles?pageSize=20>; rel="first"
[ { "id": "21", ... }, ..., { "id": "40", ... } ]
```

```
# 마지막 페이지 — rel="next" 없음
GET /articles?pageSize=20&pageToken=eyJpZCI6NDB9

200 OK
Total-Count: 58
Link: <https://api.example.com/articles?pageSize=20>; rel="first"
[ { "id": "41", ... }, ..., { "id": "58", ... } ]
```

**규칙:**
- `pageToken` 클라이언트 파싱/직접 생성 금지 — 반드시 서버가 반환한 값만 사용 `[T2]`
- `pageSize < 1` → `400 Bad Request`; `pageSize > max` → max로 cap (에러 없음) `[T2]`
- 다음 페이지가 없으면 `rel="next"` 생략 `[T2]`

**서버 구현 참고 (클라이언트에 노출 금지):**

토큰 내부에 정렬 키(keyset)를 인코딩하는 방식을 권장한다. OFFSET 쿼리(`OFFSET N LIMIT 20`)는 깊은 페이지에서 O(N) 성능 저하가 발생하므로 사용하지 않는다.

```sql
-- pageToken 내부: { "createdAt": "2024-06-15T10:30:00Z", "id": 20 } → Base64 인코딩
SELECT * FROM articles
WHERE (created_at, id) < ('2024-06-15T10:30:00Z', 20)  -- keyset 조건
ORDER BY created_at DESC, id DESC
LIMIT 21  -- pageSize + 1 (다음 페이지 존재 여부 판별)
-- 결과가 21건이면 마지막 항목을 제거하고 next pageToken 생성
-- 결과가 21건 미만이면 next pageToken 없음
```

#### Offset-based Pagination (소규모 데이터 한정) `[T2]`

관리자 UI 등 임의 페이지 접근이 필요하고 데이터가 10,000건 미만인 경우에 한해 사용한다.

- `page` + `pageSize` 파라미터
- 대용량 데이터에서 성능 저하 및 데이터 삽입 시 중복/누락 발생 위험

### 페이지네이션 선택 기준

```
임의 페이지 접근 필요 AND 데이터 < 10,000건?
  └─ Yes → Offset (page + pageSize)
  └─ No  → Token-based (pageToken + pageSize, AIP-158) ← 기본 권장
```

**같은 API 내 엔드포인트별로 다른 전략 사용 가능. 단, 같은 엔드포인트에서 두 전략 동시 제공 금지.**

## Filtering & Sorting

❌ Do not use individual query parameters for filtering (e.g., `?status=PUBLISHED&createdAfter=...`). Use `filter` expression instead. `[T1]`

**Filter expression (AIP-160):** Use the `filter` query parameter with a structured expression string. `[T1]`
- Syntax: `?filter=status = "ACTIVE" AND price >= 1000`
- Comparison operators: `=`, `!=`, `<`, `>`, `<=`, `>=`
- Logical operators: `AND`, `OR`, `NOT`; grouping with parentheses
- String and timestamp values: double-quoted — `?filter=createdAt > "2024-01-01T00:00:00Z"`
- Number values: unquoted — `?filter=price >= 100`
- Boolean values: `true` / `false` — `?filter=isPublished = true`
- Nested field access: dot notation — `?filter=author.name = "Kim"`
- Repeated field membership: `has()` — `?filter=has(tags, "golang")`
- Invalid filter expression → `400 Bad Request` with RFC 9457 error body
- Sort: `?orderBy=createdAt:desc` / multi: `?orderBy=createdAt:desc,title:asc`
- **Full-text search (M-7):** Use the `q` query parameter for keyword-based search across multiple fields (e.g., `?q=searchterm`). `[T2]`

## Partial Response & Resource Expansion

**Partial Response (AIP-157):** Use the `fields` query parameter to request specific fields only. `[T2]`
- Syntax: `?fields=id,title,author.name` (comma-separated field paths)
- Nested fields use dot notation: `?fields=id,author.name,author.email`
- `id` is always included regardless of the `fields` value
- Applied to each item in List responses
- `INPUT_ONLY` fields excluded from responses regardless of `fields`
- **ETag interaction:** Use Weak ETags (`W/"..."`) or omit ETags for partial responses, rather than computing Strong ETags which negates performance benefits.
- Unknown field name in `fields` → `400 Bad Request`

**Resource Expansion (Expand/Embed) (M-4):** Use the `expand` query parameter to include related resources in the response. `[T2]`
- Syntax: `?expand=author,comments.author`
- **Total Entity Limit REQUIRED:** Servers MUST enforce a hard limit on the *total number* of expanded entities returned per request (e.g., max 100) to prevent N+1/DoS attacks. Exceeding the limit → `400 Bad Request`.
- Depth limit: Servers SHOULD limit expansion depth (default max 3).
- Selective expansion: Clients MUST only expand what is needed.
- Expansion failure: If a requested resource cannot be expanded (e.g., permissions), the server SHOULD omit it or return a placeholder without failing the main request.

## Bulk Operations

Bulk operations allow processing multiple resources in a single request to reduce network overhead.

✅ **Required**: Express bulk operations as custom methods on the collection URL using colon syntax. `[T3]`

| Method | Goal | Endpoint |
|--------|------|----------|
| `batchCreate` | Create multiple resources | `POST /{resources}:batchCreate` |
| `batchGet` | Retrieve multiple resources by ID | `POST /{resources}:batchGet` |
| `batchUpdate` | Update multiple resources | `POST /{resources}:batchUpdate` |
| `batchDelete` | Delete multiple resources | `POST /{resources}:batchDelete` |

✅ **Required**: The request body MUST contain an array of items or IDs to process. `[T3]`
✅ **Required**: The response SHOULD contain an array of results matching the order of the request. `[T3]`
⚠️ **Recommended**: Limit the maximum number of items in a single bulk request (e.g., max 100) to prevent long-running requests. `[T3]`
⚠️ **Recommended**: Return `400 Bad Request` if the request exceeds the maximum item limit. `[T3]`
✅ **Required**: **Atomic vs. Non-atomic:** Specify whether the bulk operation is atomic (all-or-nothing) or non-atomic (partial success allowed). Use the `atomic` query parameter if the behavior is configurable. `[T3]`
✅ **Required**: For non-atomic operations, the response MUST use a structure that can express per-item success or failure (including RFC 9457 error objects for failed items). `[T3]`

**Request Example (batchCreate):**

```json
POST /articles:batchCreate
{
  "requests": [
    { "title": "Article 1", "content": "..." },
    { "title": "Article 2", "content": "..." }
  ]
}
```

**Response Example (non-atomic batchCreate):**

```json
{
  "results": [
    { "status": 201, "resource": { "id": "1", "title": "Article 1", ... } },
    { "status": 400, "error": { "title": "Validation Failed", "detail": "Title is required", ... } }
  ]
}
```

## API Versioning

**URL path versioning is PROHIBITED** — `/v1/articles` violates REST principles (same resource must have one URL) `[T1]`

**Header versioning is REQUIRED:** `[T1]`
```
Api-Version: 2024-01-20   (ISO 8601 date format)
```

> Header name uses no `X-` prefix per RFC 6648/BCP 178.

- Requests without version header MUST receive `400 Bad Request` — latest version auto-assignment is prohibited `[T1]`
- Responses always include the applied version `[T1]`
- Maintain previous versions for minimum 6 months before deprecation `[T2]`

**Breaking changes** (require new `Api-Version` date): `[T1]`

| Category | Examples |
|----------|----------|
| Removal | endpoint, field, enum value removal |
| Rename | field or endpoint name change |
| Type change | field type or format change (e.g., string → int) |
| Constraint tightening | optional → required, new required field, stricter validation |
| Semantic change | status code meaning change, default value change, sort order change |

**Compatible changes** (no version bump): `[T2]`

| Category | Examples |
|----------|----------|
| Addition | new endpoint, new optional field, new enum value, new query parameter |
| Relaxation | required → optional, loosened validation |
| Metadata | response property order change, description update |

**Compatibility principles:** `[T1]`
- Clients MUST ignore unknown fields in responses (tolerant reader)
- Servers MUST ignore unknown fields in requests
- Enums are open-ended — clients MUST handle unknown values gracefully

## Deprecation

Deprecated APIs MUST include these response headers (RFC 9745, RFC 8594): `[T1]`

```
Deprecation: true
Sunset: Sat, 01 Jan 2025 00:00:00 GMT
Link: <https://api.example.com/new-resource>; rel="successor-version"
```

- Deprecation notice must be given at least 6 months before the sunset date `[T1]`

## Rate Limiting & Retries (M-5)

- **Response headers (always):** `RateLimit: limit=N, remaining=N, reset=N` + `RateLimit-Policy: N;w=N` `[T2]`
- **429 Too Many Requests:** Include `Retry-After` (delta-seconds) + RFC 9457 Problem Details body. `[T2]`
- **Client retry strategy:** `[T2]`
  - Honor `Retry-After` if present.
  - For other transient errors (502, 503, 504), use **Exponential Backoff with Jitter**.
  - Max retries SHOULD be limited (e.g., 3-5 times).

## Caching (M-2)

- **`Cache-Control` header:** Specify caching directives (`public`, `private`, `no-cache`, `max-age`). `[T2]`
- **`ETag` usage:** All mutable resources MUST provide an `ETag` (see [Optimistic Concurrency Control](#optimistic-concurrency-control)). `[T2]`
- **`Last-Modified`:** SHOULD be used alongside ETag for legacy client compatibility. `[T3]`
- **Vary:** Use `Vary: Accept, Api-Version` if responses change based on content negotiation or versioning. `[T3]`

## Long-Running Operations

- Return `201 Created` + `Location` header with domain resource immediately `[T3]`
- Include `status` field: `PENDING` → `IN_PROGRESS` → `COMPLETED` | `FAILED` `[T3]`
- Client polls `GET {Location}` to check progress `[T3]`
- On failure: include error details in response body `[T3]`

## Idempotency-Key

- Support `Idempotency-Key` header for POST endpoints where duplicate execution is risky (payments, orders) `[T3]`
- Client-generated UUID v4 `[T3]`
- First request: process normally and store result `[T3]`
- Re-request with same key: return stored result without reprocessing `[T3]`
- Key validity: minimum 24 hours `[T3]`
- POST endpoints with financial impact MUST support `Idempotency-Key` `[T3]`

## OpenAPI Specification

All APIs MUST maintain an OpenAPI 3.0+ spec as the single source of truth (API First). `[T2]`

| Rule | Tier | Description |
|------|------|-------------|
| `description` required | `[T2]` | Every endpoint, parameter, and schema property MUST have a `description` |
| `operationId` required | `[T2]` | Every operation MUST have a unique `operationId` for code generation and documentation |
| `example` recommended | `[T3]` | Key schemas and parameters SHOULD include `example` or `examples` |
| `readOnly`/`writeOnly` | `[T2]` | Map create-only fields to `writeOnly`, read-only fields to `readOnly` |
| Minimize `nullable` | `[T2]` | Follow field-omission principle; use `nullable` only when explicitly needed |
| Shared error schema | `[T2]` | Define RFC 9457 Problem Details as a `$ref` shared component |
| Internal-only marking | `[T3]` | Mark non-public endpoints with `x-internal: true` extension |
| Automated validation | `[T1]` | MUST validate spec compliance in CI using linters (e.g., Spectral, Zally) |

## Authentication & Security

- **HTTPS Required (H-5):** All APIs MUST use HTTPS (TLS 1.2+) to ensure data in transit is encrypted. `[T1]`
- **Security Headers REQUIRED:** Responses MUST include `X-Content-Type-Options: nosniff` and `Strict-Transport-Security`. `[T1]`
- `Authorization: Bearer {token}` for JWT authentication `[T1]`
- `Authorization: ApiKey {key}` for API Key authentication `[T1]`
- Never pass credentials in query parameters (logged by servers) `[T1]`
- `401 Unauthorized`: missing/expired authentication — include `WWW-Authenticate` header `[T1]`
- `403 Forbidden`: authenticated but not authorized `[T1]`
- Avoid storing sensitive data in query strings (they get logged) `[T1]`

**Authorization (BOLA Prevention):** `[T1]`
- Servers MUST verify ownership/permissions for *every* specific resource access (`/{resource}/{id}`).

**Mass Assignment Prevention (BOPA):** `[T1]`
- Servers MUST use an Allowlist in DTOs. Clients MUST NOT be able to modify protected fields (`role`, `isVerified`) via `PATCH` body/`updateMask`.

**CORS (Cross-Origin Resource Sharing) (H-4):** `[T2]`
- Servers MUST explicitly define `Access-Control-Allow-Origin` (do not use wildcard `*` if authentication is required).
- Use `Access-Control-Allow-Methods` to list permitted HTTP methods.
- Use `Access-Control-Max-Age` (e.g., 86400 seconds) to cache preflight requests and reduce overhead.
- Explicitly list custom headers in `Access-Control-Expose-Headers` if clients need to read them (e.g., `Total-Count`, `Request-Id`).

**Webhooks (M-6):** `[T3]`
- **Payload Structure:** Use a consistent wrapper: `{"id": "evt_...", "type": "resource.event", "created": 123456789, "data": { ... }}`.
- **Signing:** Servers MUST sign payloads using HMAC-SHA256 with a shared secret, included in the `X-Hub-Signature-256` header.
- **Idempotency:** Webhook handlers SHOULD be idempotent to handle duplicate events safely.
- **Retries:** Servers SHOULD use exponential backoff for failed webhook deliveries (e.g., 5-10 retries over 24 hours).

**Health Check (L-1):** `[T2]`
- **Endpoint:** `GET /health` SHOULD be used to monitor service availability.
- **Response:** Return `200 OK` with `{"status": "UP"}` if the service is healthy.
- **Deep vs Shallow:**
  - Shallow: Just returns 200 (service is running).
  - Deep: Checks dependencies (DB, cache, downstream services) — use cautiously to avoid cascading failures in load balancer health checks.
