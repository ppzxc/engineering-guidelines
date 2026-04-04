---
description: "Use when designing, implementing, or reviewing REST APIs — URL structure, HTTP methods, status codes, JSON format, error responses, and headers. Source: github.com/ppzxc/restful-api-guidelines"
user-invocable: true
---

# RESTful API Guidelines

Source: https://github.com/ppzxc/restful-api-guidelines

Keywords MUST, SHOULD, MAY follow RFC 2119/8174.

---

## URL Design

**Resource-oriented design** — APIs are designed around resources (nouns). URL paths express resource hierarchy; behavior is expressed via HTTP methods and custom methods.
- Every resource MUST support at least GET (retrieval)
- Prefer **standard methods** (GET, POST, PATCH, DELETE); use custom methods only when standard methods cannot express the operation
- Do not mirror database structure in API schema

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
- `ETag` — opaque string representing the resource version; server includes in responses
- `If-Match` — client sends etag value on Update/Delete requests for optimistic concurrency control

## JSON Format

- **camelCase** field names: `userId`, `createdAt`, `isActive`
- Never snake_case or abbreviations
- Omit null/missing fields entirely (do not send `"field": null`)
- Date/time values as RFC 3339 strings; server responses in UTC (`Z`)
- Standard resource fields: `id`, `createdAt` (create-only), `updatedAt` (read-only)
- Servers must ignore read-only fields in request bodies

**State Enum Pattern (AIP-216):** For representing resource lifecycle state:
- State field name MUST be `state` (not `status` — avoid confusion with HTTP status codes)
- First enum value MUST always be `STATE_UNSPECIFIED` (initial/unknown state)
- `state` is OUTPUT_ONLY — direct PATCH updates are prohibited; state transitions via custom methods only
- Common patterns: `ACTIVE/INACTIVE`, `PENDING/RUNNING/SUCCEEDED/FAILED`

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

**Field Behavior Annotations** (AIP-203) — Declare field behavior in OpenAPI schema using the `x-field-behavior` extension field.

| Annotation | Meaning | Server behavior on Create | Server behavior on Update |
|-----------|---------|--------------------------|--------------------------|
| `REQUIRED` | Client must provide | Missing → `400 Bad Request` | Missing → `400 Bad Request` |
| `OUTPUT_ONLY` | Set by server; client must not provide | Request value ignored | Request value ignored |
| `INPUT_ONLY` | Client-provided; excluded from response | Excluded from response after processing | Excluded from response after processing |
| `IMMUTABLE` | Cannot change after creation | Client may provide | Value change attempt → `400 Bad Request` |
| `OPTIONAL` | Optionally provided | Default applied | Omitted → existing value preserved |
| `IDENTIFIER` | Resource identifier; cannot change | Client may provide (optional) | Value change attempt → `400 Bad Request` |

OpenAPI mapping: `OUTPUT_ONLY` → `readOnly: true`, `INPUT_ONLY` → `writeOnly: true`, other annotations → `x-field-behavior` extension.

## CRUD Behavior

**Standard method response rules:**
- POST (Create): return `201` with full resource + `Location` header
- PATCH (Update): return the updated resource
- DELETE: return `204` with no body

**POST (Create):** Return `201` with full resource + `Location` header.
- Clients SHOULD be able to specify resource ID (optional).
- Duplicate creation MUST return `409 Conflict`.

**PATCH (Update — default):** Only modify fields specified by `updateMask`; unlisted fields are unchanged.
- `updateMask` query parameter is REQUIRED: comma-separated field paths — `?updateMask=title,content`
- Response MUST return the updated full resource.
- `updateMask=*`: update all mutable fields present in the request body.
- Empty mask → `400 Bad Request`; unknown field path → `400 Bad Request`
- Nested fields use dot notation: `?updateMask=address.city`
- Field Behavior interactions with mask:
  - `OUTPUT_ONLY` in mask → silently ignored (not an error)
  - `IMMUTABLE` in mask + value changed → `400 Bad Request`
  - `REQUIRED` in mask → field must be present in body

**Optimistic Concurrency Control (AIP-154):** Include an `etag` field in the resource JSON schema (opaque string, OUTPUT_ONLY, updated on every change); the server also includes the same value in the `ETag` response header.

- Pass etag via `If-Match: {etag}` header on Update/Delete requests
- Etag mismatch → return `412 Precondition Failed` (include current resource in response body)
- If `If-Match` header is omitted → execute unconditionally (opt-in behavior)

**PUT (Content Replace — exceptional use only):** Use only when full content replacement is semantically required (file upload, binary content, configuration replacement). MUST NOT be used for resource attribute updates — use PATCH instead.

**DELETE:** Return `204`; re-deletion policy is per-service (404 or 204).
- Optionally support `force` query parameter for cascading child resource deletion (`DELETE /resources/{id}?force=true`).

**Soft Delete (AIP-164):** When a recoverable deletion pattern is needed instead of immediate permanent deletion:
- Add `deleteTime` (deletion timestamp) and `expireTime` (scheduled permanent deletion time) fields to the resource (OUTPUT_ONLY)
- Restore: `POST /{resource}/{id}:undelete` custom method
- List: exclude soft-deleted resources by default; include with `?showDeleted=true`
- Get: return soft-deleted resources normally (include `deleteTime`)
- Automatically permanently deleted after retention period (default 30 days)

**Change Validation / Dry Run (AIP-163):** Pre-validation for Create/Update requests:
- `?validateOnly=true` query parameter
- When `true`: validation only — no resource changes, no side effects
- On validation success: return a response similar to actual execution (server-generated fields may be excluded)
- On validation failure: same RFC 9457 error format

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

> **Colon syntax compatibility note**: Frameworks such as Express.js and Rails that use `:` for path parameter syntax require additional routing configuration (e.g., regex routes). Verify colon path support in your OpenAPI specification.

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

❌ Do not use individual query parameters for filtering (e.g., `?status=PUBLISHED&createdAfter=...`). Use `filter` expression instead.

**Filter expression (AIP-160):** Use the `filter` query parameter with a structured expression string.
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

## Partial Response

**Partial Response (AIP-157):** Use the `fields` query parameter to request specific fields only.
- Syntax: `?fields=id,title,author.name` (comma-separated field paths)
- Nested fields use dot notation: `?fields=id,author.name,author.email`
- `id` is always included regardless of the `fields` value
- Applied to each item in List responses
- `INPUT_ONLY` fields excluded from responses regardless of `fields`
- ETag reflects the full resource, not the partial view
- Unknown field name in `fields` → `400 Bad Request`

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
