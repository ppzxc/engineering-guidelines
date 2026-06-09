# guideline Plugin Skills 성능 평가 보고서

**평가 날짜:** 2026-06-09
**평가 대상:** guideline:restful-api (PATCH updateMask)
**테스트 케이스:** `test-cases.md` (총 3개)

---

## 커버리지 요약

| 스킬 | Safety COVERED | Safety 합계 | Workflow COVERED | Workflow 합계 | 전체 커버율 |
|------|---------------|------------|-----------------|--------------|------------|
| guideline:restful-api | 1 | 1 | 2 | 2 | 100.0% |
| **합계** | **1** | **1** | **2** | **2** | **100.0%** |

> 커버율 = (COVERED + PARTIAL×0.5) / 합계 × 100
> 평가 실행 후 각 셀을 채울 것

---

## 평가 실행 방법

각 테스트케이스를 Claude Code 세션에서 **입력 상황**에 따라 스킬을 호출하고,
**검증 포인트**를 기준으로 COVERED / PARTIAL / MISSING을 판정한다.

| 판정 | 기준 |
|------|------|
| COVERED | 검증 포인트 100% 충족 |
| PARTIAL | 검증 포인트 일부만 충족 |
| MISSING | 검증 포인트 미충족 또는 동작 없음 |
