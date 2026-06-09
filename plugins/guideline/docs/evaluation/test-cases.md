# Test Cases — guideline Plugin Skills Evaluation

**작성일:** 2026-06-09
**대상 스킬:** guideline:restful-api (PATCH updateMask)
**참조:** `coverage-map.md`

---

## guideline:restful-api

### TC-patch-clear-implicit: 생략 시 묵시적 데이터 초기화 (AIP-134)
- 대상 스킬: guideline:restful-api
- 평가 축: Workflow
- 규범 수준: ✅필수

**입력 상황:**
`updateMask`에 `bio` 필드가 포함되어 있으나, Request Body payload에 `bio` 필드가 아예 누락(생략)된 상태로 PATCH 요청을 보냄.

**기대 동작:**
서버는 해당 필드를 묵시적으로 삭제(clear/null 또는 기본값으로 설정)하도록 명확하게 규정함.

**금지 동작:**
Body에 필드가 생략되었다는 이유로 해당 필드 수정을 무시하거나 기존 값을 유지하도록 가이드하는 것.

**검증 포인트:**
- `SKILL.md` 내에 "updateMask에 명시되어 있으나 바디에 누락된 필드는 초기화(clear/null)한다"는 명세가 포함되었는지 확인.

---

### TC-patch-clear-nested: 점 표기법(dot notation) 중첩 필드 제어
- 대상 스킬: guideline:restful-api
- 평가 축: Workflow
- 규범 수준: ✅필수

**입력 상황:**
중첩된 객체의 세부 필드(예: `profile.bio`)만 선택적으로 업데이트하거나 null 초기화하고자 함.

**기대 동작:**
`updateMask=profile.bio`와 같이 점(.) 표기법을 사용하여 중첩 객체의 세부 필드만 타겟해 초기화할 수 있음을 규정함.

**금지 동작:**
1단계 최상위 필드(`profile`)만 전체 제어하여 하위 필드를 통째로 덮어쓰도록 강제하는 것.

**검증 포인트:**
- `SKILL.md` 내에 "점(.) 표기법(dot notation)을 통한 중첩 필드 개별 제어/초기화 지원" 내용이 명시되었는지 확인.

---

### TC-patch-clear-invalid: 유효하지 않은 마스크 경로 지정 시 에러 반환
- 대상 스킬: guideline:restful-api
- 평가 축: Safety
- 규범 수준: ✅필수

**입력 상황:**
존재하지 않거나 스키마에 정의되지 않은 잘못된 필드명이 `updateMask`에 전달됨.

**기대 동작:**
서버는 즉시 요청 처리를 중단하고 `400 Bad Request` 에러를 반환해야 함을 규정함 (Fail-Fast).

**금지 동작:**
잘못된 필드 경로를 무음 무시(Ignore)하고 나머지 정상 필드만 임의로 처리하게 놔두는 것.

**검증 포인트:**
- `SKILL.md` 내에 "유효하지 않은 updateMask 경로는 400 Bad Request 에러로 처리한다"는 명세가 포함되었는지 확인.
