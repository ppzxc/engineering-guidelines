# AIP Resource-Oriented Design & Colon Custom Methods 도입 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Google AIP-121/136/131~135 핵심 원칙을 API 플러그인의 RESTful 가이드라인에 도입한다.

**Architecture:** SKILL.md의 3개 섹션(URL Design, HTTP Methods, CRUD Behavior)을 점진적으로 수정하고, 새 ADR 0005를 작성하며, 기존 ADR 0004를 supersede 처리한다. 기존 구조를 유지하면서 해당 규칙만 교체한다.

**Tech Stack:** Markdown (MADR format)

**Spec:** `plugins/api/docs/superpowers/specs/2026-04-02-aip-resource-oriented-design-adoption.md`

---

## File Map

| 파일 | 변경 유형 | 책임 |
|------|----------|------|
| `plugins/api/skills/restful-guidelines/SKILL.md` | Modify | RESTful API 가이드라인 본문 |
| `docs/decisions/0005-adopt-aip-resource-oriented-design-and-colon-custom-methods.md` | Create | AIP 도입 의사결정 기록 |
| `docs/decisions/0004-adopt-non-crud-action-endpoint-pattern.md` | Modify (status only) | 기존 ADR supersede 처리 |

---

### Task 1: SKILL.md — URL Design 섹션에 리소스 중심 설계 원칙 추가

**Files:**
- Modify: `plugins/api/skills/restful-guidelines/SKILL.md:14-18`

- [ ] **Step 1: URL Design 섹션 최상단에 리소스 중심 설계 원칙 삽입**

`## URL Design` 바로 아래, 기존 bullet list 위에 다음 내용을 삽입한다:

```markdown
**Resource-oriented design** — API는 리소스(명사) 중심으로 설계한다. URL 경로는 리소스의 계층 구조를 표현하며, 행위는 HTTP 메서드와 커스텀 메서드로 표현한다.
- 모든 리소스는 최소한 GET(조회)을 지원해야 한다
- **표준 메서드**(GET, POST, PATCH, DELETE)를 우선 사용하고, 표현 불가능한 경우에만 커스텀 메서드를 사용한다
- API 스키마를 데이터베이스 구조와 동일하게 설계하지 않는다
```

기존 `- **kebab-case** for path segments` 부터 시작하는 bullet list는 그대로 유지한다.

- [ ] **Step 2: "No verbs" 규칙 설명 업데이트**

기존 (line 18):
```markdown
- **No verbs in resource paths** — use HTTP methods for CRUD; non-CRUD actions use `POST` with a verb sub-path (resource-level: `/{resource}/{id}/{action}`, collection-level: `/{resource}/{action}`)
```

변경 후:
```markdown
- **No verbs in resource paths** — use HTTP methods for CRUD; non-CRUD actions use `POST` with colon syntax (resource-level: `/{resource}/{id}:{action}`, collection-level: `/{resource}:{action}`)
```

- [ ] **Step 3: 변경 확인**

SKILL.md를 읽어서 URL Design 섹션 시작 부분에 리소스 중심 설계 원칙이 추가되었고, "No verbs" 규칙이 콜론 구문으로 변경되었는지 확인한다.

- [ ] **Step 4: Commit**

```bash
git add plugins/api/skills/restful-guidelines/SKILL.md
git commit -m "feat(api): URL Design 섹션에 AIP-121 리소스 중심 설계 원칙 추가 및 콜론 구문 선언"
```

---

### Task 2: SKILL.md — Non-CRUD Actions 콜론 구문으로 전면 교체

**Files:**
- Modify: `plugins/api/skills/restful-guidelines/SKILL.md:36-60`

- [ ] **Step 1: Non-CRUD actions 설명 문단 교체**

기존 (line 36~41):
```markdown
**Non-CRUD actions:**

Some operations carry side-effects that go beyond simple field updates (e.g., refunds,
notifications, state-machine transitions). Disguising them as PATCH masks intent and
couples unrelated concerns. Use `POST` with a verb sub-path to make the operation explicit.
This applies equally to collection-level operations where no specific resource identifier exists (`POST /{resource}/{action}`).
```

변경 후:
```markdown
**Non-CRUD actions:**

Some operations carry side-effects that go beyond simple field updates (e.g., refunds,
notifications, state-machine transitions). Disguising them as PATCH masks intent and
couples unrelated concerns. Use `POST` with colon syntax to make the operation explicit
and clearly separate it from the resource path.
This applies equally to collection-level operations where no specific resource identifier exists (`POST /{resource}:{action}`).
```

- [ ] **Step 2: DO/DON'T 테이블 교체**

기존 (line 43~47):
```markdown
| Action | ✅ Do | ❌ Don't | Why |
|--------|-------|---------|-----|
| Cancel an order | `POST /orders/{id}/cancel` | `PATCH /orders/{id}` with `{"status":"cancelled"}` | Cancellation triggers refund + notification — not a simple field update |
| Approve a review | `POST /reviews/{id}/approve` | `PUT /reviews/{id}/approval` | Approval may trigger publishing, scoring, or downstream workflows |
| Generate a report | `POST /reports/generate` | `GET /reports?generate=true` | Generation is a compute side-effect that may mutate state — not a safe retrieval |
```

변경 후:
```markdown
| Action | ✅ Do | ❌ Don't | Why |
|--------|-------|---------|-----|
| Cancel an order | `POST /orders/{id}:cancel` | `PATCH /orders/{id}` with `{"status":"cancelled"}` | Cancellation triggers refund + notification — not a simple field update |
| Approve a review | `POST /reviews/{id}:approve` | `PUT /reviews/{id}/approval` | Approval may trigger publishing, scoring, or downstream workflows |
| Generate a report | `POST /reports:generate` | `GET /reports?generate=true` | Generation is a compute side-effect that may mutate state — not a safe retrieval |
```

- [ ] **Step 3: 채택 패턴 참조 교체**

기존 (line 49~50):
```markdown
Adopted pattern: Stripe (`/charges/{id}/capture`), Shopify (`/orders/{id}/cancel`),
GitHub (`/pulls/{number}/merge`); collection-level: GitHub (`/repos/{owner}/{repo}/dispatches`).
```

변경 후:
```markdown
Adopted pattern: Google AIP-136 (`/orders/{id}:cancel`),
Google Cloud API (`/projects/{project}:setIamPolicy`).

> **Colon syntax compatibility note**: Express.js, Rails 등 `:`를 path parameter 구문으로 사용하는 프레임워크에서는 라우팅 설정 시 정규식 라우트 등 추가 처리가 필요하다. OpenAPI 명세에서 콜론 경로 지원 여부를 확인할 것.
```

- [ ] **Step 4: 변경 확인**

SKILL.md를 읽어서 Non-CRUD actions 전체 영역이 콜론 구문으로 일관되게 변경되었고, 호환성 주의사항이 추가되었는지 확인한다.

- [ ] **Step 5: Commit**

```bash
git add plugins/api/skills/restful-guidelines/SKILL.md
git commit -m "feat(api): Non-CRUD 액션을 AIP-136 콜론 구문으로 전면 교체"
```

---

### Task 3: SKILL.md — HTTP Methods 테이블 변경

**Files:**
- Modify: `plugins/api/skills/restful-guidelines/SKILL.md:62-72`

- [ ] **Step 1: HTTP Methods 테이블 교체**

기존 (line 64~70):
```markdown
| Method | Purpose | Idempotent | Safe |
|--------|---------|-----------|------|
| GET | Retrieve | Yes | Yes |
| POST | Create / execute | No | No |
| PUT | Full replacement | Yes | No |
| PATCH | Partial update | No | No |
| DELETE | Remove | Yes | No |
```

변경 후:
```markdown
| Method | Purpose | Idempotent | Safe |
|--------|---------|-----------|------|
| GET | Retrieve | Yes | Yes |
| POST | Create / execute custom method | No | No |
| PUT | Full content replacement (file/binary upload) | Yes | No |
| PATCH | Partial update (default update method) | No | No |
| DELETE | Remove | Yes | No |
```

- [ ] **Step 2: 변경 확인**

SKILL.md의 HTTP Methods 테이블이 올바르게 변경되었는지 확인한다.

- [ ] **Step 3: Commit**

```bash
git add plugins/api/skills/restful-guidelines/SKILL.md
git commit -m "feat(api): HTTP Methods 테이블에서 PUT/PATCH 역할 재정의"
```

---

### Task 4: SKILL.md — CRUD Behavior 섹션 교체

**Files:**
- Modify: `plugins/api/skills/restful-guidelines/SKILL.md:130-138`

- [ ] **Step 1: CRUD Behavior 섹션 전체 교체**

기존 (line 130~138):
```markdown
## CRUD Behavior

**POST (Create):** Return `201` with full resource + `Location` header.

**PUT (Full Replace):** Idempotent; omitted mutable fields reset to defaults.

**PATCH (Partial Update):** Only modify fields present in body; others unchanged.

**DELETE:** Return `204`; re-deletion policy is per-service (404 or 204).
```

변경 후:
```markdown
## CRUD Behavior

**Standard method response rules:**
- GET: return the resource itself (no Response wrapper)
- POST (Create): return the created resource
- PATCH (Update): return the updated resource
- DELETE: return `204` with no body

**POST (Create):** Return `201` with full resource + `Location` header.
- Clients SHOULD be able to specify resource ID (optional).
- Duplicate creation MUST return `409 Conflict`.

**PATCH (Update — default):** Only modify fields present in body; others unchanged.
- Response MUST return the updated full resource.
- Optionally support `updateMask` query parameter to explicitly specify fields to update.

**PUT (Content Replace — exceptional use only):** Use only when full content replacement is semantically required (file upload, binary content, configuration replacement). MUST NOT be used for resource attribute updates — use PATCH instead.

**DELETE:** Return `204`; re-deletion policy is per-service (404 or 204).
- Optionally support `force` parameter for cascading child resource deletion.
```

- [ ] **Step 2: 변경 확인**

SKILL.md의 CRUD Behavior 섹션이 올바르게 교체되었는지 확인한다. 특히:
- Standard method response rules가 추가되었는지
- POST에 duplicate creation 규칙이 있는지
- PATCH가 default update method로 명시되었는지
- PUT이 exceptional use only로 제한되었는지
- DELETE에 force 옵션이 추가되었는지

- [ ] **Step 3: Commit**

```bash
git add plugins/api/skills/restful-guidelines/SKILL.md
git commit -m "feat(api): CRUD Behavior를 AIP-131~135 표준 메서드 규칙으로 보강"
```

---

### Task 5: ADR 0005 신규 작성

**Files:**
- Create: `docs/decisions/0005-adopt-aip-resource-oriented-design-and-colon-custom-methods.md`

- [ ] **Step 1: ADR 0005 파일 작성**

다음 내용으로 파일을 생성한다:

```markdown
# Adopt AIP Resource-Oriented Design and Colon Custom Methods

## Status

accepted

Supersedes [ADR 0004](0004-adopt-non-crud-action-endpoint-pattern.md)

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
* RFC 3986 표준 준수 — path segment 내 콜론은 명시적으로 허용되는 문자

## Considered Options

* Option A: 현상 유지 — 슬래시 패턴 + PUT/PATCH 동등 허용
* Option B: AIP 부분 도입 — 콜론 커스텀 메서드 + PATCH 기본 + PUT 예외 허용
* Option C: AIP 전면 도입 — PUT 완전 배제 + FieldMask 필수

## Decision Outcome

Chosen option: "Option B", because 리소스/액션 분리와 PATCH 기본화의 실익을 얻으면서도,
파일 업로드 등 PUT이 의미론적으로 적합한 경우를 예외로 허용하여 실용성을 유지할 수 있기 때문이다.

### Consequences

* Good: 커스텀 액션이 리소스 경로와 시각적으로 분리됨 — `/orders/{id}:cancel`
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
```

- [ ] **Step 2: 변경 확인**

ADR 0005 파일이 MADR 형식을 올바르게 따르고, Supersedes 참조가 정확한지 확인한다.

- [ ] **Step 3: Commit**

```bash
git add docs/decisions/0005-adopt-aip-resource-oriented-design-and-colon-custom-methods.md
git commit -m "docs(decisions): ADR 0005 — AIP 리소스 중심 설계 및 콜론 커스텀 메서드 도입"
```

---

### Task 6: ADR 0004 상태를 superseded로 변경

**Files:**
- Modify: `docs/decisions/0004-adopt-non-crud-action-endpoint-pattern.md:3-5`

- [ ] **Step 1: ADR 0004의 Status 변경**

기존 (line 3~5):
```markdown
## Status

accepted
```

변경 후:
```markdown
## Status

superseded by [ADR 0005](0005-adopt-aip-resource-oriented-design-and-colon-custom-methods.md)
```

- [ ] **Step 2: 변경 확인**

ADR 0004의 Status가 올바르게 변경되었고, ADR 0005로의 링크가 정확한지 확인한다.

- [ ] **Step 3: Commit**

```bash
git add docs/decisions/0004-adopt-non-crud-action-endpoint-pattern.md
git commit -m "docs(decisions): ADR 0004 상태를 superseded by ADR 0005로 변경"
```

---

### Task 7: 최종 검증

- [ ] **Step 1: SKILL.md 전체 일관성 확인**

SKILL.md를 전체 읽어서 다음을 확인한다:
- URL Design 섹션에 리소스 중심 설계 원칙이 있는지
- 모든 커스텀 액션 예시가 콜론 구문(`:{action}`)인지 (슬래시 패턴 잔재 없는지)
- HTTP Methods 테이블의 PUT/PATCH 설명이 CRUD Behavior 섹션과 일관되는지
- "No verbs" 규칙이 콜론 구문을 참조하는지

- [ ] **Step 2: ADR 문서 간 참조 확인**

- ADR 0005의 Supersedes가 ADR 0004를 정확히 가리키는지
- ADR 0004의 Status가 ADR 0005를 정확히 가리키는지
- 상대 경로 링크가 올바른지

- [ ] **Step 3: 슬래시 패턴 잔재 검색**

```bash
grep -n "/{action}" plugins/api/skills/restful-guidelines/SKILL.md
grep -n "/{id}/" plugins/api/skills/restful-guidelines/SKILL.md
```

커스텀 액션 관련 슬래시 패턴이 남아있지 않은지 확인한다. Nesting depth 테이블의 리소스 경로(`/orders/{orderId}/items/{itemId}`)는 표준 리소스 중첩이므로 정상이다.

- [ ] **Step 4: 최종 Commit (필요시)**

잔재가 발견되면 수정 후 커밋한다:

```bash
git add plugins/api/skills/restful-guidelines/SKILL.md
git commit -m "fix(api): 슬래시 패턴 잔재 정리"
```
