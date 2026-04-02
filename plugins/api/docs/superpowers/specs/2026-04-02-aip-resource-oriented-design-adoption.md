# Google AIP Resource-Oriented Design & Custom Method Colon Syntax 도입 설계

## Context

현재 `api:restful-guidelines` 스킬은 URL 설계, HTTP 메서드, CRUD 동작 등을 가이드하고 있으나,
리소스 중심 설계(Resource-oriented design)를 명시적 최상위 원칙으로 선언하지 않고 있다.
또한 커스텀 액션은 슬래시 기반 sub-path 패턴(`POST /{resource}/{id}/{action}`)을 사용하며,
PUT과 PATCH를 동등하게 허용한다.

Google AIP(API Improvement Proposals)의 핵심 원칙을 부분적으로 도입하여:
1. 리소스 중심 설계를 가이드라인의 최상위 원칙으로 명시
2. 커스텀 액션을 콜론 구문으로 교체하여 리소스 경로와 액션을 명확히 분리
3. PATCH를 기본 수정 메서드로, PUT은 콘텐츠 전체 교체에만 예외 허용

## 도입 대상 AIP

| AIP | 주제 | 도입 수준 |
|-----|------|----------|
| AIP-121 | Resource-oriented design | 핵심 원칙 채택 |
| AIP-131 | Standard method: Get | 응답 규칙 보강 |
| AIP-132 | Standard method: List | 응답 규칙 보강 |
| AIP-133 | Standard method: Create | 중복 생성 처리, ID 지정 규칙 추가 |
| AIP-134 | Standard method: Update | PATCH 기본, PUT 예외적 사용으로 변경 |
| AIP-135 | Standard method: Delete | force/allow_missing 패턴 소개 |
| AIP-136 | Custom methods | 콜론 구문 채택 |

---

## 변경 사항

### 1. SKILL.md — URL Design 섹션

#### 1-1. 리소스 중심 설계 원칙 추가 (신규, 섹션 최상단)

URL Design 섹션 시작 부분에 다음 원칙을 추가한다:

```markdown
**Resource-oriented design** — API는 리소스(명사) 중심으로 설계한다.
URL 경로는 리소스의 계층 구조를 표현하며, 행위는 HTTP 메서드와 커스텀 메서드로 표현한다.
- 모든 리소스는 최소한 GET(조회)을 지원해야 한다
- **표준 메서드**(GET, POST, PATCH, DELETE)를 우선 사용하고,
  표현 불가능한 경우에만 커스텀 메서드를 사용한다
- API 스키마를 데이터베이스 구조와 동일하게 설계하지 않는다
```

기존 URL 설계 규칙(kebab-case, plural nouns, no file extensions 등)은 그대로 유지한다.

#### 1-2. 커스텀 액션 콜론 구문으로 교체

**변경 전:**
```
POST /{resource}/{id}/{action}     (resource-level)
POST /{resource}/{action}          (collection-level)
```

**변경 후:**
```
POST /{resource}/{id}:{action}     (resource-level)
POST /{resource}:{action}          (collection-level)
```

"No verbs in resource paths" 규칙 설명도 업데이트:
```markdown
- **No verbs in resource paths** — use HTTP methods for CRUD;
  non-CRUD actions use `POST` with colon syntax
  (resource-level: `/{resource}/{id}:{action}`,
   collection-level: `/{resource}:{action}`)
```

DO/DON'T 테이블 변경:

| Action | Do | Don't | Why |
|--------|-----|-------|-----|
| Cancel an order | `POST /orders/{id}:cancel` | `PATCH /orders/{id}` + `{"status":"cancelled"}` | Cancellation triggers refund + notification |
| Approve a review | `POST /reviews/{id}:approve` | `PUT /reviews/{id}/approval` | Approval may trigger publishing, scoring |
| Generate a report | `POST /reports:generate` | `GET /reports?generate=true` | Generation is a compute side-effect |

채택 패턴 참조 변경:
```
Adopted pattern: Google AIP-136 (`/orders/{id}:cancel`),
Google Cloud API (`/projects/{project}:setIamPolicy`).
```

호환성 주의사항 추가:
```markdown
> **Colon syntax compatibility note**: Express.js, Rails 등 `:`를 path parameter
> 구문으로 사용하는 프레임워크에서는 라우팅 설정 시 정규식 라우트 등 추가 처리가
> 필요하다. OpenAPI 명세에서 콜론 경로 지원 여부를 확인할 것.
```

### 2. SKILL.md — HTTP Methods 섹션

#### 2-1. HTTP Methods 테이블 변경

| Method | Purpose | Idempotent | Safe |
|--------|---------|-----------|------|
| GET | Retrieve | Yes | Yes |
| POST | Create / execute custom method | No | No |
| PUT | Full content replacement (파일/바이너리 등) | Yes | No |
| PATCH | Partial update (기본 수정 메서드) | No | No |
| DELETE | Remove | Yes | No |

`GET, HEAD, DELETE must not include request bodies.` 유지.

### 3. SKILL.md — CRUD Behavior 섹션

#### 3-1. 전체 교체

```markdown
## CRUD Behavior

**Standard method response rules:**
- GET: 리소스 자체를 반환한다 (Response wrapper 불필요)
- POST (Create): 생성된 리소스를 반환한다
- PATCH (Update): 업데이트된 리소스를 반환한다
- DELETE: body 없이 204를 반환한다

**POST (Create):** Return `201` with full resource + `Location` header.
- Clients SHOULD be able to specify resource ID (optional).
- Duplicate creation MUST return `409 Conflict`.

**PATCH (Update — default):** Only modify fields present in body; others unchanged.
- Response MUST return the updated full resource.
- Optionally support `updateMask` query parameter to explicitly specify fields to update.

**PUT (Content Replace — exceptional use only):** Use only when full content
replacement is semantically required (file upload, binary content, configuration
replacement). MUST NOT be used for resource attribute updates — use PATCH instead.

**DELETE:** Return `204`; re-deletion policy is per-service (404 or 204).
- Optionally support `force` parameter for cascading child resource deletion.
```

### 4. ADR 0005 신규 작성

**파일**: `docs/decisions/0005-adopt-aip-resource-oriented-design-and-colon-custom-methods.md`

MADR 형식으로 작성. 내용:
- Status: accepted
- Supersedes: ADR 0004
- Context: AIP-121/136/131~135 도입 동기
- Decision Drivers: 리소스/액션 분리, AIP 생태계 정렬, 표준 메서드 우선 원칙, PUT 역할 제한
- Considered Options:
  - A: 현상 유지 (슬래시 + PUT/PATCH 동등)
  - B: AIP 부분 도입 — 콜론 커스텀 메서드 + PATCH 기본 + PUT 예외 (채택)
  - C: AIP 전면 도입 — PUT 완전 배제 + FieldMask 필수
- Consequences: Good/Bad 분석
- 호환성 주의사항 명시 (Express.js, OpenAPI 코드 생성기)

### 5. ADR 0004 상태 변경

`docs/decisions/0004-adopt-non-crud-action-endpoint-pattern.md`의 Status를:
```
superseded by [ADR 0005](0005-adopt-aip-resource-oriented-design-and-colon-custom-methods.md)
```
로 변경.

---

## 변경하지 않는 것

- JSON Format (camelCase 유지, AIP의 snake_case 채택하지 않음)
- Error Response (RFC 7807/9457 유지, AIP-193 ErrorInfo 패턴은 미도입)
- Pagination, Filtering, Sorting (현재 가이드 유지)
- Rate Limiting, LRO, API Versioning, Deprecation (현재 가이드 유지)
- Headers, Key Principles (현재 가이드 유지)
- 평가 테스트 케이스 (이번 변경에서 업데이트하지 않음)

---

## 수정 대상 파일 요약

| 파일 | 변경 유형 |
|------|----------|
| `plugins/api/skills/restful-guidelines/SKILL.md` | URL Design, HTTP Methods, CRUD Behavior 섹션 수정 |
| `docs/decisions/0005-adopt-aip-resource-oriented-design-and-colon-custom-methods.md` | 신규 작성 |
| `docs/decisions/0004-adopt-non-crud-action-endpoint-pattern.md` | Status만 변경 |

## 검증 방법

1. SKILL.md의 변경된 섹션이 기존 가이드라인과 내부적으로 일관성 유지하는지 확인
2. ADR 0005가 MADR 형식을 따르고, ADR 0004를 올바르게 supersede하는지 확인
3. 커스텀 액션 예시가 모두 콜론 구문으로 통일되었는지 확인
4. PUT/PATCH 역할 구분이 HTTP Methods 테이블과 CRUD Behavior 섹션에서 일관되는지 확인
