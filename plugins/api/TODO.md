# API Guidelines — Google AIP 기반 개선 로드맵

> **작성일:** 2026-04-03
> **현재 버전:** v0.0.10 (111개 규칙, Writing 98.2% / Review 97.3% 커버리지)
> **목표:** 리소스 수명주기 전체를 커버하는 실용적 API 가이드라인 완성

---

## 배경

현재 플러그인은 URL 설계, HTTP 메서드, 상태 코드, JSON 형식, 에러 처리, 페이지네이션 등
"일반적인 REST API 설계"를 잘 커버한다. ADR 0005에서 Google AIP를 부분 도입(리소스 중심 설계,
콜론 커스텀 메서드, PATCH 기본)했으나, **안전한 업데이트와 리소스 수명주기** 영역에 갭이 있다.

이 문서는 Google AIP 대비 현재 플러그인의 갭을 분석하고, 도입 우선순위를 정리한다.

---

## 도입 예정 — 핵심 5개 (목표: 90%+ 완성도)

### 1. Field Behavior Annotations (AIP-203)

**문제:** 현재 필드 분류가 "create-only / read-only / mutable" 3종뿐이고, API 문서나 스키마에서 필드 동작을 명시하는 표준 체계가 없다.

**도입 내용:**
- 필드 동작 annotation 6종: `REQUIRED`, `OUTPUT_ONLY`, `INPUT_ONLY`, `IMMUTABLE`, `OPTIONAL`, `IDENTIFIER`
- Create/Update 시 각 annotation별 서버 동작 규칙
- OpenAPI 스키마에서의 표현 방법 (`readOnly`, `writeOnly`, `x-field-behavior`)

**기대 효과:** 클라이언트-서버 간 필드 계약이 명확해지고, 코드 생성/문서 자동화 가능

---

### 2. ETag 기반 낙관적 동시성 제어 (AIP-154)

**문제:** 현재 409 Conflict만 언급하고, 동시 수정을 감지하는 구체적 메커니즘이 없다. 두 사용자가 동시에 같은 리소스를 수정하면 마지막 쓰기가 이전 변경을 덮어쓴다.

**도입 내용:**
- 리소스에 `etag` 필드 포함 (opaque string, 변경 시마다 갱신)
- Update/Delete 요청에 `If-Match` 헤더로 etag 전달
- 불일치 시 `409 Conflict` + 현재 리소스 반환
- etag 미전달 시 무조건 실행 (opt-in 방식)

**기대 효과:** 데이터 손실 방지, 특히 협업 환경에서 안전한 동시 편집

---

### 3. State Enum 표준 패턴 (AIP-216)

**문제:** 현재 enum UPPER_SNAKE_CASE만 규정하고, 리소스 상태를 표현하는 패턴이 없다. `status` vs `state` 혼용, 초기값 처리, 상태 전이 규칙 등이 미정의.

**도입 내용:**
- 상태 필드명은 `state` (not `status` — `status`는 HTTP 상태 코드와 혼동)
- 첫 번째 값은 항상 `STATE_UNSPECIFIED` (unknown/default)
- 상태 전이는 커스텀 메서드로 수행 (PATCH로 `state` 직접 변경 금지)
- OUTPUT_ONLY로 표시
- 일반적 패턴: `ACTIVE/INACTIVE`, `PENDING/RUNNING/SUCCEEDED/FAILED`

**기대 효과:** 상태 관리의 일관성, 상태 전이 side-effect 명확화

---

### 4. Soft Delete (AIP-164)

**문제:** 현재 DELETE → 204만 규정. 실무에서 대부분의 서비스는 즉시 영구 삭제가 아닌 "삭제 표시 후 복구 가능" 패턴이 필요하다.

**도입 내용:**
- `deleteTime`, `expireTime` 표준 필드
- `POST /{resource}/{id}:undelete` 복구 메서드
- List에서 기본적으로 soft-deleted 리소스 제외, `showDeleted=true`로 포함
- Get은 soft-deleted 리소스 정상 반환 (상태 표시와 함께)
- 보존 기간(기본 30일) 후 자동 영구 삭제

**기대 효과:** 실수로 인한 데이터 손실 방지, 규정 준수(데이터 보존 요건)

---

### 5. Change Validation / Dry Run (AIP-163)

**문제:** Create/Update 요청을 실제로 실행하지 않고 사전 검증하는 표준 패턴이 없다.

**도입 내용:**
- `validateOnly=true` 쿼리 파라미터
- true이면 검증만 수행, 변경 없음, 부수 효과 없음
- 성공 시 실제 실행 시와 유사한 응답 반환 (서버 생성 필드 제외 가능)
- 실패 시 동일한 에러 형식

**기대 효과:** 비용이 큰 작업(결제, 주문 등)의 사전 검증, 프론트엔드 미리보기

---

## ✅ 완료 — 추가 3개 (v0.0.10, ADR-0008)

### 6. Filter 문법 표준화 (AIP-160) — 완료

**결정:** 개별 쿼리 파라미터 방식을 `filter` 표현식으로 **전면 교체**
**구현:** `?filter=status = "ACTIVE" AND price >= 1000` 표현식 문법, 비교/논리/괄호/dot notation 지원

### 7. Field Mask 필수화 (AIP-161) — 완료

**결정:** updateMask **필수화** (ADR-0005 번복)
**구현:** 모든 PATCH에 `updateMask` 필수, Field Behavior 상호작용 규칙 전면 정의

### 8. Partial Response (AIP-157) — 완료

**결정:** `fields` 파라미터 기본 규칙 추가
**구현:** `?fields=id,title,author.name`, dot notation, List 적용, id 항상 포함, ETag 전체 리소스 기준

---

## 의도적 미채택 (ADR 0005 결정 유지)

| AIP | 주제 | 미채택 이유 |
|-----|------|------------|
| AIP-122/123 | Full resource name / type | gRPC 중심 패턴, REST URL이 이미 역할 수행 |
| AIP-191 | Proto 파일 명명 | gRPC/protobuf 전용 |
| AIP-161 FieldMask 필수화 | updateMask 필수 | 클라이언트 부담 과다 |
| AIP-159 | 교차 컬렉션 조회 (와일드카드 `-`) | REST 라우팅과의 호환성 문제 |
| AIP-217 | Unreachable resources | 분산 시스템 특화, 범용 가이드라인 범위 초과 |

---

## 플러그인 고유 강점 (AIP보다 나은 점, 유지)

| 영역 | 플러그인 방식 | AIP 방식 | 유지 이유 |
|------|-------------|----------|----------|
| 에러 형식 | RFC 9457 Problem Details | 자체 에러 모델 | 표준 준수, 범용성 |
| 페이지네이션 | Top-level array + Link 헤더 | Wrapper object + nextPageToken | HTTP 표준(RFC 8288) 준수 |
| API 버전 | `Api-Version` 날짜 헤더 | URL 경로 `/v1/` | URL 중립성 유지 |
| Deprecation | RFC 9745 헤더 | 없음 | 표준 기반 |
| 멱등성 | `Idempotency-Key` | 없음 | 실용적 |
| LRO | 도메인 리소스 직접 반환 | 범용 Operation 리소스 | 단순하고 직관적 |

---

## 다음 단계

모든 TODO 항목 완료. 추가 개선이 필요한 경우 새 TODO 작성.
