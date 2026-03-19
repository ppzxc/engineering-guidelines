---
name: restful-api-guidelines
description: RESTful API 코드 작성 및 리뷰 시 가이드라인을 적용합니다. API 엔드포인트 코드 작성, 컨트롤러/핸들러 구현, API 설계 리뷰 요청 시 자동으로 활성화됩니다.
---

# RESTful API Guidelines Skill

## 트리거 조건

다음 상황에서 이 skill을 적용합니다:
- API 엔드포인트 코드 작성 또는 수정
- REST 컨트롤러/핸들러 구현
- API 응답 구조 설계
- API 코드 리뷰 요청

---

## 코드 작성 모드

API 코드를 작성할 때 아래 규칙을 준수합니다.

### URL 네이밍 규칙

```
# 복수형 명사 + kebab-case
GET    /articles
POST   /articles
GET    /articles/{id}
PUT    /articles/{id}
PATCH  /articles/{id}
DELETE /articles/{id}

# 중첩 리소스
GET    /users/{userId}/comments

# 액션 패턴 (CRUD로 표현 불가한 동작)
POST   /articles/{id}:publish
POST   /orders/{id}:cancel
POST   /users/{id}:deactivate
```

### HTTP 메서드별 상태 코드 매핑

| 메서드 | 성공 코드 | 설명 |
|--------|-----------|------|
| GET | 200 OK | 조회 성공 |
| POST (생성) | 201 Created + Location 헤더 | 리소스 생성 성공 |
| POST (액션) | 200 OK | 액션 수행 성공 |
| PUT | 200 OK | 완전 대체 성공 |
| PATCH | 200 OK | 부분 수정 성공 |
| DELETE | 204 No Content | 삭제 성공 (본문 없음) |

### 에러 응답 형식 템플릿

모든 에러 응답은 RFC 7807/9457 Problem Details 구조를 사용합니다.
`Content-Type: application/problem+json`

```json
{
  "type": "https://api.example.com/errors/error-type",
  "title": "에러 유형의 짧은 요약",
  "status": 400,
  "detail": "이 요청에 대한 구체적인 에러 설명",
  "instance": "/요청/경로",
  "errors": [
    {
      "field": "필드명",
      "message": "해당 필드의 구체적인 문제"
    }
  ],
  "traceId": "요청_추적_ID"
}
```

**자주 사용하는 에러 type URI:**

| HTTP 상태 | type | 사용 시점 |
|-----------|------|-----------|
| 400 | `.../errors/invalid-request` | 요청 형식 오류 |
| 400 | `.../errors/validation-failed` | 유효성 검사 실패 (errors 배열 포함) |
| 401 | `.../errors/unauthorized` | 인증 필요 |
| 403 | `.../errors/forbidden` | 권한 없음 |
| 404 | `.../errors/resource-not-found` | 리소스 없음 |
| 409 | `.../errors/conflict` | 중복 또는 충돌 |
| 429 | `.../errors/too-many-requests` | 속도 제한 초과 |
| 500 | `.../errors/internal-server-error` | 서버 내부 오류 |

### JSON 필드 네이밍 규칙

```json
// 올바른 예시
{
  "id": "123",
  "userId": "456",
  "isActive": true,
  "createdAt": "2024-01-20T10:00:00Z",
  "updatedAt": "2024-01-20T15:00:00Z",
  "status": "PUBLISHED"
}

// 잘못된 예시 - 절대 금지
{
  "user_id": "456",       // snake_case 금지
  "is_active": true,      // snake_case 금지
  "created_at": "...",    // snake_case 금지
  "status": "published"   // enum은 UPPER_SNAKE_CASE
}
```

### 컬렉션/페이지네이션 패턴

**응답 구조 (RFC 5988 Link 헤더 + top-level 배열):**

```
HTTP/1.1 200 OK
Link: <https://api.example.com/articles?pageSize=20&pageToken=abc>; rel="next",
      <https://api.example.com/articles?pageSize=20>; rel="first",
      <https://api.example.com/articles?pageSize=20&pageToken=xyz>; rel="last"
X-Total-Count: 100

[
  { "id": "1", "title": "항목 1" },
  { "id": "2", "title": "항목 2" }
]
```

**요청 파라미터 (camelCase):**

```
GET /articles?pageSize=20&pageToken=eyJ...
GET /articles?pageSize=20&page=2
GET /articles?status=PUBLISHED&orderBy=createdAt:desc
GET /articles?orderBy=createdAt:desc,title:asc
```

### 표준 리소스 필드

생성/수정 시 서버가 자동으로 관리하는 필드:

```json
{
  "id": "서버 생성, 클라이언트 수정 불가",
  "createdAt": "RFC 3339, 서버 생성",
  "updatedAt": "RFC 3339, 서버 자동 갱신"
}
```

### 날짜/시간

**서버 응답 (✅ 필수: UTC)**
```json
{
  "createdAt": "2024-01-20T10:00:00Z",
  "scheduledAt": "2024-01-25T00:30:00Z",
  "birthDate": "1990-05-15"
}
```

**클라이언트 요청 (⚠️ 권장: UTC, 오프셋 허용)**
```json
{ "scheduledAt": "2024-01-25T00:30:00Z" }         // 권장
{ "scheduledAt": "2024-01-25T09:30:00+09:00" }     // 허용 → 서버가 UTC 정규화
```

**금지**
```json
{
  "createdAt": 1705744800000,  // Unix timestamp 금지
  "createdAt": "2024-01-20"   // 시간 포함해야 함 (날짜만 있는 경우 제외)
}
```

### 인증

**인증 헤더 (✅ 필수: Authorization 헤더 사용)**

```
# Bearer Token
Authorization: Bearer eyJhbGciOiJSUzI1NiJ9...

# API Key
Authorization: ApiKey your-api-key-here
```

**401 vs 403 구분:**

| 상태 | 원인 | WWW-Authenticate 헤더 |
|------|------|----------------------|
| 401 | 토큰 없음/만료/형식 오류 | ✅ 필수 포함 |
| 403 | 인증됐지만 권한 없음 | 불필요 |

### Idempotency-Key

중복 실행 위험이 있는 POST(결제, 주문 등)에 필수 적용:

```
POST /orders
Idempotency-Key: a8098c1a-f86e-11da-bd1a-00112444be1e
```

- 같은 키로 재요청 시 → 기존 결과 그대로 반환 (재처리 금지)
- 키 유효 기간: 최소 24시간

### 속도 제한

**응답 헤더 (✅ 필수: 양쪽 모두 포함)**

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 99
X-RateLimit-Reset: 1742342450
RateLimit: limit=100, remaining=99, reset=50
RateLimit-Policy: 100;w=3600
```

**429 응답 (✅ 필수: Retry-After + Problem Details)**

```
HTTP/1.1 429 Too Many Requests
Content-Type: application/problem+json
Retry-After: 50
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1742342450
RateLimit: limit=100, remaining=0, reset=50
RateLimit-Policy: 100;w=3600
```

```json
{
  "type": "https://api.example.com/errors/too-many-requests",
  "title": "속도 제한 초과",
  "status": 429,
  "detail": "허용된 요청 한도를 초과했습니다. 50초 후에 다시 시도해 주세요."
}
```

**클라이언트 재시도 (✅ 필수 / ⚠️ 권장)**

- ✅ 필수: 429 수신 시 `Retry-After` 헤더 값만큼 대기 후 재시도
- ⚠️ 권장: `Retry-After` 없을 시 지수 백오프 + 지터 (`min(60, 1 × 2^(n-1)) + random(0,1)`, n=1부터)
- 최대 재시도 3~5회, 즉시 재시도 금지

---

## 코드 리뷰 모드

API 코드 리뷰 요청 시 아래 체크리스트를 기준으로 위반 사항을 식별하고 수정을 제안합니다.

### 리뷰 체크리스트

#### URL 설계
- [ ] 경로에 소문자 kebab-case 사용
- [ ] 리소스 이름이 복수형 명사
- [ ] 경로에 동사 없음 (액션은 `:action` 패턴 사용)
- [ ] URL에 파일 확장자 없음
- [ ] URL 경로에 버전(`/v1/`, `/v2/` 등) 포함하지 않음

#### 버전 관리
- [ ] API 버전은 URL 경로가 아닌 `X-API-Version` 헤더로 전달
- [ ] `X-API-Version` 값은 ISO 8601 날짜 형식(`YYYY-MM-DD`) 사용

#### HTTP 메서드 & 상태 코드
- [ ] POST 생성 → 201 + Location 헤더
- [ ] GET, PUT, PATCH 성공 → 200
- [ ] DELETE 성공 → 204 (본문 없음)
- [ ] GET 요청이 서버 상태를 변경하지 않음
- [ ] 오류 상황에 200 반환하지 않음

#### JSON 응답
- [ ] 모든 필드가 camelCase
- [ ] Boolean 필드가 `is`/`has`/`can` 접두사 사용
- [ ] 날짜/시간이 RFC 3339 형식
- [ ] 서버 응답의 모든 시간 값이 UTC(`Z`)
- [ ] 오프셋 입력 시 서버가 UTC로 정규화 (에러 아님)
- [ ] Enum 값이 UPPER_SNAKE_CASE
- [ ] null 값 필드가 응답에서 제외됨

#### 에러 처리
- [ ] 에러 응답이 RFC 7807/9457 Problem Details 구조 (`type`, `title`, `status`, `detail`)
- [ ] `Content-Type: application/problem+json` 사용
- [ ] `type`이 에러 유형 식별 URI
- [ ] 유효성 검사 실패 시 모든 오류를 한 번에 반환 (`errors` 확장 필드)
- [ ] 내부 구현 정보(스택 트레이스, DB 오류)가 노출되지 않음

#### 컬렉션
- [ ] 컬렉션 응답 본문이 top-level 배열 (envelope 사용 금지)
- [ ] 쿼리 파라미터가 camelCase (pageSize, pageToken, orderBy)
- [ ] 페이지네이션 메타데이터가 `Link` 헤더로 전달 (rel: next, prev, first, last)
- [ ] 전체 항목 수 제공 시 `X-Total-Count` 헤더 사용
- [ ] 다음 페이지 없을 때 `Link` 헤더에서 `rel="next"` 제외

#### 속도 제한
- [ ] 속도 제한 응답에 `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset` 헤더 포함
- [ ] 속도 제한 응답에 `RateLimit`, `RateLimit-Policy` 헤더 포함
- [ ] 429 응답에 `Retry-After` 헤더 포함 (delta-seconds 형식)
- [ ] 429 응답 본문이 Problem Details 구조 (`type`, `title`, `status`, `detail`)
- [ ] 429 응답의 `Content-Type`이 `application/problem+json`
- [ ] 클라이언트 재시도 시 `Retry-After` 값 준수 (즉시 재시도 금지)

#### 인증 및 보안
- [ ] 인증 토큰이 `Authorization` 헤더로 전달 (쿼리 파라미터 금지)
- [ ] Bearer token: `Authorization: Bearer <token>` 형식
- [ ] 401 응답에 `WWW-Authenticate` 헤더 포함
- [ ] 401(인증 실패) / 403(인가 실패) 구분 올바름
- [ ] 결제·주문 등 중복 위험 POST에 `Idempotency-Key` 지원

#### 비동기 작업 (202 Accepted)
- [ ] 202 응답에 `Location` 헤더 포함 (operation URL)
- [ ] Operation 상태값이 `PENDING`/`IN_PROGRESS`/`COMPLETED`/`FAILED` 사용
- [ ] `FAILED` 상태 시 응답 본문에 RFC 7807 에러 구조 포함

#### 필터링
- [ ] 범위 필터가 `After`/`Before` 접미사 사용 (`createdAfter`, `createdBefore`)
- [ ] 동일 파라미터 반복이 OR 조건으로 처리됨
- [ ] 부분 일치 필터가 `Contains` 접미사 또는 `q` 파라미터 사용

#### 커스텀 헤더
- [ ] 신규 커스텀 헤더에 `X-` 접두사 사용하지 않음 (RFC 6648 deprecated)

### 위반 사항 보고 형식

발견된 위반 사항은 다음 형식으로 보고합니다:

```
❌ [위반 규칙] 현재 코드
   → 수정 제안

예시:
❌ [URL snake_case] GET /user_profiles
   → GET /user-profiles 또는 GET /users

❌ [POST 201 누락] return ResponseEntity.ok(created)
   → return ResponseEntity.created(location).body(created)

❌ [에러 구조] return Map.of("message", "Not found")
   → Problem Details 구조 사용:
      { "type": ".../errors/resource-not-found", "title": "리소스를 찾을 수 없음",
        "status": 404, "detail": "...", "instance": "/path" }
      Content-Type: application/problem+json
```

---

## 코드 예시 참조

### Spring Boot (Java/Kotlin)

```kotlin
@RestController
@RequestMapping("/articles")
class ArticleController {

    @GetMapping
    fun getArticles(
        @RequestParam(defaultValue = "20") pageSize: Int,
        @RequestParam(required = false) pageToken: String?,
        @RequestParam(required = false) status: ArticleStatus?
    ): ResponseEntity<List<Article>> {
        val result = articleService.getArticles(pageSize, pageToken, status)
        val headers = HttpHeaders()
        buildLinkHeader(result, pageSize).let { headers.set("Link", it) }
        result.totalCount?.let { headers.set("X-Total-Count", it.toString()) }
        return ResponseEntity.ok().headers(headers).body(result.items)
    }

    @PostMapping
    fun createArticle(@RequestBody request: CreateArticleRequest): ResponseEntity<Article> {
        val article = articleService.create(request)
        val location = URI.create("/articles/${article.id}")
        return ResponseEntity.created(location).body(article)
    }

    @PatchMapping("/{id}")
    fun updateArticle(
        @PathVariable id: String,
        @RequestBody request: UpdateArticleRequest
    ): ResponseEntity<Article> {
        val article = articleService.update(id, request)
        return ResponseEntity.ok(article)
    }

    @DeleteMapping("/{id}")
    fun deleteArticle(@PathVariable id: String): ResponseEntity<Void> {
        articleService.delete(id)
        return ResponseEntity.noContent().build()
    }

    @PostMapping("/{id}:publish")
    fun publishArticle(@PathVariable id: String): ResponseEntity<Article> {
        val article = articleService.publish(id)
        return ResponseEntity.ok(article)
    }
}
```

### 에러 응답 구조체

```kotlin
// Content-Type: application/problem+json (RFC 7807/9457)
data class ProblemDetail(
    val type: String,           // 에러 유형 URI
    val title: String,          // 에러 유형 요약
    val status: Int,            // HTTP 상태 코드
    val detail: String,         // 요청별 구체적 설명
    val instance: String? = null,  // 요청 경로
    val errors: List<FieldError>? = null,  // 확장: 필드 수준 오류
    val traceId: String? = null    // 확장: 요청 추적 ID
) {
    data class FieldError(
        val field: String,
        val message: String
    )
}

// 사용 예시
throw ApiException(
    status = HttpStatus.NOT_FOUND,
    type = "https://api.example.com/errors/resource-not-found",
    title = "리소스를 찾을 수 없음",
    detail = "요청한 게시글을 찾을 수 없습니다.",
    instance = request.requestURI
)
```

### 컬렉션 응답 헬퍼

```kotlin
// 내부 헬퍼 — HTTP 응답 본문은 List<T>, 메타데이터는 헤더로 전달
data class PageResult<T>(
    val items: List<T>,
    val totalCount: Long? = null,
    val nextPageToken: String? = null,
    val prevPageToken: String? = null
)

fun <T> buildLinkHeader(result: PageResult<T>, pageSize: Int): String {
    val base = "https://api.example.com/articles?pageSize=$pageSize"
    val links = mutableListOf<String>()
    result.nextPageToken?.let { links += "<$base&pageToken=$it>; rel=\"next\"" }
    result.prevPageToken?.let { links += "<$base&pageToken=$it>; rel=\"prev\"" }
    links += "<$base>; rel=\"first\""
    return links.joinToString(", ")
}
```

### 인증 처리

```kotlin
// 401 응답 — 토큰 만료
return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
    .header("WWW-Authenticate", "Bearer realm=\"api\", error=\"token_expired\"")
    .contentType(MediaType.parseMediaType("application/problem+json"))
    .body(ProblemDetail(
        type = "https://api.example.com/errors/unauthorized",
        title = "인증이 필요합니다",
        status = 401,
        detail = "액세스 토큰이 만료되었습니다."
    ))

// 403 응답 — 권한 없음
return ResponseEntity.status(HttpStatus.FORBIDDEN)
    .contentType(MediaType.parseMediaType("application/problem+json"))
    .body(ProblemDetail(
        type = "https://api.example.com/errors/forbidden",
        title = "접근이 거부되었습니다",
        status = 403,
        detail = "이 리소스에 접근할 권한이 없습니다."
    ))
```

### Idempotency-Key 처리

```kotlin
@PostMapping("/orders")
fun createOrder(
    @RequestHeader("Idempotency-Key") idempotencyKey: String?,
    @RequestBody request: CreateOrderRequest
): ResponseEntity<Order> {
    // 기존 처리 결과 확인
    idempotencyKey?.let { key ->
        idempotencyStore.find(key)?.let { cached ->
            return ResponseEntity.status(cached.statusCode).body(cached.body)
        }
    }

    val order = orderService.create(request)
    val location = URI.create("/orders/${order.id}")

    // 결과 저장 (TTL: 24시간)
    idempotencyKey?.let { key ->
        idempotencyStore.save(key, statusCode = 201, body = order, ttl = Duration.ofHours(24))
    }

    return ResponseEntity.created(location).body(order)
}
```

### 속도 제한 응답 헤더 생성

```kotlin
fun addRateLimitHeaders(headers: HttpHeaders, limit: Int, remaining: Int, resetAt: Instant) {
    val resetUnix = resetAt.epochSecond
    val resetDelta = resetAt.epochSecond - Instant.now().epochSecond

    // 레거시 헤더
    headers.set("X-RateLimit-Limit", limit.toString())
    headers.set("X-RateLimit-Remaining", remaining.toString())
    headers.set("X-RateLimit-Reset", resetUnix.toString())

    // IETF 표준 헤더
    headers.set("RateLimit", "limit=$limit, remaining=$remaining, reset=$resetDelta")
    headers.set("RateLimit-Policy", "$limit;w=3600")
}

// 429 응답
fun rateLimitExceededResponse(retryAfterSeconds: Long): ResponseEntity<ProblemDetail> {
    val headers = HttpHeaders()
    headers.set("Retry-After", retryAfterSeconds.toString())
    addRateLimitHeaders(headers, limit = 100, remaining = 0, resetAt = Instant.now().plusSeconds(retryAfterSeconds))

    return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS)
        .headers(headers)
        .contentType(MediaType.parseMediaType("application/problem+json"))
        .body(ProblemDetail(
            type = "https://api.example.com/errors/too-many-requests",
            title = "속도 제한 초과",
            status = 429,
            detail = "허용된 요청 한도를 초과했습니다. ${retryAfterSeconds}초 후에 다시 시도해 주세요."
        ))
}
```

### API 버전 헤더 처리

```kotlin
// 요청에서 버전 추출
@GetMapping("/articles")
fun getArticles(
    @RequestHeader("X-API-Version", required = false) apiVersion: String?
): ResponseEntity<List<Article>> {
    val version = apiVersion ?: "2024-01-20" // 기본 버전
    val articles = articleService.getArticles(version)

    return ResponseEntity.ok()
        .header("X-API-Version", version)  // 적용된 버전 응답에 명시
        .body(articles)
}
```

### Deprecation 헤더 처리

```kotlin
// Deprecated 엔드포인트에 헤더 추가
fun addDeprecationHeaders(headers: HttpHeaders, sunsetDate: String, successorUrl: String) {
    headers.set("Deprecation", "true")
    headers.set("Sunset", sunsetDate)  // e.g. "Sat, 01 Jan 2025 00:00:00 GMT"
    headers.set("Link", "<$successorUrl>; rel=\"successor-version\"")
}
```
