# RESTful API 가이드라인

본 문서의 필수(MUST), 권장(SHOULD), 선택(MAY) 키워드는 RFC 2119/8174 규격을 따릅니다.

---

## 프로필 가이드

각 규칙에는 `[T1]`, `[T2]`, `[T3]` 태그가 붙어 있습니다. 사용자가 특정 프로필을 지정하면 **해당 티어(Tier) 이하의 규칙만 적용**됩니다.

| 프로필 | 포함 티어 | 대상 | 규칙 수 |
|--------|-----------|------|---------|
| **Essential** | T1 전용 | 모든 API — 첫날부터 적용 | ~91 |
| **Standard** | T1 + T2 | 프로덕션 운영 단계 | ~129 |
| **Full** | T1 + T2 + T3 | 대규모/엔터프라이즈 API | ~156 |

**사용 예시:** "Essential 프로필로 이 API를 리뷰해줘" → T1 규칙만 검사합니다.

**인자 없음(No-arg) 동작 (ADR-0045):**
- **대화형(Interactive) 세션**: 프로필이 지정되지 않은 경우, AskUserQuestion을 통해 "어떤 프로필로 검토할까요?" (Essential [T1] / Standard [T1+T2] / Full [T1+T2+T3, 권장])를 확인한 후 진행합니다.
- **비대화형(Non-interactive) 세션**: Full 프로필(T1+T2+T3)을 기본값으로 진행합니다.

**티어 분류 기준 [ADR-0010]:**
- **T1 (Essential):** 나중에 도입할 경우 하위 호환성이 깨질 위험이 높은 규칙 / 보안 필수 사항 / HTTP 표준 / API 계약의 근간
- **T2 (Standard):** 프로덕션 운영 편의성 제공 규칙, 나중에 도입 가능
- **T3 (Full):** 엔터프라이즈 또는 고급 패턴, 특정 도메인에 한정됨

---

## URL 설계

**리소스 지향 설계 (AIP-121)** — API는 리소스(명사)를 중심으로 설계됩니다. URL 경로는 리소스의 계층 구조를 나타내며, 행위는 HTTP 메서드 및 커스텀 메서드로 표현합니다.
- 모든 리소스는 최소한 GET(조회)을 지원해야 합니다. `[T1]`
- 컬렉션 리소스는 List(목록 조회)를 지원해야 합니다. 단, 인스턴스가 하나만 존재할 수 있는 싱글톤(Singleton) 리소스(예: `/users/{id}/settings`)는 예외입니다. `[T1]` (AIP-121)
- 표준 메서드(GET, POST, PATCH, DELETE)를 우선적으로 사용하며, 표준 메서드로 표현할 수 없는 경우에만 커스텀 메서드를 사용합니다. `[T1]`
- 데이터베이스 구조를 API 스키마에 그대로 반영하지 마십시오. `[T1]`

- 경로 세그먼트에는 **kebab-case**를 사용합니다: `/user-profiles`, `/product-categories/123` `[T1]`
- 컬렉션에는 **복수 명사**를 사용합니다: `/articles` ( `/article` 불가) `[T1]`
- **리소스 경로에 동사를 사용하지 마십시오** — CRUD 작업에는 HTTP 메서드를 사용하고, 부작용이 있는 비-CRUD 동작에는 콜론(`:`) 구문을 동반한 `POST` 메서드를 사용합니다 (리소스 수준: `/{resource}/{id}:{action}`, 컬렉션 수준: `/{resource}:{action}`). 부작용 없는 조회형 커스텀 메서드는 `GET`을 사용합니다(액션 섹션 참고). `[T1]`
- **파일 확장자**를 경로에 포함하지 마십시오 (`.json`, `.xml` 등) `[T1]`
- **끝에 슬래시(trailing slash)를 붙이지 마십시오** — `/articles/` 대신 `/articles` 사용 `[T1]`
- 쿼리 파라미터에는 **camelCase**를 사용합니다: `pageSize=20&sortOrder=desc` `[T1]`
- 경로 세그먼트에는 ASCII 소문자, 숫자, 하이픈만 허용합니다. `[T1]`
- 배열 형식의 파라미터는 이름을 반복하여 지정합니다: `?tag=tech&tag=design` `[T1]`
- **하위 리소스 중첩은 단일 수준까지만 허용합니다** — `/{parent}/{parentId}/{child}/{childId}` (예: `/users/42/profiles/7`) `[T2]`

**중첩 깊이 규칙:** `[T2]`
부모 리소스 아래에는 최대 하나의 하위 리소스만 중첩합니다. 더 깊은 관계가 필요한 경우 플랫(flat)한 최상위 경로로 승격시킵니다.

| 상황 | ✅ 권장 (Do) | ❌ 금지 (Don't) |
|-----------|-------|---------|
| 주문 내 주문 항목 | `/orders/{orderId}/items/{itemId}` | `/users/{userId}/orders/{orderId}/items/{itemId}` |
| 주문 항목에 대한 리뷰 | `/order-items/{orderItemId}/reviews/{reviewId}` | `/users/{userId}/orders/{orderId}/items/{itemId}/reviews/{reviewId}` |
| 주소 하위의 배송 구역 | `/addresses/{addressId}/delivery-zones/{zoneId}` | `/users/{userId}/addresses/{addressId}/delivery-zones/{zoneId}` |

---

## HTTP 메서드 및 상태 코드

| 메서드 | 용도 | 멱등성 (Idempotent) | 안전성 (Safe) |
|--------|---------|-----------|------|
| GET | 조회 | 예 | 예 |
| POST | 리소스 생성 / 커스텀 메서드 실행 | 아니요 | 아니요 |
| PUT | 전체 콘텐츠 교체 (파일/이진 업로드) | 예 | 아니요 |
| PATCH | 부분 수정 (기본 수정 메서드) | 아니요 | 아니요 |
| DELETE | 삭제 | 예 | 아니요 |
| HEAD | 메타데이터만 조회 (응답 본문 없음) | 예 | 예 |
| OPTIONS | 허용된 메서드/CORS 정보 조회 | 예 | 예 |

- **HEAD (M-8):** 클라이언트는 전체 본문을 다운로드하지 않고 리소스의 존재 여부나 마지막 수정 시간을 확인하기 위해 HEAD를 사용해야 합니다. `[T2]`
- **OPTIONS (M-8):** 서버는 CORS 프리플라이트 요청에 대해 OPTIONS를 지원해야 하며, `Allow` 헤더를 통해 지원하는 메서드를 기술해야 합니다. `[T2]`
- GET, HEAD, DELETE 요청은 요청 본문(body)을 포함해서는 안 됩니다. `[T1]`

**2xx 성공:**
- `200 OK` — 표준 성공 응답 `[T1]`
- `201 Created` — 생성 성공. 응답 헤더에 새로 생성된 리소스의 URL을 가리키는 `Location` 헤더를 포함해야 합니다. `[T1]`
- `202 Accepted` — 요청이 수락되었으나 처리가 완료되지 않음. 비동기 또는 지연 작업에 사용됩니다. `[T2]`
- `204 No Content` — 성공했으나 응답 본문이 없음 (DELETE 성공 시 등) `[T1]`

**4xx 클라이언트 에러:**
- `400 Bad Request` — 잘못된 형식의 요청, 유효성 검사 실패 `[T1]`
- `401 Unauthorized` — 인증 정보 누락 또는 만료 `[T1]`
- `403 Forbidden` — 인증되었으나 해당 리소스에 대한 권한 없음 `[T1]`
- `404 Not Found` — 리소스가 존재하지 않음 `[T1]`
- `409 Conflict` — 리소스 중복 (동일 ID 또는 고유 제약 조건 위반) `[T1]`
- `412 Precondition Failed` — `If-Match` etag 불일치 (조건부 요청 실패) `[T1]`
- `422 Unprocessable Entity` — 비즈니스/의미론적 유효성 검사 실패 `[T1]`
- `429 Too Many Requests` — 요청 횟수 제한 초과 `[T1]`

**5xx 서버 에러:**
- `500 Internal Server Error` — 예상치 못한 서버 내부 실패 `[T1]`
- `503 Service Unavailable` — 일시적인 서비스 이용 불가 `[T1]`

---

## 헤더

- 응답/요청 본문 형식으로 `Content-Type: application/json` 지정 `[T1]`
- 콘텐츠 협상을 위해 `Accept: application/json` 헤더 사용 `[T1]`
- 201 Created 응답 시 `Location` 헤더 필수 포함 `[T1]`
- 컬렉션의 전체 크기를 나타내기 위해 `Total-Count` 헤더 사용 `[T2]`
- 페이지네이션 링크를 나타내기 위해 RFC 8288 `Link` 헤더 사용 `[T2]`
- **커스텀 헤더에 `X-` 접두사 사용 금지** (RFC 6648/BCP 178) — `X-`는 원래 실험적 헤더용이었으나 표준이 될 때 이름 충돌을 유발합니다. 모든 신규 API는 이 접두사 없이 커스텀 헤더를 정의해야 합니다. (예외: 기존에 표준화된 `X-Forwarded-For`, `X-Content-Type-Options`, `X-Hub-Signature-256` 등은 호환성을 위해 유지) `[T1]`
- `Cache-Control` 헤더를 통해 캐싱 전략을 지정합니다. `[T2]`
- `Request-Id` 헤더 — 서버는 모든 응답에 고유한 요청 식별자(UUID v4)를 포함해야 합니다. 클라이언트가 `Request-Id`를 보내면 서버는 이를 채택하거나 새로 생성해야 합니다. `[T1]`
- 마이크로서비스 간 분산 추적(Distributed Tracing)을 위해 `Request-Id`를 전파합니다. `[T1]`
- 디버깅 연관 추적을 위해 모든 서비스 로그에 `Request-Id`를 기록합니다. `[T1]`
- `ETag` — 리소스의 버전을 나타내는 불투명 문자열로, 서버 응답에 포함됩니다. `[T1]`
- `If-Match` — 낙관적 동시성 제어(Optimistic Concurrency Control)를 위해 클라이언트가 수정/삭제 요청 시 ETag 값을 실어 보냅니다. `[T1]`

---

## JSON 포맷

- 필드 이름에는 **camelCase**를 사용합니다: `userId`, `createdAt`, `isActive` `[T1]`
- snake_case나 임의의 축약형 단어를 사용하지 마십시오. `[T1]`
- null이거나 값이 없는 필드는 본문에서 아예 생략합니다 (`"field": null` 형태로 전송 금지) `[T1]`
  - *예외*: 명시적인 필드 삭제/초기화를 위해 RFC 7396 (JSON Merge Patch) 방식을 채택한 엔드포인트에 한해서는, 클라이언트가 필드를 비우기 위해 `"field": null`을 전송할 수 있습니다. 이 경우 서버는 해당 필드를 null 또는 기본값으로 설정해야 합니다. `[T2]`
- 날짜/시간 값은 RFC 3339 규격 문자열로 표현하며, 서버 응답은 UTC (`Z`) 기준으로 반환합니다. `[T1]`
- 표준 리소스 필드: `id`, `createdAt` (생성 시에만 설정 가능), `updatedAt` (읽기 전용) `[T1]`
- 서버는 요청 본문에 포함된 읽기 전용 필드를 무시해야 합니다. `[T1]`

**리소스 상태 에넘 패턴 (AIP-216):** `[T1]` 리소스 생명주기 상태를 나타낼 때:
- 상태 필드 이름은 반드시 `state`여야 합니다 (`status` 불가 — HTTP 상태 코드와 혼동 방지)
- 에넘의 첫 번째 값은 항상 `STATE_UNSPECIFIED` (초기/알 수 없는 상태)여야 합니다.
- `state` 필드는 읽기 전용(OUTPUT_ONLY)입니다 — Create 시 직접 설정하거나 PATCH로 수정할 수 없으며, 상태 전환은 커스텀 메서드로만 수행합니다.
- **상태값 명명 규칙:** 사용 가능 → `ACTIVE` (`READY`/`AVAILABLE` 대신); 종료(terminal) → 과거분사 `-ED` (`SUCCEEDED`, `FAILED`, `DELETED`); 진행 중 → 현재분사 `-ING` (`RUNNING`, `CREATING`, `DELETING`)
- 공통 패턴: `ACTIVE/INACTIVE`, `PENDING/RUNNING/SUCCEEDED/FAILED`
- 허용되지 않는 상태 전환(전제 조건 미충족)은 `409 Conflict`를 반환하며 응답 본문에 현재 `state`를 포함합니다. `[T2]`
- 클라이언트에게 실제 유스케이스가 있는 상태만 노출하고, 내부 구현 상태를 그대로 드러내지 마십시오. `[T3]`
- 시간으로부터 도출되는 단일 사실인 상태는 에넘보다 타임스탬프를 우선합니다 (예: 삭제 여부 → `deleteTime`, 소프트 딜리트 섹션 참고). `[T3]`

---

## 에러 응답 (RFC 7807/9457 + AIP-193 하이브리드)

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

- `Content-Type: application/problem+json` 헤더 설정 `[T1]`
- **기계 판독 가능한 코드:** 클라이언트 분기 처리를 위해 UPPER_SNAKE_CASE 형식의 `code` 문자열 필드를 포함합니다. `[T1]`
- **필드 수준 에러 (AIP-193 스타일):** 400/422 에러의 경우, `@type` 필드를 가진 다형성 객체를 담은 `details` 배열을 포함합니다. `[T1]`
  - `google.rpc.BadRequest`: `fieldViolations` 배열(필드 경로 `field`와 상세 설명 `description`)을 포함합니다.
  - `google.rpc.ErrorInfo`: 안정적인 `reason`과 에러가 속한 `domain`을 포함합니다.
  - 유효성 검사 실패 시 점진적으로 하나씩 에러를 내지 말고, 발견된 **모든** 유효성 오류를 한 번에 반환해야 합니다. `[T1]`
  - 스택 트레이스, 서버 내부 경로 또는 데이터베이스 에러 메시지를 절대 외부로 노출하지 마십시오. `[T1]`
  - `traceId` 값은 디버깅 상관관계 일관성을 위해 `Request-Id` 응답 헤더와 반드시 일치해야 합니다. `[T1]`

---

## 리소스 스키마 및 필드 규칙

- **스키마 일관성 (AIP-121):** Get, List, Create, Update 응답에 담기는 전체 리소스 표현은 서로 동일해야 합니다. `fields`를 통한 부분 응답 및 배치 결과 래퍼는 명시적 예외입니다. `[T2]`
- 표준 리소스 필드: `id`, `createdAt` (생성 시 설정 가능), `updatedAt` (읽기 전용) `[T1]`
- 리소스 식별자(ID)는 불투명 문자열이어야 합니다 — 클라이언트가 ID의 구조를 파싱해서는 안 됩니다. `[T1]`
- null이거나 빈 필드는 아예 생략합니다. `[T1]`
- 서버는 요청 본문에 포함된 읽기 전용 필드를 무시해야 합니다. `[T1]`

**필드 행위 어노테이션** (AIP-203) `[T1]` — OpenAPI 스키마에서 `x-field-behavior` 확장 필드를 사용하여 필드의 행위를 선언합니다.

| 어노테이션 | 의미 | 생성(Create) 시 서버 동작 | 수정(Update) 시 서버 동작 |
|-----------|---------|--------------------------|--------------------------|
| `REQUIRED` | 클라이언트 필수 제공 | 누락 시 → `400 Bad Request` | 누락 시 → `400 Bad Request` |
| `OUTPUT_ONLY` | 서버 설정; 클라이언트 제공 금지 | 요청 본문의 값은 무시됨 | 요청 본문의 값은 무시됨 |
| `INPUT_ONLY` | 클라이언트 제공; 응답에서 제외됨 | 처리 완료 후 응답에서 제외 | 처리 완료 후 응답에서 제외 |
| `IMMUTABLE` | 생성 후 변경 불가 | 클라이언트가 최초 지정 가능 | 값 수정 시도 시 → `400 Bad Request` |
| `OPTIONAL` | 선택 사항 | 기본값 적용 가능 | 생략 시 → 기존 값 유지 |
| `IDENTIFIER` | 리소스 식별자; 변경 불가 | 클라이언트 제공 가능 (선택) | 값 수정 시도 시 → `400 Bad Request` |

OpenAPI 매핑: `OUTPUT_ONLY` → `readOnly: true`, `INPUT_ONLY` → `writeOnly: true`, 나머지 어노테이션은 `x-field-behavior` 확장에 기록합니다. `[T1]`

---

## CRUD 동작

**읽기-쓰기 강한 일관성 (AIP-121):** `[T2]` 표준 메서드가 성공한 직후 이어지는 GET 요청은 그 결과를 반드시 반영해야 합니다 — 생성 후에는 해당 리소스를, 수정 후에는 최종 값을, 삭제 후에는 `404 Not Found`를 반환해야 합니다. 예외: 소프트 딜리트된 리소스(AIP-164)는 `deleteTime` 정보와 함께 GET으로 계속 조회됩니다.

**표준 메서드 응답 규칙:**
- POST (생성): `201 Created`와 함께 생성된 전체 리소스 객체 및 `Location` 헤더 반환 `[T1]`
- PATCH (수정): 수정 완료된 전체 리소스 객체 반환 `[T1]`
- DELETE (삭제): 응답 본문 없이 `204 No Content` 반환 `[T1]`

**POST (생성):** `201` 성공 응답과 생성된 전체 리소스를 반환하며, `Location` 헤더를 포함해야 합니다. `[T1]`
- 클라이언트가 고유한 리소스 ID를 직접 지정하여 생성할 수 있도록 지원해야 합니다 (선택 사항).
- 이미 존재하는 리소스를 중복 생성하려 하는 경우 `409 Conflict`를 반환해야 합니다.

**PATCH (수정 — 기본값, AIP-134):** `updateMask`에 명시된 필드만 수정하며, 지정되지 않은 필드는 유지합니다. `[T1]`
- `updateMask` 쿼리 파라미터는 필수 사항입니다: 쉼표로 구분된 필드 경로들 — `?updateMask=title,content`
- 응답 본문은 업데이트 완료된 전체 리소스 객체를 반환해야 합니다.
- `updateMask=*` 지정을 지원하여 요청 본문에 존재하는 모든 변경 가능 필드를 한 번에 수정할 수 있습니다.
- 빈 마스크이거나 정의되지 않은 잘못된 필드 경로를 지정한 경우 `400 Bad Request`를 반환합니다.
- 중첩된 필드는 점(`.`) 구문을 사용합니다: `?updateMask=address.city`
- 필드 행위와 마스크 상호작용:
  - 마스크에 `OUTPUT_ONLY`가 포함된 경우: 에러를 발생시키지 않고 무시합니다.
  - 마스크에 `IMMUTABLE`가 포함되어 있고 값을 변경하려고 시도한 경우: `400 Bad Request`를 반환합니다.
  - 마스크에 `REQUIRED`가 지정된 경우: 해당 필드는 반드시 본문에 포함되어야 합니다.
- **대안 (JSON Merge Patch)**: API 서비스가 RFC 7396 (JSON Merge Patch)을 구현하고 삭제용 명시적 `null` 필드를 지원하는 경우, `updateMask` 지정을 선택 사항(Optional)으로 처리하여 요청 본문에 포함된 필드만으로 부분 수정을 수행할 수 있습니다. `[T2]`

**낙관적 동시성 제어 (AIP-154):** `[T1]` 리소스 스키마에 `etag` 필드를 포함합니다 (불투명 문자열, 읽기 전용, 수정될 때마다 갱신됨). 또한 동일한 값을 `ETag` 응답 헤더로 반환합니다.
- 수정/삭제 요청 시 클라이언트는 `If-Match: {etag}` 헤더로 ETag 값을 보냅니다.
- ETag가 불일치하는 경우, `412 Precondition Failed`를 반환합니다 (응답 본문에 현재 서버 측 리소스를 함께 보냄).
- 만약 `If-Match` 헤더가 유실된 경우: 기본적으로 조건 없이 요청을 실행합니다 (선택적 동시성 제어).
- **민감한 리소스** (재고, 권한, 금융 트랜잭션 등): `If-Match` 요청이 필수이며, 누락 시 `428 Precondition Required`를 반환해야 합니다. `[T1]`

**PUT (전체 대체 — 특별한 경우에만 사용):** 파일 업로드, 이진 콘텐츠, 설정 값 전체 교체 등 전체 리소스 내용 대체가 의미상 필요한 경우에만 사용합니다. 일반 리소스 속성 수정용으로는 PATCH를 사용해야 하며 PUT은 금지됩니다. `[T1]`

**DELETE (삭제):** `204`를 반환합니다. 이미 삭제된 리소스에 대한 재삭제 요청은 서비스 정책에 따라 `404` 또는 `204`로 유연하게 처리할 수 있습니다. `[T1]`
- 하위 리소스까지 연쇄 삭제하기 위해 `force` 쿼리 파라미터를 지원할 수 있습니다 (`DELETE /resources/{id}?force=true`).

**소프트 딜리트 (AIP-164):** `[T3]` 즉각적이고 영구적인 삭제 대신 복구 가능한 삭제 패턴이 필요한 경우:
- 리소스에 `deleteTime` (삭제 시각) 및 `expireTime` (영구 삭제 예정 시각) 필드를 추가합니다 (읽기 전용).
- 복구 API는 `POST /{resource}/{id}:undelete` 커스텀 메서드를 제공합니다.
- 목록 조회: 기본적으로 소프트 딜리트된 리소스를 제외하고 조회하되, `?showDeleted=true` 파라미터가 있을 때만 포함합니다.
- 단건 조회: 평소와 같이 리소스를 정상 반환합니다 (단, `deleteTime` 정보 포함).
- 설정된 보관 기간(기본 30일)이 지나면 배경 작업 등을 통해 자동으로 영구 삭제됩니다.

**변경 미리 검증 / Dry Run (AIP-163):** `[T3]` 리소스 생성/수정 요청 전 유효성 검사만 시뮬레이션하고 싶은 경우:
- `?validateOnly=true` 쿼리 파라미터를 사용합니다.
- `true`인 경우: 유효성 검사만 수행하며, 실제 리소스를 생성/변경하지 않고 그에 따르는 부수 효과(side-effect)도 일으키지 않습니다.
- 유효성 검사 성공 시: 실제 실행 시와 유사한 응답을 반환합니다 (서버가 생성하는 자동 필드는 제외될 수 있음).
- 유효성 검사 실패 시: 동일한 RFC 9457 에러 본문을 반환합니다.

---

## 액션 (동작)

**비-CRUD 행위 정의:** `[T1]`
단순한 필드 수정 수준을 넘어서서 부수 효과가 수반되는 동작(예: 환불, 알림 발송, 상태 머신 전환 등)은 PATCH로 처리하기 어렵습니다. 이 경우 리소스 경로 뒤에 콜론(`:`)과 동작명을 명시하는 `POST` 커스텀 메서드를 사용하여 의도를 명확히 합니다. 이는 특정 ID가 없는 컬렉션 단위 동작에도 동일하게 적용됩니다 (`POST /{resource}:{action}`).

| 동작 | ✅ 권장 (Do) | ❌ 금지 (Don't) | 이유 |
|--------|-------|---------|-----|
| 주문 취소 | `POST /orders/{id}:cancel` | `PATCH /orders/{id}` 본문 `{"status":"cancelled"}` | 취소 동작은 단순 필드 수정이 아니며 환불 및 알림 처리가 연동됨 |
| 리뷰 승인 | `POST /reviews/{id}:approve` | `PUT /reviews/{id}/approval` | 승인은 노출 상태 전환 외에도 통계 점수 반영 등 후속 작업 유발 |
| 보고서 생성 | `POST /reports:generate` | `GET /reports?generate=true` | 생성 작업은 상태를 변경하거나 높은 컴퓨팅 자원을 쓰는 행위로 GET이 적합하지 않음 |

채택 패턴: Google AIP-136 (`/orders/{id}:cancel`), Google Cloud API (`/projects/{project}:setIamPolicy`).

> **콜론 구문 사용 시 주의사항**: Express.js, Rails 등 `:`를 경로 매개변수로 사용하는 웹 프레임워크에서는 추가 라우팅 설정(정규식 매칭 등)이 필요합니다. OpenAPI 문서 설계 시 프레임워크 지원 여부를 검토하십시오.

**동작 메서드 응답 코드:** `[T1]`

| 시나리오 | 상태 코드 | 응답 본문 |
|----------|-------------|---------------|
| 동기식 동작 — 리소스 업데이트 완료 | `200 OK` | 업데이트된 리소스 객체 |
| 동기식 동작 — 반환할 정보 없음 | `204 No Content` | 없음 |
| 비동기식 동작 — 수락 완료 및 지연 처리 | `202 Accepted` | 없거나 수락 관련 정보 제공 |

비동기 동작 중 새로운 폴링 작업 리소스가 생성되는 경우는 `201 Created`와 `Location` 헤더를 대신 사용하십시오 ([LRO 장시간 실행 작업](#장시간-실행-작업) 참고).

**커스텀 메서드의 HTTP 메서드 선택 (AIP-136):** `[T1]`
- 부작용이 있거나 상태를 변경하는 경우 `POST` — 액션의 기본값이며 입력은 본문에 담습니다.
- 부작용 없는 조회형 커스텀 메서드는 `GET`; 이때 요청 본문을 포함해서는 안 되며 입력은 쿼리 파라미터로 전달합니다. 읽기는 원칙적으로 표준 컬렉션 `GET` + `filter`/`q`/`fields`로 표현하며, 콜론 `GET` 커스텀 메서드는 필터·투영으로 표현할 수 **없는** 고유 연산(예: `GET /documents/{id}:preview`, `GET /text:translate`)에만 한정합니다.
- 조회 메서드라도 파라미터가 URL 길이 한계를 초과할 때만 `POST`로 폴백합니다.

**커스텀 동사 네이밍 (AIP-136):** `[T1]`
- 콜론 뒤 동사는 camelCase: `:batchGet`, `:setIamPolicy` (`:batch_get` / `:BatchGet` 불가)
- 동사 또는 동사+명사 사용; 전치사 포함 금지 (`:moveForArchive` 불가 → `:moveToArchive`)
- 표준 메서드 동사(`get`, `list`, `create`, `update`, `delete`) 재사용 금지
- 장시간 실행 변형은 `Async`가 아니라 `LongRunning` 접미사 사용 (예: `:exportLongRunning`)

**커스텀 메서드 스코프 (AIP-136):** `[T2]` 커스텀 메서드는 리소스(`/articles/{id}:publish`), 컬렉션(`/articles:purge`)에 바인딩하거나, 관련 리소스가 없는 경우 stateless/서비스 스코프(동사+명사 권장, 예: `/text:translate`)로 정의할 수 있습니다.

---

## 컬렉션 및 페이지네이션

- **JSON HAL 표준 (권장)**: 컬렉션 조회의 경우, JSON Hijacking 방지 및 하이퍼미디어 지원을 위해 `application/hal+json` Content-Type을 사용하는 JSON HAL 객체 엔벨롭(envelope)을 반환해야 합니다. `[T1]`
- **엔벨롭 구조**:
  - `_links`: 하이퍼미디어 링크들 (`self`, `next`, `prev`, `first`, `last`) `[T1]`
  - `_embedded`: 리소스 이름(예: `"articles"`)을 키로 사용하는 실제 리소스 목록 배열 `[T1]`
  - 최상위 레벨 필드에는 커스텀 페이징 정보(예: `totalCount`, `pageSize`)가 포함될 수 있습니다. `[T1]`
- **레거시 배열 지원**: 하위 호환성을 유지해야 하는 구형 API의 경우, 최상위에 배열 `[]` 형식을 유지하면서 RFC 8288 `Link` 및 `Total-Count` 응답 헤더로 메타데이터를 대체 제공할 수 있습니다. `[T1]`
- **콘텐츠 협상 폴백(Content Negotiation Fallback)**: 클라이언트가 `application/hal+json` 대신 `Accept: application/json`을 명시적으로 요청하는 경우, 서버는 클라이언트 측 파싱 오버헤드를 줄이기 위해 간소화된 일반 JSON 엔벨롭(예: `{"items": [...], "totalCount": N}`)을 반환할 수 있습니다. `[T2]`
- **빈 컬렉션 반환**: 데이터가 존재하지 않는 경우 `404` 대신 `200 OK`와 빈 컬렉션(예: `_embedded: { "articles": [] }` and `totalCount: 0`)을 반환해야 합니다. `[T1]`

### API 표면 계약 — 페이지네이션 방식

#### 토큰 기반 페이지네이션 (Token-based Pagination) (AIP-158, 권장) `[T2]`

불투명 토큰(`pageToken`)을 사용합니다. 클라이언트는 토큰의 내부 구조를 파싱하거나 직접 토큰을 생성해서는 안 됩니다.

**파라미터:**
- `pageSize` — 페이지당 항목 수 (기본값 20, 최대 100)
- `pageToken` — 이전 응답에서 제공된 `nextPageToken` 값 (첫 페이지 요청 시에는 생략)

**요청/응답 흐름 (JSON HAL 표준):**

```
# 첫 번째 페이지 요청
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
# 다음 페이지 요청 (next 링크에 제공된 pageToken 전달)
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
# 마지막 페이지 요청 — next 링크 생략됨
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

**세부 규칙:**
- 클라이언트는 `pageToken` 내부를 가공하거나 수동 생성할 수 없으며, 반드시 서버가 반환한 불투명 값을 그대로 활용해야 합니다. `[T2]`
- `pageSize < 1` 인 경우 → `400 Bad Request` 에러. `pageSize > max` 인 경우 → 에러 없이 강제로 최대값(max)으로 제한합니다. `[T2]`
- 더 이상 다음 페이지가 없다면 `_links.next` 필드를 응답에서 생략합니다. `[T2]`

**서버 구현 참고 사항 (클라이언트에 세부 로직 노출 금지):**

토큰 내부에 키셋 정렬 정보(keyset)를 암호화/인코딩하여 활용하는 방식(Keyset Pagination)을 권장합니다. `OFFSET N LIMIT 20`과 같은 정렬 쿼리는 뒷 페이지로 갈수록 O(N)의 성능 저하가 나타나므로 사용해서는 안 됩니다.

```sql
-- pageToken 내부: { "createdAt": "2024-06-15T10:30:00Z", "id": 20 } → Base64 인코딩
SELECT * FROM articles
WHERE (created_at, id) < ('2024-06-15T10:30:00Z', 20)  -- keyset 조건 기반 쿼리
ORDER BY created_at DESC, id DESC
LIMIT 21  -- pageSize + 1 개를 조회하여 다음 페이지가 존재하는지 미리 확인
-- 만약 조회된 결과가 21개이면, 마지막 항목을 버리고 다음 pageToken을 생성합니다.
-- 결과가 21개 미만이면, 다음 pageToken을 제공하지 않습니다.
```

#### 오프셋 기반 페이지네이션 (Offset-based Pagination) (소규모 데이터 전용) `[T2]`

관리자 도구 등 특정 페이지 번호로 무작위 접근이 반드시 필요하고, 데이터의 총 크기가 10,000건 미만인 소량 데이터에 한해서만 한시적으로 허용됩니다.
- `page` + `pageSize` 조합 파라미터를 사용합니다.
- 대용량 데이터에서는 성능 저하 문제가 있고, 데이터가 실시간으로 추가/삭제되는 동안 사용하면 조회 결과 누락 또는 중복 현상이 일어납니다.

### 페이지네이션 방식 결정 전략

```
특정 페이지로 임의 접근이 필요함 AND 데이터 총 크기 < 10,000건?
  ├─ 예 (Yes) → 오프셋 기반 사용 (page + pageSize)
  └─ 아니요 (No) → 토큰 기반 사용 (pageToken + pageSize, AIP-158) ← 기본 권장 전략
```

**하나의 API 서비스 내에서도 엔드포인트에 따라 서로 다른 페이지네이션 전략을 병행할 수 있습니다. 단, 동일한 엔드포인트 내에서 두 가지 페이징 방식을 함께 제공해서는 안 됩니다.**

---

## 필터링 및 정렬

- **필터 표현식 (AIP-160):** 복잡한 조회 조건(AND/OR, 비교 연산자 등)의 경우, 구조화된 조건식을 단일 `filter` 쿼리 파라미터 값으로 전달합니다. `[T1]`
- **단순 일치 필터:** 단순한 1:1 일치 여부 필터링(예: 특정 상태값의 정확한 매칭)의 경우, 기본적인 CRUD 작업에서 파싱 오버헤드를 줄이기 위해 가벼운 대안으로서 개별 쿼리 파라미터(예: `?status=ACTIVE`) 지원을 허용합니다. `[T1]`
- 문법 예시: `?filter=status = "ACTIVE" AND price >= 1000`
- 비교 연산자: `=`, `!=`, `<`, `>`, `<=`, `>=`
- 논리 연산자: `AND`, `OR`, `NOT`, 괄호를 통한 그룹화 지원
- 문자열 및 날짜값: 큰따옴표로 감씀 — `?filter=createdAt > "2024-01-01T00:00:00Z"`
- 숫자값: 따옴표 없이 사용 — `?filter=price >= 100`
- 불리언값: `true` / `false` — `?filter=isPublished = true`
- 중첩 필드 접근: 점(`.`) 표기법 사용 — `?filter=author.name = "Kim"`
- 배열 형태의 포함 여부 검사: `has()` 문법 사용 — `?filter=has(tags, "golang")`
- 올바르지 않은 형식의 필터 식 요청 시 → `400 Bad Request`와 함께 RFC 9457 에러 메시지를 반환합니다.
- 정렬 파라미터: `?orderBy=createdAt:desc` / 다중 정렬: `?orderBy=createdAt:desc,title:asc`
- **전체 텍스트 검색 (M-7):** 여러 필드에 대한 키워드 기반 통합 검색은 `q` 파라미터를 사용합니다 (예: `?q=검색어`). `[T2]`

---

## 부분 응답 및 리소스 확장

**부분 응답 (Partial Response) (AIP-157):** 특정 필드들만 선택하여 응답받고 싶을 때 `fields` 파라미터를 제공합니다. `[T2]`
- 문법: `?fields=id,title,author.name` (쉼표로 나열된 필드 경로)
- 하위 중첩 필드는 점 표기법 사용: `?fields=id,author.name,author.email`
- `id` 필드는 `fields` 파라미터 지정 값과 관계없이 항상 응답 본문에 포함됩니다.
- 목록 조회 시에도 개별 항목마다 동일하게 적용됩니다.
- `INPUT_ONLY` (입력 전용) 필드는 클라이언트가 `fields`에 지정하더라도 응답에서 강제 제외됩니다.
- **ETag 상호작용:** 부분 응답의 경우 Strong ETag 계산을 하지 말고 Weak ETag (`W/"..."`)를 사용하거나 ETag 헤더를 제외하여 서버 연산 성능을 보장해야 합니다.
- 스키마에 없는 필드를 요청한 경우 → `400 Bad Request` 반환.

**리소스 확장 (Resource Expansion/Embed) (M-4):** 연관된 하위 리소스를 응답 본문에 함께 포함하기 위해 `expand` 파라미터를 사용합니다. `[T2]`
- 문법: `?expand=author,comments.author`
- **전체 엔티티 제한 필수 (Total Entity Limit):** 서버는 단일 요청에서 함께 확장되어 반환될 수 있는 *총 엔티티 개수*에 대한 엄격한 제한(예: 최대 100개)을 두어 N+1 쿼리 공격이나 DoS를 예방해야 합니다. 제한 초과 시 → `400 Bad Request`.
- 깊이 제한: 확장 깊이는 기본적으로 최대 3단계로 제한할 것을 권장합니다.
- 선택적 확장: 클라이언트는 정말 필요한 연관 리소스만 골라 확장해야 합니다.
- 확장 실패 처리: 연관 리소스를 가져오던 중 오류(예: 권한 없음)가 발생해도, 메인 요청 자체를 실패시키지 말고 에러 대상 리소스만 생략하거나 null/플레이스홀더로 대체해 반환해야 합니다.

---

## 벌크(일괄) 연산

벌크 연산은 다수의 리소스를 단일 요청으로 처리하여 네트워크 왕복 비용을 절약하는 기능입니다.

✅ **필수**: 벌크 연산은 컬렉션 URL 뒤에 콜론(`:`) 구문을 사용하는 커스텀 메서드로 정의해야 합니다. `[T3]`

| 동작 메서드 | 목적 | 엔드포인트 |
|--------|------|----------|
| `batchCreate` | 복수 리소스 대량 생성 | `POST /{resources}:batchCreate` |
| `batchGet` | ID 목록을 통해 다수 리소스 한 번에 조회 | `POST /{resources}:batchGet` |
| `batchUpdate` | 복수 리소스 대량 수정 | `POST /{resources}:batchUpdate` |
| `batchDelete` | 복수 리소스 대량 삭제 | `POST /{resources}:batchDelete` |

✅ **필수**: 요청 본문에는 처리할 객체 목록이나 ID 배열이 포함되어야 합니다. `[T3]`
✅ **필수**: 응답 본문에는 요청 본문 순서에 대응하는 결과 배열이 포함되어야 합니다. `[T3]`
⚠️ **권장**: 단일 요청의 수행 시간이 너무 길어지는 것을 방지하기 위해 벌크 처리할 수 있는 최대 항목 수(예: 최대 100개)를 제한합니다. `[T3]`
⚠️ **권장**: 최대 항목 제한을 초과하는 요청의 경우 `400 Bad Request` 에러를 반환합니다. `[T3]`
✅ **필수**: **원자적(Atomic) vs 비원자적(Non-atomic):** 일괄 연산이 '모두 성공 또는 실패(all-or-nothing)' 인지, 아니면 '일부 성공 허용(partial success)' 인지 API 설계에 명시합니다. 필요한 경우 `atomic` 쿼리 파라미터로 선택하게 할 수 있습니다. `[T3]`
✅ **필수**: 일부 성공을 허용하는 비원자적 벌크 연산의 경우, 응답에 각 항목의 성공 또는 실패 여부(실패한 항목에 대해서는 RFC 9457 에러 세부 설명 포함)를 담을 수 있는 스키마 구조를 사용해야 합니다. `[T3]`

**요청 본문 예시 (batchCreate):**

```json
POST /articles:batchCreate
{
  "requests": [
    { "title": "Article 1", "content": "..." },
    { "title": "Article 2", "content": "..." }
  ]
}
```

**응답 본문 예시 (일부 성공 허용형 batchCreate):**

```json
{
  "results": [
    { "status": 201, "resource": { "id": "1", "title": "Article 1", ... } },
    { "status": 400, "error": { "title": "Validation Failed", "detail": "Title is required", ... } }
  ]
}
```

---

## API 버전 관리

**URL 경로를 활용한 버전 지정은 엄격히 금지됩니다** — `/v1/articles` 형태는 하나의 리소스에 대해 다수의 주소를 갖게 되어 REST 핵심 원칙을 위반합니다. `[T1]`

**헤더 기반 버전 지정을 필수로 적용해야 합니다:** `[T1]`
```
Api-Version: 2024-01-20   (ISO 8601 날짜 형식 사용)
```

> RFC 6648/BCP 178 표준에 따라 커스텀 헤더에 `X-` 접두사를 붙이지 않습니다.

- 버전 헤더 없이 온 요청에 대해서는 `400 Bad Request` 에러로 거절합니다 — 서버가 최신 버전으로 자동 임의 할당하는 방식은 금지됩니다. `[T1]`
- 응답에는 항상 실제 처리 시 적용된 버전 명세를 포함해야 합니다. `[T1]`
- 이전 지원 대상 버전은 Deprecation 선언 후 최소 6개월 동안 정상 유지해야 합니다. `[T2]`

**하위 호환성을 깨는 변경 사항** (새로운 `Api-Version` 날짜 지정이 필요한 경우): `[T1]`

| 유형 | 예시 |
|----------|----------|
| 삭제 | 엔드포인트, 특정 필드, 에넘 값의 삭제 |
| 변경 | 필드명이나 엔드포인트 경로 이름 수정 |
| 타입 변경 | 필드 타입이나 형식 교체 (예: 문자열 → 정수) |
| 제약 사항 강화 | 선택 필드 → 필수 필드로 변경, 신규 필수 필드 추가, 정규식 등 검사 강화 |
| 의미론적 변경 | 상태 코드 의미 변경, 기본값 변경, 기본 정렬 기준 수정 |

**호환되는 변경 사항** (버전 날짜 갱신 없이 배포 가능): `[T2]`

| 유형 | 예시 |
|----------|----------|
| 추가 | 신규 엔드포인트 추가, 새로운 선택적 필드 추가, 새로운 에넘 값 추가, 선택적 쿼리 파라미터 추가 |
| 제약 사항 완화 | 필수 필드 → 선택적 필드로 변경, 유효성 검사 범위 완화 |
| 메타데이터 | 응답 필드의 순서 변경, 설명(description) 수정 |

**호환성 보장 원칙:** `[T1]`
- 클라이언트는 응답 본문에 알 수 없는 필드가 있더라도 무시하고 정상 처리해야 합니다 (Tolerant Reader 원칙).
- 서버는 요청 본문에 정의되지 않은 알 수 없는 필드가 오더라도 무시하고 처리해야 합니다.
- 에넘 값은 항상 확장 가능하므로, 클라이언트는 새로운 신규 에넘 값을 읽더라도 정상적으로 폴백 처리해야 합니다.

---

## Deprecation (지원 종료 예정 선언)

사용이 중단될 예정인 API는 다음 응답 헤더를 필수적으로 제공해야 합니다 (RFC 9745, RFC 8594): `[T1]`

```
Deprecation: true
Sunset: Sat, 01 Jan 2025 00:00:00 GMT
Link: <https://api.example.com/new-resource>; rel="successor-version"
```

- 지원 종료(Sunset) 예정 시간의 최소 6개월 전에 Deprecation 헤더가 적용되어야 합니다. `[T1]`

---

## 처리율 제한 및 재시도 (Rate Limiting & Retries) (M-5)

- **응답 헤더 기본 탑재:** 모든 응답에는 `RateLimit: limit=N, remaining=N, reset=N` 및 `RateLimit-Policy: N;w=N` 헤더를 포함합니다. `[T2]`
- **429 Too Many Requests:** 응답에 `Retry-After` (재시도 대기 초 단위 시간) 헤더 및 RFC 9457 Problem Details 형식 에러 본문을 함께 보냅니다. `[T2]`
- **클라이언트 재시도 전략:** `[T2]`
  - 응답에 `Retry-After`가 존재하면 해당 시간만큼 대기 후 재시도합니다.
  - 기타 일시적 에러(502, 503, 504 등)에 대해서는 **지터가 적용된 지수 백오프(Exponential Backoff with Jitter)** 알고리즘을 사용합니다.
  - 최대 재시도 횟수는 3~5회 이내로 제한해야 합니다.

---

## 캐싱 (M-2)

- **`Cache-Control` 헤더:** 캐싱 범위와 유효 기간 지시어(`public`, `private`, `no-cache`, `max-age` 등)를 올바르게 명시합니다. `[T2]`
- **`ETag` 필수 제공:** 모든 변경 가능 리소스는 응답에 ETag를 제공해야 합니다 ([낙관적 동시성 제어](#낙관적-동시성-제어) 참고). `[T2]`
- **`Last-Modified`:** 구형 클라이언트 호환성을 위해 ETag와 병행하여 자원 수정 시각 헤더를 제공할 수 있습니다. `[T3]`
- **버전 캐시 Vary 헤더 지정:** 헤더 기반 버전 관리를 구현하는 모든 API는 CDN 및 프록시 캐시의 오염을 방지하기 위해 응답 헤더에 반드시 `Vary: Api-Version` (콘텐츠 협상을 병행하는 경우 `Vary: Accept, Api-Version`)을 포함해야 합니다. `[T1]`

---

## 장시간 실행 작업 (Long-Running Operations)

- 작업 수행 시간이 길어지는 연산의 경우 `201 Created`와 함께 작업의 진행 상태를 추적할 수 있는 LRO(Task) 리소스의 URL을 `Location` 헤더로 반환합니다. `[T3]`
- LRO 리소스의 진행 상태는 `status` 필드로 표현합니다: `PENDING` → `IN_PROGRESS` → `COMPLETED` | `FAILED` `[T3]`
- 클라이언트는 `Location`에 기술된 주소로 `GET` 폴링을 수행하여 진행 상황을 추적합니다. `[T3]`
- 작업이 실패한 경우, 응답 본문에 구체적인 실패 에러 객체를 포함해야 합니다. `[T3]`

---

## Idempotency-Key (멱등성 키) (AIP-155)

- 이중 요청 발생 시 치명적인 위험이 있는 POST 엔드포인트(결제, 주문 생성 등)는 `Idempotency-Key` 헤더를 지원해야 합니다. `[T3]`
- 클라이언트는 요청마다 고유한 UUID v4 토큰을 생성해 헤더로 보냅니다. `[T3]`
- 서버는 첫 번째 요청을 정상 처리하고, 생성한 응답 데이터 및 상태를 키값과 매칭하여 저장해 둡니다. `[T3]`
- 동일한 키값으로 다시 동일 요청이 들어오면, 실제 로직을 재수행하지 않고 저장되어 있던 이전 응답 데이터를 즉시 반환합니다. `[T3]`
- 저장된 멱등성 키의 유효 기간은 최소 24시간 이상 유지되어야 합니다. `[T3]`
- 재정적 거래 부수 효과가 발생하는 결제성 POST 요청은 멱등성 키 제공이 필수 사항이어야 합니다. `[T3]`

---

## OpenAPI 스펙 작성 규칙

모든 API 서비스는 최신 사양을 담은 OpenAPI 3.0+ 스펙 문서를 작성하고 소스코드의 유일한 진실의 원천(API-First)으로 유지해야 합니다. `[T2]`

| 규칙 | 적용 티어 | 설명 |
|------|------|-------------|
| `description` 필수 | `[T2]` | 모든 엔드포인트, 매개변수, 스키마 속성에는 명확한 설명(description)이 작성되어야 합니다. |
| `operationId` 필수 | `[T2]` | 자동 코드 생성 및 문서 자동화를 위해 모든 API 연산은 고유한 `operationId`를 가져야 합니다. |
| `example` 권장 | `[T3]` | 주요 객체 스키마 및 매개변수 명세에는 구체적인 `example` 데이터를 제공해야 합니다. |
| `readOnly`/`writeOnly` 설정 | `[T2]` | 생성 전용 필드는 `writeOnly: true`, 서버 생성 전용 필드는 `readOnly: true`로 OpenAPI 매핑을 매칭합니다. |
| `nullable` 최소화 | `[T2]` | 필드 부재/생략 원칙을 따르며, 정말 명시적으로 NULL 전달이 비즈니스상 필요할 때만 `nullable: true`를 씁니다. |
| 공용 에러 스키마 활용 | `[T2]` | RFC 9457 문제 세부 정보 스키마는 공통 컴포넌트로 분리하고 `$ref` 참조 형식으로 재사용합니다. |
| 내부 API 표시 | `[T3]` | 외부 비공개 엔드포인트는 `x-internal: true` 확장 태그를 붙여 표시합니다. |
| 자동 규격 검사 | `[T1]` | CI 파이프라인 빌드 시 OpenAPI 스타일 린터(예: Spectral, Zally)를 실행하여 자동 검증을 거쳐야 합니다. |

---

## 인증 및 보안

- **HTTPS 통신 필수 (H-5):** 전송 구간 암호화를 보장하기 위해 모든 API는 반드시 HTTPS (TLS 1.2 이상) 프로토콜만 제공해야 합니다. `[T1]`
- **보안 헤더 탑재 필수:** 응답에는 항상 `X-Content-Type-Options: nosniff` 및 `Strict-Transport-Security` 헤더가 탑재되어야 합니다. `[T1]`
- JWT 인증에는 `Authorization: Bearer {token}` 표준 방식을 사용합니다. `[T1]`
- API Key 인증에는 `Authorization: ApiKey {key}` 형식을 활용합니다. `[T1]`
- 인증에 관련한 토큰이나 키값을 쿼리 파라미터로 실어 보내지 마십시오 (서버 액세스 로그에 무방비로 기록됨). `[T1]`
- `401 Unauthorized` 실패 시: 인증 누락/만료를 알리고 `WWW-Authenticate` 헤더를 반드시 포함합니다. `[T1]`
- `403 Forbidden` 실패 시: 이미 인증은 완료되었으나 요청한 리소스의 권한이 없음을 알립니다. `[T1]`
- 민감한 데이터는 절대 URL 쿼리 문자열에 담아 호출하지 마십시오. `[T1]`

**리소스 수준 권한 검사 (BOLA 예방):** `[T1]`
- 서버는 단건 리소스 접근 요청(`/{resource}/{id}`)을 처리할 때마다 요청을 보낸 주체가 해당 리소스의 실제 소유주/권한자인지 매번 재검증해야 합니다.

**대량 할당 취약점 차단 (BOPA 예방):** `[T1]`
- DTO(데이터 전송 객체) 역직렬화 시 허용 필드 목록(Allowlist)만 매핑되도록 처리합니다. 클라이언트가 `PATCH` 바디나 `updateMask`를 조작하여 권한 필드(`role`, `isVerified` 등)를 임의로 변경할 수 있어서는 안 됩니다.

**CORS (교차 출처 리소스 공유) 설정 (H-4):** `[T2]`
- 서버는 허용할 Origin 도메인을 `Access-Control-Allow-Origin`에 명시해야 합니다 (자격 증명을 동반한 통신의 경우 와일드카드 `*` 사용 금지).
- `Access-Control-Allow-Methods`를 통해 클라이언트 접근 허용 HTTP 메서드 목록을 제공합니다.
- `Access-Control-Max-Age` (예: 86400초, 1일) 값을 충분히 주어 프리플라이트 요청이 클라이언트 브라우저에 캐싱되도록 함으로써 불필요한 네트워크 지연을 방지합니다.
- 클라이언트 측에서 특수 커스텀 헤더를 읽어야 하는 경우(예: `Total-Count`, `Request-Id`), 반드시 `Access-Control-Expose-Headers` 목록에 추가해 주어야 합니다.

**웹훅 (Webhooks) 연동 (M-6):** `[T3]`
- **페이로드 포맷:** 정형화된 공통 래퍼 구조를 씁니다: `{"id": "evt_...", "type": "resource.event", "created": 123456789, "data": { ... }}`.
- **서명 검증:** 발송하는 웹훅 본문 데이터는 사전 공유한 보안 비밀키(Secret)와 HMAC-SHA256 해시를 사용해 서명하고, 이 서명값을 `X-Hub-Signature-256` 헤더에 실어 보냅니다.
- **멱등성 처리:** 웹훅 수신 핸들러는 네트워크 지연 등으로 인한 중복 전달 상황을 고려하여 멱등적으로 설계되어야 합니다.
- **재시도 정책:** 수신 서버가 정상 응답하지 않을 경우, 전송 서버는 지수 백오프(Exponential Backoff)를 적용하여 일정 횟수(예: 24시간 동안 5~10회) 재시도를 시도해야 합니다.

**헬스 체크 (Health Check) API (L-1):** `[T2]`
- **엔드포인트:** 자원 모니터링을 위해 기본적으로 `GET /health` 경로를 개방합니다.
- **응답 본문:** 상태가 정상인 경우 `200 OK`와 함께 `{"status": "UP"}`을 반환합니다.
- **Shallow vs Deep 체크:**
  - Shallow: 단지 웹 애플리케이션 서비스가 살아 있는지 빠르게 체크해 응답합니다.
  - Deep: 내부 DB 접속 여부, 캐시 및 외부 필수 연계 서비스 정상 동작 등 하부 의존성까지 통틀어 점검합니다. 로드 밸런서 헬스 체크 시 deep 방식을 전면 사용하면 연쇄 장애가 확산할 위험이 있어 신중히 구별 적용해야 합니다.

---

## 참고 표준 (References)

본 가이드라인이 근거로 삼는 표준 목록입니다. 본문의 인라인 `(AIP-xxx)` / RFC 태그는 각 규칙의 출처를 표시하며, 아래 표는 정식 명세로 연결되는 크로스워크입니다.

### Google AIP (API Improvement Proposals — https://google.aip.dev)

| 표준 | 제목 | 적용 위치 |
|------|------|-----------|
| AIP-121 | 리소스 지향 설계 (Resource-oriented design) | URL 설계, CRUD 동작, 리소스 스키마 |
| AIP-134 | 표준 메서드: 수정(Update) | CRUD 동작 (PATCH / `updateMask`) |
| AIP-136 | 커스텀 메서드 | URL 설계, 액션 |
| AIP-154 | 리소스 신선도 검증(etag) | 낙관적 동시성 제어 |
| AIP-155 | 요청 멱등성 | Idempotency-Key |
| AIP-157 | 부분 응답 | 부분 응답 |
| AIP-158 | 페이지네이션 | 컬렉션 및 페이지네이션 |
| AIP-160 | 필터링 | 필터링 및 정렬 |
| AIP-163 | 변경 미리 검증(Dry Run) | 변경 미리 검증 / Dry Run |
| AIP-164 | 소프트 딜리트 | 소프트 딜리트 |
| AIP-193 | 에러 표현 | 에러 응답 |
| AIP-203 | 필드 행위(Field behavior) | 리소스 스키마 및 필드 규칙 |
| AIP-216 | 리소스 생명주기 상태 | 리소스 상태 에넘 패턴 |

### RFC / 웹 표준

| 표준 | 제목 | 적용 위치 |
|------|------|-----------|
| RFC 2119 / 8174 | 요구 수준 키워드 (MUST/SHOULD/MAY) | 문서 전반 |
| RFC 3339 | 인터넷 날짜/시간 표기 | JSON 포맷 |
| RFC 6648 / BCP 178 | `X-` 헤더 접두사 사용 중단 | 헤더, API 버전 관리 |
| RFC 7396 | JSON Merge Patch | JSON 포맷, CRUD 동작 |
| RFC 7807 / 9457 | HTTP API 문제 상세(Problem Details) | 에러 응답 |
| RFC 8288 | 웹 링킹 (`Link` 헤더) | 헤더, 페이지네이션 |
| RFC 8594 | Sunset HTTP 헤더 | Deprecation |
| RFC 9745 | Deprecation HTTP 헤더 | Deprecation |
| W3C Trace Context | `traceparent` / `tracestate` 전파 | 헤더 |
