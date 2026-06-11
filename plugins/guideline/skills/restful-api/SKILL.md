---
name: restful-api
description: "Use when designing, implementing, or reviewing REST APIs (URL structure, HTTP methods, status codes, JSON format, error responses, and headers). Source: github.com/ppzxc/restful-api-guidelines — /guideline:restful-api, \"REST API Design\", \"REST API Review\", \"API Guidelines\""
user-invocable: true
---

# RESTful API Guidelines

Source: https://github.com/ppzxc/restful-api-guidelines

Keywords MUST, SHOULD, MAY follow RFC 2119/8174.

---

## Profile Guide

Each rule is tagged with `[T1]`, `[T2]`, or `[T3]`. If the user specifies a profile, **only the rules up to that Tier are applied**.

| Profile | Included Tiers | Target | Rule Count |
|--------|-----------|------|---------|
| **Essential** | T1 only | All APIs — from day one | ~88 |
| **Standard** | T1 + T2 | Production environments | ~124 |
| **Full** | T1 + T2 + T3 | Large-scale/Enterprise APIs | ~149 |

**Example usage:** "Review this API using the Essential profile" → Check only T1 rules.

**No-arg Behavior (ADR-0045):**
- **Interactive Session**: If no profile is specified, use AskUserQuestion to confirm: "Which profile should be used for review?" (Essential [T1] / Standard [T1+T2] / Full [T1+T2+T3, Recommended]).
- **Non-interactive Session**: Fall back to the Full profile (T1+T2+T3).

**Tier Classification Criteria [ADR-0010]:**
- **T1 (Essential):** High risk of breaking backward compatibility if introduced later / Security essentials / HTTP standards / Core API contract.
- **T2 (Standard):** Production convenience, can be introduced later.
- **T3 (Full):** Enterprise/advanced patterns, limited to specific domains.

---

## URL Design

**Resource-oriented design (AIP-121)** — APIs are designed around resources (nouns). URL paths express resource hierarchy; behavior is expressed via HTTP methods and custom methods.
- Every resource MUST support at least GET (retrieval) `[T1]`
- Collection resources MUST support List, except singleton resources where only one instance can exist (e.g., `/users/{id}/settings`) `[T1]` (AIP-121)
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
- **No `X-` prefix on custom headers** (RFC 6648/BCP 178) — `X-` was intended for experimental headers but causes naming conflicts when they become standards. All new APIs MUST define custom headers without this prefix. Exception: legacy headers already standardized with `X-` (e.g., `X-Forwarded-For`, `X-Content-Type-Options`, `X-Hub-Signature-256`) retain their names for compatibility `[T1]`
- `Cache-Control` header specifies caching strategy `[T2]`
- `traceparent` header — W3C Trace Context standard for distributed tracing. Must format as `version-trace_id-parent_id-trace_flags` (e.g., `00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01`) `[T1]`
- `tracestate` header — vendor-specific tracing metadata propagation (optional) `[T1]`
- `Request-Id` header — server MUST include a unique request identifier (UUID v4) in every response; if the client sends `Request-Id`, the server SHOULD adopt it or generate a new one. In a distributed context, both W3C headers and legacy `Request-Id` MUST be propagated together (Dual Propagation) for backward compatibility `[T1]`
- Propagate distributed tracing context across microservices: API Gateway (or first entrypoint service) MUST generate a new `traceparent` and `Request-Id` if they are missing in the incoming request `[T1]`
- Invalid tracing context fallback: if the received `traceparent` is malformed/invalid, the server MUST ignore it and generate a new one (Restart Trace) without rejecting the request. Additionally, a warning log MUST be recorded for debugging correlation `[T1]`
- Log both `traceparent` and `Request-Id` in all service logs for debugging correlation `[T1]`
- `ETag` — opaque string representing the resource version; server includes in responses `[T1]`
- `If-Match` — client sends etag value on Update/Delete requests for optimistic concurrency control `[T1]`

## JSON Format

- **camelCase** field names: `userId`, `createdAt`, `isActive` `[T1]`
- Never snake_case or abbreviations `[T1]`
- Omit null/missing fields entirely (do not send `"field": null`) `[T1]`
  - *Exception*: In endpoints utilizing RFC 7396 (JSON Merge Patch) for explicit field deletion/nullification, clients MAY send `"field": null` to clear the field. In this case, the server MUST set the field to null or default. `[T2]`
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

- **Schema consistency (AIP-121):** The full resource representation MUST be identical across Get, List, Create, and Update responses. Partial Response via `fields` and batch result wrappers are explicit exceptions. `[T2]`
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

**Read-after-write consistency (AIP-121):** `[T2]` After a standard method succeeds, a subsequent GET MUST reflect the result — post-Create returns the resource, post-Update returns the final values, post-Delete returns `404 Not Found`. Exception: soft-deleted resources (AIP-164) remain retrievable via GET with a `deleteTime`.

**Standard method response rules:**
- POST (Create): return `201` with full resource + `Location` header `[T1]`
- PATCH (Update): return the updated resource `[T1]`
- DELETE: return `204` with no body `[T1]`

**POST (Create):** Return `201` with full resource + `Location` header. `[T1]`
- Clients SHOULD be able to specify resource ID (optional).
- Duplicate creation MUST return `409 Conflict`.

**PATCH (Update — default, AIP-134):** Only modify fields specified by `updateMask`; unlisted fields are unchanged. `[T1]`
- `updateMask` query parameter is REQUIRED: comma-separated field paths — `?updateMask=title,content` (AIP-134 HTTP binding: resource in body, mask as query param)
- Response MUST return the updated full resource.
- `updateMask=*`: update all mutable fields present in the request body.
- Empty mask → `400 Bad Request`.
- **Field Clearing (Data Nulling):**
  - If a field is specified in `updateMask` and the client sends `"field": null` in the Request Body, the server MUST clear that field (set to null/empty).
  - If a field is specified in `updateMask` but is missing (omitted) from the Request Body JSON payload, the server MUST clear that field (set to its default value or null/empty).
- **Nested fields and Dot Notation:**
  - Nested fields use dot notation: `?updateMask=profile.bio`
  - Sub-fields within a nested object can be individually updated or cleared using dot notation (e.g., clearing `profile.bio` while leaving `profile.website` unchanged).
- **Invalid Mask Paths:**
  - If the `updateMask` contains any invalid path (paths that do not exist or map to the resource schema), the server MUST reject the request with `400 Bad Request` (INVALID_ARGUMENT).
- Field Behavior interactions with mask:
  - `OUTPUT_ONLY` in mask → silently ignored (not an error)
  - `IMMUTABLE` in mask + value changed → `400 Bad Request`
  - `REQUIRED` in mask → field must be present in body
- **Alternative (JSON Merge Patch)**: If the API service implements RFC 7396 (JSON Merge Patch) and supports explicit `null` fields for deletion, `updateMask` MAY be optional, allowing partial updates based purely on the fields present in the request body. `[T2]`

**Optimistic Concurrency Control (AIP-154):** `[T1]` Include an `etag` field in the resource JSON schema (opaque string, OUTPUT_ONLY, updated on every change); the server also includes the same value in the `ETag` response header.

- Pass etag via `If-Match: {etag}` header on Update/Delete requests
- Etag mismatch → return `412 Precondition Failed` (include current resource in response body)
- If `If-Match` header is omitted → execute unconditionally (opt-in behavior)
- **Sensitive resources** (inventory, permissions, financial transactions): `If-Match` MUST be required; omission MUST return `428 Precondition Required` `[T1]`

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

- **JSON HAL Standard (Recommended)**: Collections SHOULD return a JSON HAL object envelope with `application/hal+json` Content-Type to prevent JSON Hijacking and allow embedded pagination metadata. `[T1]`
- **Envelope Structure**:
  - `_links` (hypermedia links: `self`, `next`, `prev`, `first`, `last`) `[T1]`
  - `_embedded` (wrapping the array of resources under a resource-specific key, e.g., `"articles"`) `[T1]`
  - Top-level attributes are used for custom page/total count metadata (e.g., `totalCount`, `pageSize`). `[T1]`
- **Legacy Array Support**: Backwards-compatible implementations may return a top-level JSON array `[]` alongside `Link` (RFC 8288) and `Total-Count` headers. `[T1]`
- **Content Negotiation Fallback**: If the client explicitly requests `Accept: application/json` instead of `application/hal+json`, the server MAY return a simplified flat JSON envelope (e.g., `{"items": [...], "totalCount": N}`) to reduce client-side parsing overhead. `[T2]`
- **Empty collections**: return `200 OK` with an empty collection representation (e.g., `_embedded: { "articles": [] }` and `totalCount: 0`) — never `404`. `[T1]`

### API Surface Contract — Pagination Methods

#### Token-based Pagination (AIP-158, Recommended) `[T2]`

Uses an opaque token (`pageToken`). Clients MUST NOT parse the internal structure of the token or generate it directly.

**Parameters:**
- `pageSize` — Number of items per page (default 20, max 100)
- `pageToken` — The `nextPageToken` value from the previous response (omit for the first page)

**Request/Response Flow (JSON HAL Standard):**

```
# 첫 페이지
GET /articles?pageSize=20

200 OK
Content-Type: application/hal+json

{
  "_links": {
    "self": { "href": "https://api.example.com/articles?pageSize=20" },
    "next": { "href": "https://api.example.com/articles?pageSize=20&pageToken=eyJpZCI6MjB9" }
  },
  "_embedded": {
    "articles": [
      {
        "id": "1",
        "_links": { "self": { "href": "/articles/1" } },
        "title": "Article 1"
      },
      {
        "id": "2",
        "_links": { "self": { "href": "/articles/2" } },
        "title": "Article 2"
      }
    ]
  },
  "totalCount": 58,
  "pageSize": 20
}
```

```
# 다음 페이지
GET /articles?pageSize=20&pageToken=eyJpZCI6MjB9

200 OK
Content-Type: application/hal+json

{
  "_links": {
    "self": { "href": "https://api.example.com/articles?pageSize=20&pageToken=eyJpZCI6MjB9" },
    "next": { "href": "https://api.example.com/articles?pageSize=20&pageToken=eyJpZCI6NDB9" },
    "first": { "href": "https://api.example.com/articles?pageSize=20" }
  },
  "_embedded": {
    "articles": [
      {
        "id": "21",
        "_links": { "self": { "href": "/articles/21" } },
        "title": "Article 21"
      }
    ]
  },
  "totalCount": 58,
  "pageSize": 20
}
```

```
# 마지막 페이지 — next 링크 없음
GET /articles?pageSize=20&pageToken=eyJpZCI6NDB9

200 OK
Content-Type: application/hal+json

{
  "_links": {
    "self": { "href": "https://api.example.com/articles?pageSize=20&pageToken=eyJpZCI6NDB9" },
    "first": { "href": "https://api.example.com/articles?pageSize=20" }
  },
  "_embedded": {
    "articles": [
      {
        "id": "41",
        "_links": { "self": { "href": "/articles/41" } },
        "title": "Article 41"
      }
    ]
  },
  "totalCount": 58,
  "pageSize": 20
}
```

**Rules:**
- Clients MUST NOT parse or directly generate `pageToken` — only use the value returned by the server `[T2]`
- `pageSize < 1` → `400 Bad Request`; `pageSize > max` → cap at max (no error) `[T2]`
- Omit `_links.next` if there is no next page `[T2]`

**Server Implementation Notes (Do not expose to clients):**

Encoding sorting keys (keyset) inside the token is recommended. Do not use OFFSET queries (`OFFSET N LIMIT 20`) due to O(N) performance degradation on deep pages.

```sql
-- Inside pageToken: { "createdAt": "2024-06-15T10:30:00Z", "id": 20 } → Base64 Encoded
SELECT * FROM articles
WHERE (created_at, id) < ('2024-06-15T10:30:00Z', 20)  -- keyset condition
ORDER BY created_at DESC, id DESC
LIMIT 21  -- pageSize + 1 (to check for next page existence)
-- If result count is 21, remove the last item and generate next pageToken.
-- If result count is less than 21, next pageToken is not provided.
```

#### Offset-based Pagination (Small datasets only) `[T2]`

Use only when random page access is required (e.g., admin UI) and the dataset contains fewer than 10,000 items.

- `page` + `pageSize` parameters
- Risk of performance degradation and duplicate/missing data during pagination when data is inserted/deleted

### Pagination Selection Criteria

```
Random page access required AND data < 10,000 items?
  └─ Yes → Offset (page + pageSize)
  └─ No  → Token-based (pageToken + pageSize, AIP-158) ← Default Recommended
```

**Different endpoints in the same API can use different strategies. However, providing both strategies on the same endpoint is prohibited.**

## Filtering & Sorting

- **Filter expression (AIP-160):** Use the `filter` query parameter with a structured expression string for complex query criteria (AND/OR, inequality operators). `[T1]`
- **Simple equality filters:** For simple 1:1 equality filtering (e.g., matching a single exact status), APIs MAY support direct query parameters (e.g., `?status=ACTIVE`) as a lightweight alternative to reduce parsing overhead on basic CRUD tasks. `[T1]`
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
- **Vary on Versioning:** All APIs implementing Header Versioning MUST include `Vary: Api-Version` (and `Accept` if content negotiation is used) in their responses to prevent CDN/proxy cache pollution. `[T1]`

## Long-Running Operations

- Return `201 Created` + `Location` header with domain resource immediately `[T3]`
- Include `status` field: `PENDING` → `IN_PROGRESS` → `COMPLETED` | `FAILED` `[T3]`
- Client polls `GET {Location}` to check progress `[T3]`
- On failure: include error details in response body `[T3]`

## Idempotency-Key (AIP-155)

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

---

## References

Standards this guideline draws from. Inline `(AIP-xxx)` / RFC tags mark each rule's source; this table is the crosswalk to the full specifications.

### Google AIP (API Improvement Proposals — https://google.aip.dev)

| Standard | Title | Applied in |
|----------|-------|-----------|
| AIP-121 | Resource-oriented design | URL Design, CRUD Behavior, Resource Schema |
| AIP-134 | Standard methods: Update | CRUD Behavior (PATCH / `updateMask`) |
| AIP-136 | Custom methods | Actions |
| AIP-154 | Resource freshness validation (etag) | Optimistic Concurrency Control |
| AIP-155 | Request idempotency | Idempotency-Key |
| AIP-157 | Partial responses | Partial Response |
| AIP-158 | Pagination | Collections & Pagination |
| AIP-160 | Filtering | Filtering & Sorting |
| AIP-163 | Change validation (dry run) | Change Validation / Dry Run |
| AIP-164 | Soft delete | Soft Delete |
| AIP-193 | Errors | Error Response |
| AIP-203 | Field behavior | Resource Schema & Field Rules |
| AIP-216 | Resource lifecycle states | State Enum Pattern |

### RFC / Web standards

| Standard | Title | Applied in |
|----------|-------|-----------|
| RFC 2119 / 8174 | Requirement keywords (MUST/SHOULD/MAY) | Document-wide |
| RFC 3339 | Date and Time on the Internet | JSON Format |
| RFC 6648 / BCP 178 | Deprecating the `X-` header prefix | Headers, API Versioning |
| RFC 7396 | JSON Merge Patch | JSON Format, CRUD Behavior |
| RFC 7807 / 9457 | Problem Details for HTTP APIs | Error Response |
| RFC 8288 | Web Linking (`Link` header) | Headers, Pagination |
| RFC 8594 | The Sunset HTTP header | Deprecation |
| RFC 9745 | The Deprecation HTTP header | Deprecation |
| W3C Trace Context | `traceparent` / `tracestate` propagation | Headers |
