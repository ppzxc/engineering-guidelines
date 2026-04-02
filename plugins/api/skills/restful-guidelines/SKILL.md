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

## HTTP Methods

| Method | Purpose | Idempotent | Safe |
|--------|---------|-----------|------|
| GET | Retrieve | Yes | Yes |
| POST | Create / execute custom method | No | No |
| PUT | Full content replacement (file/binary upload) | Yes | No |
| PATCH | Partial update (default update method) | No | No |
| DELETE | Remove | Yes | No |

GET, HEAD, DELETE must not include request bodies.

## Status Codes

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
- `409 Conflict` — duplicate or optimistic lock failure
- `422 Unprocessable Entity` — semantic validation failure
- `429 Too Many Requests` — rate limit exceeded

**5xx Server Error:**
- `500 Internal Server Error` — unexpected failure
- `503 Service Unavailable` — temporary unavailability

## JSON Format

- **camelCase** field names: `userId`, `createdAt`, `isActive`
- Never snake_case or abbreviations
- Omit null/missing fields entirely (do not send `"field": null`)
- Date/time values as RFC 3339 strings; server responses in UTC (`Z`)
- Standard resource fields: `id`, `createdAt` (create-only), `updatedAt` (read-only)
- Servers must ignore read-only fields in request bodies

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

## Headers

- `Content-Type: application/json` for bodies
- `Accept: application/json` for content negotiation
- `Location` header on 201 Created
- `Total-Count` for collection size
- RFC 8288 `Link` header for pagination
- **No `X-` prefix on custom headers** (RFC 6648/BCP 178) — `X-` was intended for experimental headers but causes naming conflicts when they become standards. All new APIs MUST define custom headers without this prefix. Exception: legacy headers already standardized with `X-` (e.g., `X-Forwarded-For`) retain their names for compatibility

## CRUD Behavior

**POST (Create):** Return `201` with full resource + `Location` header.

**PUT (Full Replace):** Idempotent; omitted mutable fields reset to defaults.

**PATCH (Partial Update):** Only modify fields present in body; others unchanged.

**DELETE:** Return `204`; re-deletion policy is per-service (404 or 204).

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
- **Breaking changes** (require version bump): field deletion, type changes, new required fields, enum removal, status code semantics change
- **Compatible changes**: new optional fields, new endpoints, new enum values

## Deprecation

Deprecated APIs MUST include these response headers (RFC 9745, RFC 8594):

```
Deprecation: true
Sunset: Sat, 01 Jan 2025 00:00:00 GMT
Link: <https://api.example.com/new-resource>; rel="successor-version"
```

- Deprecation notice must be given at least 6 months before the sunset date

## Key Principles

- Resource identifiers are opaque strings — clients must not parse structure
- Avoid storing sensitive data in query strings (they get logged)
- `Cache-Control` header specifies caching strategy
- Custom header names MUST NOT use `X-` prefix (RFC 6648/BCP 178) — applies to all new APIs; `X-Forwarded-For` and other headers already standardized with `X-` are grandfathered exceptions

## Filtering & Sorting

- Equality: `?status=PUBLISHED&authorId=123`
- Date range: `After`/`Before` suffix — `?createdAfter=2024-01-01T00:00:00Z`
- Numeric range: `Min`/`Max` suffix — `?priceMin=100&priceMax=500`
- Multi-value (IN): repeat param = OR — `?status=a&status=b`
- Cross-param = AND: `?status=PUBLISHED&authorId=123`
- Contains: `?q=keyword` (full-text) or `?titleContains=keyword` (field)
- Sort: `?orderBy=createdAt:desc` / multi: `?orderBy=createdAt:desc,title:asc`

## Pagination

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

## Rate Limiting

- Response headers (always): `RateLimit: limit=N, remaining=N, reset=N` + `RateLimit-Policy: N;w=N`
- 429 Too Many Requests: include `Retry-After` (delta-seconds) + RFC 9457 Problem Details body
- Client retry: honor `Retry-After`; otherwise exponential backoff + jitter

## Long-Running Operations

- Return `201 Created` + `Location` header with domain resource immediately
- Include `status` field: `PENDING` → `PROCESSING` → `COMPLETED` | `FAILED`
- Client polls `GET {Location}` to check progress
- On failure: include error details in response body
