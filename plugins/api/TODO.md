# API 플러그인 — 업계 표준 갭 분석 로드맵

> 작성일: 2026-04-06
> 기준 버전: ppzxc/api v0.1.1 (115개 규칙, Writing 100% / Review 100% 커버리지)
> 목적: 업계 6대 리더 대비 누락 항목 식별 및 구현 완료 보고

---

## 비교 대상

| 약칭 | 출처 | 특징 |
|------|------|------|
| **ppzxc/api** | 현재 플러그인 v0.1.1 | Google AIP 완전 도입, RFC 중심 |
| **AIP** | Google API Improvement Proposals | gRPC-first, 가장 체계적 |
| **MS** | Microsoft REST API Guidelines | 엔터프라이즈, Azure 생태계 |
| **Stripe** | Stripe API Reference | 개발자 경험 최고 평가 |
| **Zalando** | Zalando RESTful API Guidelines | 유럽 대규모 마이크로서비스 |
| **GitHub** | GitHub REST API | 대규모 퍼블릭 API 운영 경험 |
| **JSON:API** | jsonapi.org Specification | 구조화된 JSON 표준 |

---

## 1. 핵심 설계 원칙

| 항목 | ppzxc/api | AIP | MS | Stripe | Zalando | GitHub | JSON:API |
|------|-----------|-----|-----|--------|---------|--------|---------|
| 리소스 중심 설계 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| RFC 2119 규범 수준 | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | ✅ |
| OpenAPI 스펙 연동 가이드 | ✅ | ⚠️ proto | ✅ | ✅ | ✅ 필수 | ✅ | ❌ |
| API Linter/자동 검증 도구 | ✅ CI | ✅ aip-linter | ❌ | ❌ | ✅ Zally | ❌ | ❌ |
| 다국어 문서 (한/영) | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |

---

## 2. URL 설계

| 항목 | ppzxc/api | AIP | MS | Stripe | Zalando | GitHub | JSON:API |
|------|-----------|-----|-----|--------|---------|--------|---------|
| 복수 명사 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| kebab-case URL | ✅ | ✅ | ❌ camel | ❌ snake | ✅ | ✅ | ✅ |
| 중첩 깊이 제한 | ✅ 1단계 | 제한없음 | 제한없음 | ✅ 1단계 | ⚠️ ≤3 | ⚠️ 2단계 | 무관 |
| Non-CRUD 콜론 액션 | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| 전체 리소스 이름(`//api/..`) | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |

---

## 3. HTTP 메서드 & CRUD

| 항목 | ppzxc/api | AIP | MS | Stripe | Zalando | GitHub | JSON:API |
|------|-----------|-----|-----|--------|---------|--------|---------|
| PATCH 기본 수정 | ✅ | ✅ | ✅ | ✅ POST | ✅ | ✅ | ✅ |
| PUT 전체 교체 예외 전용 | ✅ | ✅ | ✅ | ❌ 미사용 | ✅ | ❌ | ✅ |
| POST 201+Location | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| DELETE 204 | ✅ | ✅ | ✅ | ❌ 200+obj | ✅ | ✅ | ✅ |
| HEAD/OPTIONS 지원 | ✅ | ❌ | ✅ | ❌ | ✅ | ✅ | ❌ |

---

## 4. 에러 처리

| 항목 | ppzxc/api | AIP | MS | Stripe | Zalando | GitHub | JSON:API |
|------|-----------|-----|-----|--------|---------|--------|---------|
| RFC 9457 Problem Details | ✅ | ❌ 자체 | ❌ 자체 | ❌ 자체 | ✅ | ❌ 자체 | ❌ 자체 |
| 필드 수준 에러 (validation) | ✅ | ✅ details[] | ✅ details[] | ❌ | ✅ | ❌ | ✅ errors[].source |
| 에러 코드 체계 (machine-readable) | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| 재시도 가이드 (5xx 포함) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| i18n 에러 메시지 | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ |

---

## 5. 페이지네이션

| 항목 | ppzxc/api | AIP | MS | Stripe | Zalando | GitHub | JSON:API |
|------|-----------|-----|-----|--------|---------|--------|---------|
| Cursor 기반 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Offset 기반 | ✅ | ❌ | ✅ | ❌ | ✅ | ✅ | ✅ |
| Keyset 기반 | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ |
| Top-level array 응답 | ✅ | ❌ wrapper | ❌ wrapper | ❌ wrapper | 혼합 | ✅ | ❌ wrapper |
| Link 헤더 네비게이션 | ✅ | ❌ nextPageToken | ❌ @odata | ❌ has_more | ✅ | ✅ | ❌ links{} |
| Total-Count 헤더 | ✅ | ⚠️ total_size | ✅ | ⚠️ | ❌ 비권장 | ❌ | ⚠️ meta |
| 기본 페이지 크기 명시 | ✅ 20 | ✅ | ✅ | ✅ 10 | ✅ | ✅ 30 | ❌ |
| 최대 페이지 크기 명시 | ✅ 100 | ✅ 1000 | ✅ | ✅ 100 | ✅ | ✅ 100 | ❌ |

---

## 6. 필터링 & 정렬

| 항목 | ppzxc/api | AIP | MS | Stripe | Zalando | GitHub | JSON:API |
|------|-----------|-----|-----|--------|---------|--------|---------|
| 동등 필터 (`?status=active`) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| 범위 필터 (Min/Max) | ✅ | ✅ filter | ✅ $filter | ✅ gte/lte | ✅ | ❌ | ❌ |
| 복합 필터 문법 (AND/OR) | ✅ | ✅ AIP-160 CEL | ✅ OData | ❌ | ✅ | ❌ | ❌ |
| 전문 검색 (`q=`) | ✅ | ❌ | ✅ $search | ❌ | ✅ | ✅ | ❌ |
| 정렬 (`orderBy`) | ✅ | ✅ | ✅ $orderby | ❌ | ✅ sort | ✅ | ✅ |

---

## 7. 버전관리

| 항목 | ppzxc/api | AIP | MS | Stripe | Zalando | GitHub | JSON:API |
|------|-----------|-----|-----|--------|---------|--------|---------|
| 날짜 기반 버전 헤더 | ✅ Api-Version | ❌ URL | ❌ URL | ✅ Stripe-Version | ❌ URL | ❌ URL | 미정 |
| Breaking Change 정의 | ✅ | ✅ AIP-180 | ✅ | ✅ | ✅ | ✅ | ❌ |
| 하위 호환성 정책 | ✅ | ✅ 상세 | ✅ 상세 | ✅ | ✅ 상세 | ✅ | ❌ |
| Deprecation 헤더 | ✅ RFC 9745 | ❌ | ✅ | ✅ | ✅ | ✅ | ❌ |

---

## 8. 고급 패턴

| 항목 | ppzxc/api | AIP | MS | Stripe | Zalando | GitHub | JSON:API |
|------|-----------|-----|-----|--------|---------|--------|---------|
| ETag / 낙관적 동시성 | ✅ | ✅ AIP-154 | ✅ | ❌ | ✅ | ✅ | ❌ |
| Soft Delete | ✅ | ✅ AIP-164 | ❌ | ❌ | ❌ | ❌ | ❌ |
| Dry Run / validateOnly | ✅ | ✅ AIP-163 | ❌ | ❌ | ❌ | ❌ | ❌ |
| Field Behavior Annotations | ✅ | ✅ AIP-203 | ❌ | ❌ | ✅ | ❌ | ❌ |
| State Enum 표준 | ✅ | ✅ AIP-216 | ❌ | ❌ | ❌ | ❌ | ❌ |
| 멱등성 키 (Idempotency-Key) | ✅ | ❌ | ❌ | ✅ | ✅ | ❌ | ❌ |
| Rate Limiting 헤더 | ✅ | ❌ | ✅ | ✅ | ✅ | ✅ | ❌ |
| LRO (장기 실행 작업) | ✅ 도메인 리소스 | ✅ Operation | ✅ 202+poll | ❌ | ✅ 202+poll | ❌ | ❌ |
| Partial Response (`fields=`) | ✅ | ✅ FieldMask | ✅ $select | ✅ expand | ✅ fields | ❌ | ✅ sparse |
| Expand/Embed | ✅ | ❌ | ✅ $expand | ✅ expand[] | ✅ embed | ❌ | ✅ include |
| Bulk Operations | ✅ | ❌ | ✅ $batch | ❌ | ✅ | ❌ | ✅ |
| Webhooks / Events | ✅ | ❌ | ❌ | ✅ 상세 | ✅ | ✅ | ❌ |
| Request ID / 분산 추적 | ✅ | ❌ | ✅ | ✅ | ✅ X-Flow-ID | ✅ | ❌ |
| Caching 가이드 | ✅ | ❌ | ✅ | ❌ | ✅ | ✅ | ❌ |
| Health Check 엔드포인트 | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ |

---

## 9. 보안

| 항목 | ppzxc/api | AIP | MS | Stripe | Zalando | GitHub | JSON:API |
|------|-----------|-----|-----|--------|---------|--------|---------|
| Bearer 토큰 / 인증 방식 | ✅ | ✅ OAuth2 | ✅ OAuth2+OIDC | ✅ API Key | ✅ OAuth2 | ✅ PAT/OAuth | ❌ |
| 401 vs 403 구분 | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | ❌ |
| CORS 가이드 | ✅ | ❌ | ✅ | ✅ | ✅ | ✅ | ❌ |
| TLS/HTTPS 명시 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| 민감 데이터 마스킹 | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ | ❌ |

---

## 10. 갭 요약 — 구현 로드맵

> **분류 기준** (v0.0.8 기준 — 현재 v0.1.0에서 전항목 완료)
> - 🔴 Critical: 업계 4곳 이상 보유 + ppzxc/api 완전 누락(❌)
> - 🟡 High: 업계 3~4곳 보유 + ppzxc/api 완전 누락(❌)
> - 🟠 Medium: 업계 2~3곳 보유, 또는 4곳 이상이더라도 ppzxc/api가 ⚠️ 부분 구현 상태
> - 🔵 Low: 업계 1~2곳 보유

### ✅ Critical (완료 — 업계 4곳 이상 보유)

| # | 항목 | 보유 업체 수 | 구현 방향 |
|---|------|-------------|-----------|
| C-1 | **OpenAPI 스펙 연동 가이드 ✅** | 4/6 | SKILL.md에 OpenAPI `example`, `x-internal`, nullable 처리 등 섹션 추가 |
| C-2 | **Breaking Change 정의 및 호환성 정책 ✅** | 5/6 | README에 비호환 변경 목록 명시, `Api-Version` 날짜 기반과 연계 |
| C-3 | **Request ID / 분산 추적 헤더 ✅** | 4/6 | `Request-Id` (UUID v4) 요청 수신 시 생성, 응답 에코, 로그 연계 |

### ✅ High (완료 — 업계 3~4곳 보유, ppzxc/api 구현 완료)

| # | 항목 | 보유 업체 수 | 구현 내용 |
|---|------|-------------|-----------|
| H-1 | **필드 수준 에러 (validation errors)** | 4/6 | RFC 9457 `errors[]` + AIP-193 `fieldViolations` |
| H-2 | **에러 코드 체계 (machine-readable code)** | 3/6 | `code` UPPER_SNAKE_CASE 열거형 필드 |
| H-3 | **복합 필터 문법** | 3/6 | AIP-160 `filter` 표현식, AND/OR/NOT, 비교 연산자 |
| H-4 | **CORS 가이드** | 4/6 | 허용 오리진, preflight 캐시, 인증 헤더 노출 규칙 |
| H-5 | **TLS/HTTPS 명시** | 5/6 | HTTPS 필수 규칙 명시 |

### ✅ Medium (완료 — 업계 2~3곳 보유 또는 부분 구현 완성)

| # | 항목 | 보유 업체 수 | 구현 내용 |
|---|------|-------------|-----------|
| M-1 | **페이지 크기 기본값/최대값 명시** | 5/6 | 기본값 20, 최대값 100 |
| M-2 | **Caching 가이드 (Cache-Control)** | 3/6 | Cache-Control 지시어 + ETag/Last-Modified 가이드 |
| M-3 | **Partial Response 심화 (`fields=`)** | 4/6 | AIP-157, dot notation, id 항상 포함 |
| M-4 | **Expand/Embed 심화** | 3/6 | `?expand=`, 총 엔티티 상한, 깊이 제한, 순환 참조 방지 |
| M-5 | **재시도 가이드 (5xx 포함)** | 5/6 | 지수 백오프, 502/503/504 포함 |
| M-6 | **Webhooks / Event 알림** | 3/6 | 이벤트 페이로드 구조, 서명 검증, 재시도 정책 |
| M-7 | **전문 검색 (`q=`)** | 3/6 | 단순 키워드 검색 vs 필터링 구분 가이드 |
| M-8 | **HEAD/OPTIONS 메서드** | 3/6 | HEAD(메타만 반환), OPTIONS(CORS preflight) 명시 |

### ✅ Low (완료 — 업계 1~2곳 보유)

| # | 항목 | 보유 업체 수 | 구현 내용 |
|---|------|-------------|-----------|
| L-1 | **Health Check 엔드포인트** | 1/6 | `GET /health` → 200 `{"status":"ok"}` |

---

## 참고 문서

- Google AIP: https://google.aip.dev
- Microsoft REST API Guidelines: https://github.com/microsoft/api-guidelines
- Zalando RESTful API Guidelines: https://opensource.zalando.com/restful-api-guidelines
- Stripe API Reference: https://docs.stripe.com/api
- GitHub REST API: https://docs.github.com/en/rest
- JSON:API: https://jsonapi.org
