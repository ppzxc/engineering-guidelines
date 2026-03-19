# RESTful API Guidelines Skill 성능 평가 설계

**날짜:** 2026-03-19
**목적:** Claude Code skill(restful-api-guidelines.md)이 README 가이드라인을 얼마나 잘 커버하는지 평가하고, 개선 우선순위를 도출한다.

---

## 배경

`/home/ppzxc/projects/restful-api-guidelines/.claude/skills/restful-api-guidelines.md` 스킬은 Claude Code가 API 코드를 작성하거나 리뷰할 때 자동으로 활성화된다. 이 스킬이 `README.md`의 모든 규칙을 올바르게 반영하는지 체계적으로 평가한다.

---

## 목표

1. README ↔ 스킬 간 규칙 커버리지를 정량화한다.
2. 테스트 케이스(bad/good 코드 쌍)로 스킬의 탐지/생성 능력을 검증한다.
3. 문제를 Critical/Minor로 분류하고 개선 권고사항을 제시한다.

---

## 산출물

| 파일 | 설명 |
|------|------|
| `docs/evaluation/coverage-map.md` | README 규칙 ↔ 스킬 커버 여부 매핑 테이블 |
| `docs/evaluation/test-cases.md` | 섹션별 bad/good 코드 테스트 케이스 (~50개) |
| `docs/evaluation/report.md` | 커버리지 수치, Critical/Minor 문제 목록, 개선 권고사항 |

---

## 커버리지 매핑 방법론

### 규범 수준 분류

| 기호 | 수준 |
|------|------|
| ✅ 필수 | MUST / DO |
| ⚠️ 권장 | SHOULD / MAY |
| ❌ 금지 | MUST NOT / DO NOT |

### 스킬 커버 상태

| 상태 | 의미 |
|------|------|
| `COVERED` | 스킬에 명시적으로 언급됨 |
| `PARTIAL` | 일부만 반영됨 (예시 부족, 불완전한 설명) |
| `MISSING` | 스킬에 전혀 없음 |

### 심각도 분류 기준

| 심각도 | 조건 |
|--------|------|
| **Critical** | ✅필수 규칙이 `MISSING` 또는 `PARTIAL` |
| **Minor** | ⚠️권장/❌금지 규칙이 누락되거나, 스킬 코드 예시가 잘못된 경우 |

---

## 테스트 케이스 구조

```
### TC-{섹션번호}-{순번}: {규칙명}

- 규칙: README 원문 인용
- 규범 수준: ✅필수 / ⚠️권장 / ❌금지
- 스킬 커버: COVERED / PARTIAL / MISSING

❌ Bad:
[코드]

✅ Good:
[코드]

- 검증 포인트: 스킬의 어느 체크리스트 항목이 이를 탐지해야 하는가
```

### 테스트 케이스 범위

| 섹션 | 예상 케이스 수 |
|------|--------------|
| 2. HTTP 기본 규칙 (URL, 메서드, 상태코드, 헤더) | ~12개 |
| 3. REST 원칙 (스키마, 필드, 에러처리) | ~8개 |
| 4. JSON 규칙 (네이밍, 타입, 날짜, Enum) | ~10개 |
| 5. 공통 패턴 (액션, 페이지네이션, 필터, 버전, Rate Limit 등) | ~15개 |
| 6. 인증/보안 (Bearer, 401/403, Idempotency) | ~6개 |
| **합계** | **~50개** |

---

## 평가 보고서 구조

```
## 커버리지 요약
- 전체 규칙 수: N개
- COVERED: N개 (N%)
- PARTIAL: N개 (N%)
- MISSING: N개 (N%)

## Critical 문제
1. [규칙명] — 이유

## Minor 문제
1. [규칙명] — 이유

## 개선 권고사항
### 즉시 수정 (Critical)
### 다음 단계 (Minor)
```

---

## 평가 후 액션

- Critical 문제: 스킬에 즉시 반영
- Minor 문제: 우선순위 분류 후 단계적으로 반영
- 스킬 변경 후 동일한 테스트 케이스로 회귀 검증 가능
