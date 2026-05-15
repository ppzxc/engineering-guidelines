# RESTful API Guidelines

> [한국어](README.ko.md)

RESTful API design guidelines.

---

## Profile Guide

Each rule is tagged with `[T1]`, `[T2]`, or `[T3]`. When a profile is specified, only rules at that Tier or below are applied.

| Profile | Tiers Included | Target | Rule Count |
|--------|-----------|------|---------|
| **Essential** | T1 only | All APIs — from day one | ~87 |
| **Standard** | T1 + T2 | Production operation phase | ~121 |
| **Full** | T1 + T2 + T3 | Large-scale/Enterprise APIs | ~146 |

**Tier Criteria (ADR-0010):**
- **T1 (Essential):** Breaking change risk if introduced later / Security mandatory / HTTP standards / API contract fundamentals
- **T2 (Standard):** Production operation convenience, can be introduced later
- **T3 (Full):** Enterprise/Advanced patterns, domain-specific

---

## Table of Contents

1. [Overview](#1-overview)
   - [Compliance Levels](#compliance-levels)
2. [URL Design](#2-url-design)
3. [HTTP Methods & Status Codes](#3-http-methods--status-codes)
4. [Headers](#4-headers)
5. [JSON Format](#5-json-format)
6. [Error Response](#6-error-response)
7. [Resource Schema & Field Rules](#7-resource-schema--field-rules)
8. [CRUD Behavior](#8-crud-behavior)
9. [Actions](#9-actions)
10. [Collections & Pagination](#10-collections--pagination)
11. [Filtering & Sorting](#11-filtering--sorting)
12. [Partial Response & Resource Expansion](#12-partial-response--resource-expansion)
13. [Bulk Operations](#13-bulk-operations)
14. [API Versioning](#14-api-versioning)
15. [Deprecation](#15-deprecation)
16. [Rate Limiting & Retries](#16-rate-limiting--retries)
17. [Caching](#17-caching)
18. [Long-Running Operations](#18-long-running-operations)
19. [Idempotency-Key](#19-idempotency-key)
20. [OpenAPI Specification](#20-openapi-specification)
21. [Authentication & Security](#21-authentication--security)
22. [References](#22-references)

---

## 1. Overview

### Purpose

- Ensure consistency, predictability, and maintainability across all RESTful APIs.
- APIs are products consumed by developers.
  - They must be intuitively understandable.
  - They must provide clear messages when errors occur.
  - They must maintain backward compatibility across versions.
- Follows Roy Fielding's RESTful principles.
  - HATEOAS is not implemented.

### Compliance Levels

The key words "MUST", "MUST NOT", "SHOULD", "MAY", and "DO NOT" in this document are to be interpreted as described in [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119) and [RFC 8174](https://datatracker.ietf.org/doc/html/rfc8174).

| Symbol | Level | Description |
|--------|-------|-------------|
| ✅ **Required** | MUST / DO | Rules that must be followed |
| ⚠️ **Recommended** | SHOULD / MAY | Rules that should be followed when possible |
| ❌ **Prohibited** | MUST NOT / DO NOT | Patterns that must not be used |

---

## 2. URL Design

- **Resource-oriented design** — APIs are designed around resources (nouns). URL paths express resource hierarchy; behavior is expressed via HTTP methods and custom methods.
- Every resource MUST support at least GET (retrieval). `[T1]`
- Prefer **standard methods** (GET, POST, PATCH, DELETE); use custom methods only when standard methods cannot express the operation. `[T1]`
- Do not mirror database structure in API schema. `[T1]`

- **kebab-case** for path segments: `/user-profiles`, `/product-categories/123`. `[T1]`
- **Plural nouns** for collections: `/articles` not `/article`. `[T1]`
- **No verbs in resource paths** — use HTTP methods for CRUD; non-CRUD actions use `POST` with colon syntax (resource-level: `/{resource}/{id}:{action}`, collection-level: `/{resource}:{action}`). `[T1]`
- **No file extensions** (`.json`, `.xml`). `[T1]`
- **No trailing slash** — `/articles` not `/articles/`. `[T1]`
- **camelCase** for query parameters: `pageSize=20&sortOrder=desc`. `[T1]`
- ASCII lowercase letters, numerals, and hyphens only in path segments. `[T1]`
- Repeat parameter names for arrays: `?tag=tech&tag=design`. `[T1]`
- **Single sub-resource nesting** — `/{parent}/{parentId}/{child}/{childId}` e.g., `/users/42/profiles/7`. `[T2]`

**Nesting depth rule:** `[T2]`
Nest at most one sub-resource under a parent. For deeper relationships, promote to a flat top-level route.

| Situation | ✅ Do | ❌ Don't |
|-----------|-------|---------|
| Order items under an order | `/orders/{orderId}/items/{itemId}` | `/users/{userId}/orders/{orderId}/items/{itemId}` |
| Reviews on an order item | `/order-items/{orderItemId}/reviews/{reviewId}` | `/users/{userId}/orders/{orderId}/items/{itemId}/reviews/{reviewId}` |

---

## 3. HTTP Methods & Status Codes

| Method | Purpose | Idempotent | Safe |
|--------|---------|-----------|------|
| GET | Retrieve | Yes | Yes |
| POST | Create / execute custom method | No | No |
| PUT | Full content replacement (file/binary upload) | Yes | No |
| PATCH | Partial update (default update method) | No | No |
| DELETE | Remove | Yes | No |
| HEAD | Retrieve metadata only (no body) | Yes | Yes |
| OPTIONS | Retrieve allowed methods/CORS info | Yes | Yes |

- **HEAD:** Clients SHOULD use HEAD to check resource existence or last-modified time without downloading the full body. `[T2]`
- **OPTIONS:** Servers MUST support OPTIONS for CORS preflight and SHOULD use it to describe supported methods via the `Allow` header. `[T2]`
- GET, HEAD, DELETE must not include request bodies. `[T1]`

**2xx Success:**
- `200 OK` — standard success. `[T1]`
- `201 Created` — creation success; include `Location` header with new resource URL. `[T1]`
- `202 Accepted` — request accepted, processing not complete; used for async or deferred operations. `[T2]`
- `204 No Content` — success with no body (DELETE, etc.). `[T1]`

**4xx Client Error:**
- `400 Bad Request` — malformed request, validation failure. `[T1]`
- `401 Unauthorized` — missing/expired authentication. `[T1]`
- `403 Forbidden` — authenticated but not authorized. `[T1]`
- `404 Not Found` — resource doesn't exist. `[T1]`
- `409 Conflict` — duplicate resource (same ID or unique constraint violation). `[T1]`
- `412 Precondition Failed` — `If-Match` etag mismatch (conditional request failed). `[T1]`
- `422 Unprocessable Entity` — semantic validation failure. `[T1]`
- `429 Too Many Requests` — rate limit exceeded. `[T1]`

**5xx Server Error:**
- `500 Internal Server Error` — unexpected failure. `[T1]`
- `503 Service Unavailable` — temporary unavailability. `[T1]`

---

## 4. Headers

- `Content-Type: application/json` for bodies. `[T1]`
- `Accept: application/json` for content negotiation. `[T1]`
- `Location` header on 201 Created. `[T1]`
- `Total-Count` for collection size. `[T2]`
- RFC 8288 `Link` header for pagination. `[T2]`
- **No `X-` prefix on custom headers** (RFC 6648) — All new APIs MUST define custom headers without this prefix. `[T1]`
- `Cache-Control` header specifies caching strategy. `[T2]`
- `Request-Id` header — server MUST include a unique request identifier (UUID v4) in every response. `[T1]`
- `ETag` — opaque string representing the resource version; server includes in responses. `[T1]`
- `If-Match` — client sends etag value on Update/Delete requests for optimistic concurrency control. `[T1]`

---

## 5. JSON Format

- **camelCase** field names: `userId`, `createdAt`, `isActive`. `[T1]`
- Never snake_case or abbreviations. `[T1]`
- Omit null/missing fields entirely (do not send `"field": null`). `[T1]`
- Date/time values as RFC 3339 strings; server responses in UTC (`Z`). `[T1]`
- Standard resource fields: `id`, `createdAt` (create-only), `updatedAt` (read-only). `[T1]`
- Servers must ignore read-only fields in request bodies. `[T1]`

**State Enum Pattern (AIP-216):** `[T1]`
- State field name MUST be `state` (not `status`).
- First enum value MUST always be `STATE_UNSPECIFIED`.
- `state` is OUTPUT_ONLY — state transitions via custom methods only.

---

## 6. Error Response

✅ **Required**: All error responses MUST follow RFC 7807 / RFC 9457 standard and use `application/problem+json`.

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
    }
  ]
}
```

- **Machine-readable code:** Include a `code` string field (UPPER_SNAKE_CASE). `[T1]`
- **Field-level errors (AIP-193 style):** Include a `details` array with polymorphic objects. `[T1]`
- Include **all** validation failures at once. `[T1]`
- `traceId` MUST match the `Request-Id` response header. `[T1]`
- Never expose internal implementation details. `[T1]`

---

## 7. Resource Schema & Field Rules

**Field Behavior Annotations (AIP-203):** `[T1]`
Declare behavior in OpenAPI schema using `x-field-behavior`.

| Annotation | Meaning |
|-----------|---------|
| `REQUIRED` | Client must provide |
| `OUTPUT_ONLY` | Set by server; client must not provide |
| `INPUT_ONLY` | Client-provided; excluded from response |
| `IMMUTABLE` | Cannot change after creation |
| `OPTIONAL` | Optionally provided |
| `IDENTIFIER` | Resource identifier; cannot change |

---

## 8. CRUD Behavior

**Standard method response rules:**
- POST (Create): return `201` with full resource + `Location` header. `[T1]`
- PATCH (Update): return the updated full resource. `[T1]`
- DELETE: return `204` with no body. `[T1]`

**PATCH (Update — default):** `[T1]`
- `updateMask` query parameter is REQUIRED: comma-separated field paths — `?updateMask=title,content`.
- Only modify fields specified by `updateMask`.
- Empty mask or unknown field path → `400 Bad Request`.

**Optimistic Concurrency Control (AIP-154):** `[T1]`
- Include an `etag` field in the resource (OUTPUT_ONLY).
- Pass etag via `If-Match: {etag}` header on Update/Delete requests.
- Etag mismatch → return `412 Precondition Failed`.

---

## 9. Actions

**Non-CRUD actions (AIP-136):** `[T1]`
Use `POST` with colon syntax for operations that carry side-effects.

```
POST /orders/{id}:cancel
POST /reports:generate
```

---

## 10. Collections & Pagination

- Collections return **top-level JSON array** `[]`. `[T1]`
- **Empty collections**: return `200 OK` + `[]` — never `404`. `[T1]`

**Token-based Pagination (AIP-158, Recommended):** `[T2]`
- Use `pageSize` and `pageToken` (opaque token).
- Link header with `rel="next"`, `prev`, `first`.

---

## 11. Filtering & Sorting

❌ Do not use individual query parameters for filtering.

**Filter expression (AIP-160):** `[T1]`
- Syntax: `?filter=status = "ACTIVE" AND price >= 1000`.
- Operators: `=`, `!=`, `<`, `>`, `<=`, `>=`, `AND`, `OR`, `NOT`, `has()`.
- Invalid filter expression → `400 Bad Request`.

**Sorting:** `?orderBy=createdAt:desc,title:asc`. `[T2]`

---

## 12. Partial Response & Resource Expansion

**Partial Response (AIP-157):** `[T2]`
- Use `fields` query parameter: `?fields=id,title,author.name`.
- `id` is always included.

**Resource Expansion (Expand/Embed):** `[T2]`
- Use `expand` query parameter: `?expand=author`.
- **Total Entity Limit REQUIRED:** MUST enforce a hard limit (e.g., max 100 entities). `[T1]`
- Exceeding limit → `400 Bad Request`.

---

## 13. Bulk Operations

✅ **Required**: Express bulk operations as custom methods on the collection URL using colon syntax. `[T3]`
- `batchCreate`, `batchGet`, `batchUpdate`, `batchDelete`.
- Specify whether atomic or non-atomic.

---

## 14. API Versioning

❌ **URL path versioning is PROHIBITED.** `[T1]`

✅ **Header versioning is REQUIRED:** `[T1]`
```
Api-Version: 2024-01-20
```

- Requests without version header MUST receive **`400 Bad Request`**. `[T1]`
- Responses always include the applied version. `[T1]`
- Maintain previous versions for minimum 6 months. `[T2]`

---

## 15. Deprecation

- Include headers: `Deprecation: true`, `Sunset`, `Link`. `[T1]`
- Notice must be given at least 6 months before sunset. `[T1]`

---

## 16. Rate Limiting & Retries

- **Response headers:** `RateLimit: limit=N, remaining=N, reset=N`. `[T2]`
- **429 Too Many Requests:** Include `Retry-After` + RFC 9457 body. `[T2]`
- **Client retry strategy:** Exponential Backoff with Jitter. `[T2]`

---

## 17. Caching

- `Cache-Control` header. `[T2]`
- `ETag` usage for all mutable resources. `[T2]`

---

## 18. Long-Running Operations

- Return `201 Created` + `Location` header immediately. `[T3]`
- Include `status` field: `PENDING`, `IN_PROGRESS`, `COMPLETED`, `FAILED`. `[T3]`

---

## 19. Idempotency-Key

- Support `Idempotency-Key` header for risky POST endpoints. `[T3]`
- Use UUID v4. Key validity: minimum 24 hours. `[T3]`

---

## 20. OpenAPI Specification

- All APIs MUST maintain an OpenAPI 3.0+ spec (API First). `[T2]`
- `description` and `operationId` required. `[T2]`
- MUST validate spec compliance in CI using linters. `[T1]`

---

## 21. Authentication & Security

- **HTTPS Required.** `[T1]`
- **Security Headers REQUIRED:** `X-Content-Type-Options: nosniff`, `Strict-Transport-Security`. `[T1]`
- `Authorization` header for Bearer tokens or API Keys. `[T1]`

**Authorization (BOLA Prevention):** `[T1]`
- Servers MUST verify ownership/permissions for *every* specific resource access.

**Mass Assignment Prevention (BOPA):** `[T1]`
- Servers MUST use an Allowlist in DTOs. `PATCH` body/`updateMask` must not modify protected fields.

---

## 22. References

- [Google API Improvement Proposals (AIP)](https://google.aip.dev)
- [RFC 9457: Problem Details for HTTP APIs](https://datatracker.ietf.org/doc/html/rfc9457)
- [OWASP API Security Top 10](https://owasp.org/www-project-api-security/)
