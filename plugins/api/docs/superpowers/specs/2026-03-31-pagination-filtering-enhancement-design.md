# Pagination & Filtering Enhancement Design

**Date:** 2026-03-31
**Scope:** `plugins/api/README.md`, `plugins/api/skills/restful-guidelines/SKILL.md`, evaluation system

---

## Context

현재 api 플러그인의 REST 가이드라인(README.md)은 Cursor/Offset 페이지네이션과 기본 필터링 패턴을 다루고 있지만, 실무에서 자주 필요한 세부 규칙들이 누락되어 있다. SKILL.md에는 있지만 README에 없는 규칙(Min/Max 필터)도 발견되었고, 페이지네이션 관련 엣지 케이스(빈 컬렉션, pageSize 검증, Cursor 불투명성)와 대규모 데이터셋을 위한 Keyset Pagination 패턴이 필요하다.

**목표:** README 가이드라인을 심화하고, SKILL.md에 동기화하며, 평가 시스템도 함께 업데이트한다.

---

## Changes

### 1. README.md — 5.2 Collections and Pagination 섹션

#### 1-1. 빈 컬렉션 응답 규칙 (신규)

- ✅ **Required**: 컬렉션에 항목이 없을 때 `200 OK` + 빈 배열 `[]` 반환. `404 Not Found` 사용 금지.
- ⚠️ **Recommended**: 빈 컬렉션에도 `Total-Count: 0` 헤더 포함.
- RFC 9110 참조 노트 포함: 컬렉션 엔드포인트는 비어 있어도 리소스 자체는 존재.

Example:
```
HTTP/1.1 200 OK
Content-Type: application/json
Total-Count: 0

[]
```

#### 1-2. pageSize 범위 검증 (신규)

- ✅ **Required**: `pageSize < 1` → `400 Bad Request` 반환.
- ⚠️ **Recommended**: `pageSize > maxPageSize` → 에러 대신 최대값으로 커팅. 적용된 `pageSize`를 응답에 포함.

Example:
```
# Request: pageSize=500 (max is 100)
# Server applies pageSize=100

HTTP/1.1 200 OK
Link: <...?pageSize=100&pageToken=abc>; rel="next"

[ ... 100 items ... ]
```

#### 1-3. Cursor (pageToken) 불투명성 (신규)

- ✅ **Required**: `pageToken`은 불투명 값. 클라이언트는 파싱, 조합, 내부 형식에 대한 가정 금지.
- ✅ **Required**: 서버는 `pageToken` 인코딩을 사전 고지 없이 변경 가능.
- 리소스 식별자 불투명성 원칙과 동일 원리 참조 노트 포함.

#### 1-4. Keyset Pagination (신규 하위 섹션)

- ⚠️ **Recommended**: 대규모 데이터셋에서 일관된 성능이 중요한 경우 Keyset 페이지네이션 사용.
- 정렬 키 기반 커서로 O(1) 조회, 삽입 시 항목 누락/중복 없음.
- `after`/`before` 불투명 토큰 사용.
- ⚠️ **Recommended**: 복합 정렬 키는 불투명 커서에 인코딩.
- Trade-off 설명: 임의 페이지 점프 불가, 필요 시 offset 사용.

Example:
```
GET /articles?pageSize=20&orderBy=createdAt:desc&after=eyJjcmVhdGVkQXQiOi...

HTTP/1.1 200 OK
Link: <...?pageSize=20&orderBy=createdAt:desc&after=eyJjcm...>; rel="next"

[
  { "id": "455", "createdAt": "2024-01-20T09:55:00Z" },
  ...
]
```

### 2. README.md — 5.3 Filtering and Sorting 섹션

#### 2-1. Min/Max 숫자 범위 필터 (신규)

- ⚠️ **Recommended**: 숫자 범위 필터에 `Min`/`Max` 접미사 사용.

Example:
```
GET /products?priceMin=100&priceMax=500
GET /articles?viewCountMin=1000
```

### 3. README.md — 새 섹션 추가

#### 5.8 Partial Response
> 🚧 Coming soon

#### 5.9 Expand/Embed
> 🚧 Coming soon

#### 5.10 Bulk Operations
> 🚧 Coming soon

### 4. ToC 업데이트

5.8~5.10 항목을 Table of Contents에 추가.

### 5. SKILL.md 동기화

README에 추가된 규칙을 SKILL.md에 압축 반영:
- Filtering & Sorting 섹션: Min/Max 패턴은 이미 존재 (변경 불필요)
- 새 항목 추가:
  - 빈 컬렉션: `200 OK` + `[]`, 404 금지
  - pageSize: `< 1` → 400, `> max` → cap
  - Cursor: pageToken은 opaque, 파싱 금지
  - Keyset: after/before opaque token, O(1) 성능

### 6. 평가 시스템 업데이트

#### coverage-map.md
- 신규 규칙에 대한 매핑 행 추가 (5.2-7 ~ 5.2-10 등 번호 부여)
- Writing/Review 모드 모두 COVERED로 매핑

#### test-cases.md
- 신규 규칙별 bad/good 코드 쌍 테스트 케이스 추가 (약 5~8개)

#### report.md
- 규칙 총 수 업데이트 (71 → 76+)
- 커버리지 수치 재계산

---

## Files to Modify

| File | Action |
|------|--------|
| `plugins/api/README.md` | 5.2, 5.3 보강 + 5.8~5.10 placeholder + ToC |
| `plugins/api/README.ko.md` | README.md와 동일 변경 (한국어) |
| `plugins/api/skills/restful-guidelines/SKILL.md` | 신규 규칙 압축 반영 |
| `plugins/api/docs/evaluation/coverage-map.md` | 신규 규칙 매핑 행 추가 |
| `plugins/api/docs/evaluation/test-cases.md` | 신규 bad/good 테스트 케이스 추가 |
| `plugins/api/docs/evaluation/report.md` | 수치 업데이트 |

---

## Verification

1. README.md의 모든 신규 규칙이 Good/Bad 예시를 포함하는지 확인
2. SKILL.md가 README 신규 규칙을 빠짐없이 반영하는지 교차 확인
3. coverage-map.md에 신규 규칙이 모두 매핑되어 있는지 확인
4. test-cases.md에 신규 규칙 당 최소 1개 테스트 케이스 존재하는지 확인
5. README.md ToC 링크가 모두 정상 작동하는지 확인
6. README.ko.md가 README.md와 구조적으로 동일한지 확인
