# Pagination & Filtering Enhancement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** README.md의 페이지네이션 & 필터링 가이드라인을 심화하고, SKILL.md에 동기화하며, 평가 시스템을 업데이트한다.

**Architecture:** 기존 5.2/5.3 섹션 구조를 유지하면서 내부에 규칙을 추가하고, 5.8~5.10 placeholder 섹션을 추가한다. README.md(영문) → README.ko.md(한글) → SKILL.md(압축) → 평가 시스템 순서로 작업한다.

**Tech Stack:** Markdown 문서, Git

**Spec:** `plugins/api/docs/superpowers/specs/2026-03-31-pagination-filtering-enhancement-design.md`

---

## File Map

| File | Action | Responsibility |
|------|--------|---------------|
| `plugins/api/README.md` | Modify (lines 20-49, 670-815, 1017-1135) | 영문 가이드라인 원본 — ToC, 5.2, 5.3, 새 섹션, References |
| `plugins/api/README.ko.md` | Modify (lines 21-50, 693-849, 1050-1170) | 한국어 가이드라인 — README.md와 동일 구조 |
| `plugins/api/skills/restful-guidelines/SKILL.md` | Modify (lines 95-170) | SKILL 압축 반영 |
| `plugins/api/docs/evaluation/coverage-map.md` | Modify (lines 88-108) | 신규 규칙 매핑 행 추가 |
| `plugins/api/docs/evaluation/test-cases.md` | Modify (EOF 부근) | 신규 bad/good 테스트 케이스 추가 |
| `plugins/api/docs/evaluation/report.md` | Modify (lines 10-17, 219) | 규칙 총 수 및 커버리지 수치 업데이트 |

---

### Task 1: README.md — 5.3 Filtering에 Min/Max 숫자 범위 필터 추가

**Files:**
- Modify: `plugins/api/README.md:772-801`

> 참고: README.ko.md에는 이미 Min/Max가 있음 (lines 800-810). README.md에만 누락.

- [ ] **Step 1: Range filter 섹션 뒤에 Numeric range filter 추가**

`plugins/api/README.md`의 5.3 Filtering 섹션에서 Range filter 블록(After/Before) 바로 뒤, Multi-value filter 앞에 삽입:

```markdown
**Numeric range filter:** Use `Min`/`Max` suffixes.

```
GET /products?priceMin=100&priceMax=500
GET /articles?viewCountMin=1000
```

⚠️ **Recommended**: Use `After`/`Before` suffixes for date/time ranges and `Min`/`Max` suffixes for numeric ranges.
```

구체적 위치: README.md에서 아래 텍스트를 찾아서 그 앞에 삽입:

```
**Multi-value filter (IN):** Repeat the same parameter for OR conditions.
```

- [ ] **Step 2: 변경 확인**

Run: `grep -n "Min\|Max\|Numeric range" plugins/api/README.md`
Expected: Numeric range filter 섹션이 5.3 내에 존재

- [ ] **Step 3: Commit**

```bash
git add plugins/api/README.md
git commit -m "docs(api): README.md 5.3에 Min/Max 숫자 범위 필터 추가"
```

---

### Task 2: README.md — 5.2 Collections and Pagination 보강

**Files:**
- Modify: `plugins/api/README.md:670-757`

- [ ] **Step 1: 빈 컬렉션 응답 규칙 추가**

5.2 섹션에서 "Collection Response Structure" 하위 섹션의 rel value 테이블 바로 뒤, "Cursor-Based Pagination" 바로 앞에 새 하위 섹션 삽입:

```markdown
#### Empty Collection Response

✅ **Required**: Return `200 OK` with an empty array `[]` when a collection has no items. Do not return `404 Not Found` for empty collections.

⚠️ **Recommended**: Include the `Total-Count: 0` header for empty collections.

```
HTTP/1.1 200 OK
Content-Type: application/json
Total-Count: 0

[]
```

> **Note**: A collection endpoint always exists as a resource even when empty ([RFC 9110](https://datatracker.ietf.org/doc/html/rfc9110)). `404 Not Found` indicates the endpoint itself does not exist, not that the collection is empty.
```

위치: 아래 텍스트 바로 앞에 삽입:

```
#### Cursor-Based Pagination (Recommended)
```

- [ ] **Step 2: pageSize 검증 규칙 추가**

"Offset-Based Pagination" 하위 섹션 끝, 기존 `pageSize` 기본값/최대값 규칙 바로 뒤에 추가:

```markdown
✅ **Required**: Return `400 Bad Request` when `pageSize` is less than 1.

⚠️ **Recommended**: When `pageSize` exceeds the maximum allowed value, cap it to the maximum rather than returning an error. Include the applied `pageSize` in the response.

```
# Request: pageSize=500 (max is 100)
# Server applies pageSize=100

HTTP/1.1 200 OK
Link: <https://api.example.com/articles?pageSize=100&pageToken=abc>; rel="next"

[ ... 100 items ... ]
```
```

위치: `⚠️ **Recommended**: Limit the maximum page size to 100.` 바로 뒤에 추가.

- [ ] **Step 3: Cursor 불투명성 규칙 추가**

"Cursor-Based Pagination (Recommended)" 하위 섹션 끝, `rel="next"` 제외 규칙 바로 뒤에 추가:

```markdown
✅ **Required**: `pageToken` is an opaque value. Clients MUST NOT parse, construct, or make assumptions about its internal format.

✅ **Required**: Servers MAY change the encoding of `pageToken` at any time without notice.

> **Note**: This follows the same principle as resource identifiers — opaque strings that clients must not depend on structurally.
```

위치: `✅ **Required**: Exclude `rel="next"` from the `Link` header when there is no next page.` 바로 뒤에 추가.

- [ ] **Step 4: Keyset Pagination 하위 섹션 추가**

"Offset-Based Pagination" 하위 섹션 끝 (pageSize 검증 규칙 뒤), 5.3 Filtering 섹션 시작 (`---`) 바로 앞에 새 하위 섹션 삽입:

```markdown
#### Keyset Pagination

⚠️ **Recommended**: Use keyset pagination for large datasets where consistent performance is critical.

Keyset pagination uses the last item's sort key as a cursor, achieving O(1) lookup regardless of page depth.

**Request:**

```
GET /articles?pageSize=20&orderBy=createdAt:desc&after=eyJjcmVhdGVkQXQiOi...
```

**Response:**

```
HTTP/1.1 200 OK
Link: <https://api.example.com/articles?pageSize=20&orderBy=createdAt:desc&after=eyJjcmVhdGVkQXQiOi...>; rel="next"

[
  { "id": "455", "createdAt": "2024-01-20T09:55:00Z" },
  ...
  { "id": "440", "createdAt": "2024-01-15T08:00:00Z" }
]
```

✅ **Required**: The keyset cursor (`after`/`before`) MUST be an opaque token — clients must not construct it manually.

⚠️ **Recommended**: Encode compound sort keys into the opaque cursor.

> **Trade-off**: Keyset pagination cannot jump to arbitrary pages. Use offset pagination when random page access is required.
```

위치: pageSize 검증 규칙 뒤, `---` (5.3 시작 구분선) 바로 앞.

- [ ] **Step 5: 변경 확인**

Run: `grep -n "Empty Collection\|pageSize.*less than\|opaque value\|Keyset Pagination" plugins/api/README.md`
Expected: 4개 섹션 모두 5.2 내에 존재

- [ ] **Step 6: Commit**

```bash
git add plugins/api/README.md
git commit -m "docs(api): README.md 5.2 페이지네이션 규칙 보강

- 빈 컬렉션 응답 규칙 (200 OK + [] + RFC 9110 참조)
- pageSize 범위 검증 규칙
- Cursor(pageToken) 불투명성 규칙
- Keyset Pagination 패턴"
```

---

### Task 3: README.md — 5.8~5.10 Placeholder 섹션 및 ToC 업데이트

**Files:**
- Modify: `plugins/api/README.md:20-49` (ToC)
- Modify: `plugins/api/README.md:1017-1019` (5.7 뒤, 6 앞)

- [ ] **Step 1: ToC에 5.8~5.10 항목 추가**

`plugins/api/README.md`의 Table of Contents에서 `[Long-Running Operations]` 항목 뒤에 추가:

```markdown
   - [Partial Response](#58-partial-response)
   - [Expand/Embed](#59-expandembed)
   - [Bulk Operations](#510-bulk-operations)
```

위치: `   - [Long-Running Operations](#57-long-running-operations)` 바로 뒤에 추가.

- [ ] **Step 2: 5.7 Long-Running Operations 섹션 뒤에 Placeholder 섹션 추가**

`plugins/api/README.md`에서 5.7 섹션의 마지막 줄 (`❌ **Prohibited**: Do not use a separate generic `/operations` resource...`) 뒤의 `---` 바로 뒤에 삽입:

```markdown

### 5.8 Partial Response

> 🚧 Coming soon

---

### 5.9 Expand/Embed

> 🚧 Coming soon

---

### 5.10 Bulk Operations

> 🚧 Coming soon

---
```

위치: 5.7 섹션 끝 `---` 뒤, `## 6. Authentication & Security` 앞.

- [ ] **Step 3: References에 RFC 9110 추가**

`plugins/api/README.md`의 References 섹션에 이미 `RFC 9110: HTTP Semantics`가 있는지 확인. 있으면 생략. 없으면 추가:

```markdown
- [RFC 9110: HTTP Semantics](https://datatracker.ietf.org/doc/html/rfc9110)
```

Run: `grep "RFC 9110" plugins/api/README.md`

- [ ] **Step 4: 변경 확인**

Run: `grep -n "Partial Response\|Expand/Embed\|Bulk Operations\|5\.8\|5\.9\|5\.10" plugins/api/README.md`
Expected: ToC에 3항목 + 본문에 3개 placeholder 섹션

- [ ] **Step 5: Commit**

```bash
git add plugins/api/README.md
git commit -m "docs(api): README.md 5.8~5.10 placeholder 섹션 및 ToC 추가"
```

---

### Task 4: README.ko.md — 영문 README와 동일 변경 적용 (한국어)

**Files:**
- Modify: `plugins/api/README.ko.md:21-50` (목차)
- Modify: `plugins/api/README.ko.md:693-849` (5.2, 5.3)
- Modify: `plugins/api/README.ko.md:1050 부근` (5.7 뒤)

> 참고: README.ko.md에는 이미 Min/Max 숫자 범위 필터가 있으므로 (lines 800-810) 해당 항목은 건너뜀.

- [ ] **Step 1: 5.2 컬렉션 및 페이지네이션 — 빈 컬렉션 응답 추가**

README.ko.md의 rel 값 테이블 뒤, "커서 기반 페이지네이션" 앞에 삽입:

```markdown
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
```

- [ ] **Step 2: 5.2 커서 기반 페이지네이션 — Cursor 불투명성 추가**

`✅ **필수**: 다음 페이지가 없을 때 `Link` 헤더에서 `rel="next"`를 제외한다.` 뒤에 추가:

```markdown
✅ **필수**: `pageToken`은 불투명한 값이다. 클라이언트는 `pageToken`을 파싱하거나, 직접 조합하거나, 내부 형식에 대해 가정해서는 안 된다.

✅ **필수**: 서버는 `pageToken`의 인코딩을 사전 고지 없이 변경할 수 있다.

> **참고**: 이는 리소스 식별자의 불투명성 원칙과 동일하다 — 클라이언트가 구조적으로 의존해서는 안 되는 불투명한 문자열.
```

- [ ] **Step 3: 5.2 오프셋 기반 페이지네이션 — pageSize 검증 추가**

`⚠️ **권장**: 최대 페이지 크기는 100으로 제한한다.` 뒤에 추가:

```markdown
✅ **필수**: `pageSize`가 1 미만이면 `400 Bad Request`를 반환한다.

⚠️ **권장**: `pageSize`가 최대 허용값을 초과하면 에러 대신 최대값으로 자른다. 적용된 `pageSize`를 응답에 포함한다.

```
# 요청: pageSize=500 (최대값 100)
# 서버가 pageSize=100으로 적용

HTTP/1.1 200 OK
Link: <https://api.example.com/articles?pageSize=100&pageToken=abc>; rel="next"

[ ... 100개 항목 ... ]
```
```

- [ ] **Step 4: 5.2에 키셋 페이지네이션 하위 섹션 추가**

pageSize 검증 규칙 뒤, `---` (5.3 시작 구분선) 앞에 삽입:

```markdown
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
```

- [ ] **Step 5: 목차에 5.8~5.10 추가**

`   - [장기 실행 작업](#57-장기-실행-작업)` 뒤에 추가:

```markdown
   - [Partial Response](#58-partial-response)
   - [Expand/Embed](#59-expandembed)
   - [Bulk Operations](#510-bulk-operations)
```

- [ ] **Step 6: 5.7 뒤에 Placeholder 섹션 추가**

5.7 장기 실행 작업 섹션 끝 `---` 뒤, `## 6. 인증 및 보안` 앞에 삽입:

```markdown

### 5.8 Partial Response

> 🚧 Coming soon

---

### 5.9 Expand/Embed

> 🚧 Coming soon

---

### 5.10 Bulk Operations

> 🚧 Coming soon

---
```

- [ ] **Step 7: 변경 확인**

Run: `grep -n "빈 컬렉션\|불투명\|키셋\|Partial Response" plugins/api/README.ko.md`
Expected: 4개 신규 항목 모두 존재

- [ ] **Step 8: Commit**

```bash
git add plugins/api/README.ko.md
git commit -m "docs(api): README.ko.md 페이지네이션 심화 및 placeholder 추가

README.md 변경사항의 한국어 반영:
- 빈 컬렉션 응답, pageSize 검증, Cursor 불투명성
- 키셋 페이지네이션, 5.8~5.10 placeholder"
```

---

### Task 5: SKILL.md — 신규 규칙 압축 반영

**Files:**
- Modify: `plugins/api/skills/restful-guidelines/SKILL.md:95-170`

> 참고: Min/Max는 SKILL.md에 이미 존재하므로 추가 불필요.

- [ ] **Step 1: Filtering & Sorting 섹션 뒤에 Pagination 규칙 추가**

`plugins/api/skills/restful-guidelines/SKILL.md`의 "Filtering & Sorting" 섹션 뒤, "Rate Limiting" 섹션 앞에 새 섹션 삽입:

```markdown
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
```

위치: `## Rate Limiting` 바로 앞에 삽입.

- [ ] **Step 2: 기존 Headers 섹션에서 중복되는 pagination 관련 내용 확인**

SKILL.md의 기존 Headers 섹션에 `Total-Count for collection size`와 `RFC 8288 Link header for pagination` 내용이 있음. Pagination 섹션에서 상세하게 다루므로 Headers 섹션의 해당 항목은 유지 (간단한 포인터 역할).

- [ ] **Step 3: 변경 확인**

Run: `grep -n "Pagination\|opaque\|Keyset\|Empty collections" plugins/api/skills/restful-guidelines/SKILL.md`
Expected: Pagination 섹션 내 모든 항목 존재

- [ ] **Step 4: Commit**

```bash
git add plugins/api/skills/restful-guidelines/SKILL.md
git commit -m "docs(api): SKILL.md에 Pagination 섹션 추가

README.md 신규 규칙 압축 반영:
- 빈 컬렉션 응답, pageSize 검증, Cursor 불투명성
- Keyset Pagination 패턴"
```

---

### Task 6: 평가 시스템 — coverage-map.md 업데이트

**Files:**
- Modify: `plugins/api/docs/evaluation/coverage-map.md:88-108`

- [ ] **Step 1: 섹션 5 테이블에 신규 규칙 매핑 행 추가**

`plugins/api/docs/evaluation/coverage-map.md`의 섹션 5 테이블에서 `5.2-2` 행 뒤, `5.3-1` 행 앞에 신규 행 5개 삽입:

```markdown
| 5.2-3 | ✅필수 | 빈 컬렉션에 200 OK + 빈 배열 반환, 404 금지 | COVERED | COVERED | New |
| 5.2-4 | ✅필수 | pageSize < 1이면 400 Bad Request | COVERED | COVERED | New |
| 5.2-5 | ✅필수 | pageToken은 불투명 값, 클라이언트 파싱/조합 금지 | COVERED | COVERED | New |
| 5.2-6 | ⚠️권장 | 대규모 데이터셋에 Keyset Pagination 사용 | COVERED | COVERED | New |
| 5.3-0 | ⚠️권장 | 숫자 범위 필터에 Min/Max 접미사 사용 | COVERED | COVERED | New |
```

위치: `| 5.2-2 | ✅필수 | 다음 페이지 없을 때 Link 헤더에서 rel="next" 제외 |` 행 바로 뒤에 삽입.

> 주의: 5.3-0은 기존 5.3-1 앞에 위치하며, Min/Max가 README.md에 신규 추가됨을 표시. 번호 충돌을 피하기 위해 0을 사용.

- [ ] **Step 2: 커버리지 합계 섹션 수치 업데이트**

coverage-map.md의 커버리지 합계 섹션을 업데이트:

Writing 모드:
```markdown
| COVERED | 73 | 96.1% |
| PARTIAL | 0 | 0.0% |
| MISSING | 3 | 3.9% |
| **합계** | **76** | **100%** |
```

Review 모드:
```markdown
| COVERED | 73 | 96.1% |
| PARTIAL | 0 | 0.0% |
| MISSING | 3 | 3.9% |
| **합계** | **76** | **100%** |
```

전체 커버리지:
```markdown
| COVERED | 146 | 96.1% |
| PARTIAL | 0 | 0.0% |
| MISSING | 6 | 3.9% |
| **합계** | **152** | **100%** |
```

하단 참고 텍스트: `71개 규칙` → `76개 규칙`

- [ ] **Step 3: 변경 확인**

Run: `grep -n "5.2-3\|5.2-4\|5.2-5\|5.2-6\|5.3-0\|76" plugins/api/docs/evaluation/coverage-map.md`
Expected: 신규 5개 행 + 합계 76 존재

- [ ] **Step 4: Commit**

```bash
git add plugins/api/docs/evaluation/coverage-map.md
git commit -m "docs(api): coverage-map.md 신규 규칙 5개 매핑 추가 (71→76)"
```

---

### Task 7: 평가 시스템 — test-cases.md 업데이트

**Files:**
- Modify: `plugins/api/docs/evaluation/test-cases.md` (EOF 부근)

- [ ] **Step 1: 섹션 5 테스트 케이스 추가**

`plugins/api/docs/evaluation/test-cases.md` 파일 끝에 신규 테스트 케이스 5개 추가:

```markdown
---

### TC-5-03: 빈 컬렉션에 200 OK + 빈 배열 반환

- 규칙: "✅ **필수**: 컬렉션에 항목이 없을 때 `200 OK` + 빈 배열 `[]` 반환. `404 Not Found` 사용 금지"
- 규범 수준: ✅필수
- 대상 모드: Both
- 스킬 커버: Writing: COVERED / Review: COVERED

❌ Bad:
```kotlin
@RestController
@RequestMapping("/articles")
class ArticleController(private val articleService: ArticleService) {

    @GetMapping
    fun getArticles(@RequestParam status: String?): ResponseEntity<List<Article>> {
        val articles = articleService.findByStatus(status)
        if (articles.isEmpty()) {
            // 빈 컬렉션에 404 반환 — 금지
            return ResponseEntity.notFound().build()
        }
        return ResponseEntity.ok(articles)
    }
}
```

✅ Good:
```kotlin
@RestController
@RequestMapping("/articles")
class ArticleController(private val articleService: ArticleService) {

    @GetMapping
    fun getArticles(@RequestParam status: String?): ResponseEntity<List<Article>> {
        val articles = articleService.findByStatus(status)
        // 빈 컬렉션이어도 200 OK + 빈 배열 반환
        return ResponseEntity.ok()
            .header("Total-Count", articles.size.toString())
            .body(articles)
    }
}
```

- 검증 포인트: Writing 모드의 "Empty collections: return 200 OK + []" 규칙, Review 체크리스트의 "빈 컬렉션에 404 사용하지 않음" 항목

---

### TC-5-04: pageSize 범위 검증

- 규칙: "✅ **필수**: `pageSize`가 1 미만이면 `400 Bad Request` 반환"
- 규범 수준: ✅필수
- 대상 모드: Both
- 스킬 커버: Writing: COVERED / Review: COVERED

❌ Bad:
```kotlin
@GetMapping("/articles")
fun getArticles(
    @RequestParam(defaultValue = "20") pageSize: Int
): ResponseEntity<List<Article>> {
    // pageSize 검증 없이 그대로 사용 — 음수/0 허용
    val articles = articleService.findAll(pageSize)
    return ResponseEntity.ok(articles)
}
```

✅ Good:
```kotlin
@GetMapping("/articles")
fun getArticles(
    @RequestParam(defaultValue = "20") pageSize: Int
): ResponseEntity<List<Article>> {
    if (pageSize < 1) {
        throw BadRequestException("pageSize must be at least 1")
    }
    val effectivePageSize = pageSize.coerceAtMost(MAX_PAGE_SIZE)
    val articles = articleService.findAll(effectivePageSize)
    return ResponseEntity.ok()
        .header("Total-Count", articleService.count().toString())
        .body(articles)
}
```

- 검증 포인트: Writing 모드의 "pageSize < 1 → 400 Bad Request" 규칙, pageSize > max → cap 동작

---

### TC-5-05: pageToken 불투명성

- 규칙: "✅ **필수**: `pageToken`은 불투명한 값이다. 클라이언트는 파싱/조합/내부 형식 가정 금지"
- 규범 수준: ✅필수
- 대상 모드: Both
- 스킬 커버: Writing: COVERED / Review: COVERED

❌ Bad:
```kotlin
// 클라이언트 코드: pageToken 직접 조합 — 금지
val lastId = articles.last().id
val lastCreatedAt = articles.last().createdAt
val nextPageToken = "$lastCreatedAt|$lastId"  // 내부 형식 가정
val response = api.get("/articles?pageSize=20&pageToken=$nextPageToken")
```

✅ Good:
```kotlin
// 클라이언트 코드: 서버가 제공한 Link 헤더 사용
val linkHeader = response.headers["Link"]
val nextUrl = parseLinkHeader(linkHeader, "next")
if (nextUrl != null) {
    val nextResponse = api.get(nextUrl)  // 서버 제공 URL 그대로 사용
}
```

- 검증 포인트: Writing 모드의 "pageToken is an opaque value" 규칙, Review 체크리스트의 "클라이언트가 pageToken을 직접 조합하지 않음" 항목

---

### TC-5-06: Keyset Pagination 패턴

- 규칙: "⚠️ **권장**: 대규모 데이터셋에서 일관된 성능이 중요한 경우 키셋 페이지네이션 사용"
- 규범 수준: ⚠️권장
- 대상 모드: Both
- 스킬 커버: Writing: COVERED / Review: COVERED

❌ Bad:
```kotlin
// 대규모 데이터셋에서 오프셋 기반 페이지네이션 — 성능 문제
@GetMapping("/events")
fun getEvents(
    @RequestParam(defaultValue = "1") page: Int,
    @RequestParam(defaultValue = "20") pageSize: Int
): ResponseEntity<List<Event>> {
    // 100만 건 테이블에서 page=50000 → 매우 느린 OFFSET 쿼리
    val offset = (page - 1) * pageSize
    val events = eventRepository.findAll(PageRequest.of(offset, pageSize))
    return ResponseEntity.ok(events.content)
}
```

✅ Good:
```kotlin
// 대규모 데이터셋에서 키셋 기반 페이지네이션 — O(1) 성능
@GetMapping("/events")
fun getEvents(
    @RequestParam(defaultValue = "20") pageSize: Int,
    @RequestParam required: false after: String?,
    @RequestParam(defaultValue = "createdAt:desc") orderBy: String
): ResponseEntity<List<Event>> {
    val cursor = after?.let { decodeCursor(it) }
    val events = eventRepository.findAfterCursor(cursor, pageSize, orderBy)
    val nextCursor = if (events.size == pageSize) encodeCursor(events.last()) else null

    return ResponseEntity.ok()
        .header("Link", buildLinkHeader(nextCursor, pageSize, orderBy))
        .body(events)
}
```

- 검증 포인트: Writing 모드의 "Keyset: after/before opaque cursor + orderBy" 규칙, Review 체크리스트의 "대규모 데이터에 keyset 사용 여부" 항목

---

### TC-5-07: Min/Max 숫자 범위 필터

- 규칙: "⚠️ **권장**: 숫자 범위 필터에 `Min`/`Max` 접미사 사용"
- 규범 수준: ⚠️권장
- 대상 모드: Both
- 스킬 커버: Writing: COVERED / Review: COVERED

❌ Bad:
```kotlin
// 숫자 범위 필터에 일관성 없는 파라미터 이름 사용
@GetMapping("/products")
fun getProducts(
    @RequestParam(required = false) price_from: Int?,   // snake_case + 비표준 접미사
    @RequestParam(required = false) price_to: Int?      // snake_case + 비표준 접미사
): ResponseEntity<List<Product>> {
    return ResponseEntity.ok(productService.findByPriceRange(price_from, price_to))
}
```

✅ Good:
```kotlin
// 숫자 범위 필터에 Min/Max 접미사 + camelCase 사용
@GetMapping("/products")
fun getProducts(
    @RequestParam(required = false) priceMin: Int?,
    @RequestParam(required = false) priceMax: Int?
): ResponseEntity<List<Product>> {
    return ResponseEntity.ok(productService.findByPriceRange(priceMin, priceMax))
}
```

- 검증 포인트: Writing 모드의 "Numeric range: Min/Max suffix" 규칙, Review 체크리스트의 "숫자 범위 필터에 Min/Max 접미사 사용" 항목
```

- [ ] **Step 2: 변경 확인**

Run: `grep -n "TC-5-03\|TC-5-04\|TC-5-05\|TC-5-06\|TC-5-07" plugins/api/docs/evaluation/test-cases.md`
Expected: 5개 테스트 케이스 모두 존재

- [ ] **Step 3: Commit**

```bash
git add plugins/api/docs/evaluation/test-cases.md
git commit -m "docs(api): test-cases.md 신규 테스트 케이스 5개 추가 (TC-5-03~07)"
```

---

### Task 8: 평가 시스템 — report.md 업데이트

**Files:**
- Modify: `plugins/api/docs/evaluation/report.md:1-17`

- [ ] **Step 1: 테스트 케이스 수 및 커버리지 수치 업데이트**

`plugins/api/docs/evaluation/report.md` 상단의 메타데이터와 커버리지 요약 테이블을 수정:

헤더 영역에서 `(총 54개)` → `(총 59개)`

커버리지 요약 테이블:
```markdown
| 모드 | COVERED | PARTIAL | MISSING | 합계 | 커버율 |
|------|---------|---------|---------|------|--------|
| Writing | 73 | 0 | 3 | 76 | 96.1% |
| Review | 73 | 0 | 3 | 76 | 96.1% |
```

- [ ] **Step 2: 다음 단계 섹션에 이번 작업 기록 추가**

report.md의 "다음 단계" 섹션에 추가:

```markdown
- [x] Pagination & Filtering 심화 — 5개 신규 규칙 추가 (5.2-3~5.2-6, 5.3-0), 5개 테스트 케이스 추가 (TC-5-03~07)
```

- [ ] **Step 3: 변경 확인**

Run: `grep -n "76\|96.1\|59개\|Pagination" plugins/api/docs/evaluation/report.md`
Expected: 업데이트된 수치 및 기록 존재

- [ ] **Step 4: Commit**

```bash
git add plugins/api/docs/evaluation/report.md
git commit -m "docs(api): report.md 커버리지 수치 업데이트 (71→76 규칙, 95.8→96.1%)"
```

---

## Verification

전체 작업 완료 후 검증:

1. **README.md 신규 규칙 예시 확인**: `grep -c "Good\|Bad\|Example\|Request\|Response" plugins/api/README.md`
2. **SKILL.md 동기화 확인**: `grep "Empty collections\|pageSize\|opaque\|Keyset\|Min.*Max" plugins/api/skills/restful-guidelines/SKILL.md`
3. **coverage-map 매핑 확인**: `grep "5.2-3\|5.2-4\|5.2-5\|5.2-6\|5.3-0" plugins/api/docs/evaluation/coverage-map.md`
4. **test-cases 존재 확인**: `grep "TC-5-0[3-7]" plugins/api/docs/evaluation/test-cases.md`
5. **README.md ToC 링크 확인**: `grep -n "partial-response\|expandembed\|bulk-operations" plugins/api/README.md`
6. **README.ko.md 구조 일치 확인**: `diff <(grep "^###\|^####\|^##" plugins/api/README.md) <(grep "^###\|^####\|^##" plugins/api/README.ko.md)` — 헤더 구조가 대응되는지 확인
