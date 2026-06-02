---
name: update
description: Use right before context compaction to persist task state into the Dev Docs folder — /context:update, "컨텍스트 업데이트", "상태 저장", "진행상황 기록"
user-invocable: true
---

# Context Update — 작업 상태 영속화

현재 세션의 진행 상태를 `docs/context/{TASK_NAME}/`에 저장한다.
컨텍스트 압축(compaction) 직전에 사용한다.

---

## 실행 순서

### 1. 대상 폴더 선택

선택적 ARGUMENTS = TASK_NAME.

TASK_NAME이 생략된 경우:
1. `docs/context/*/context.md`를 glob으로 수집한다.
2. 각 파일에서 `<!-- last_updated:` 라인을 grep으로 추출한다.
3. ISO-8601 문자열로 `sort -r` 정렬 → 가장 최신 폴더를 선택한다.
4. 동일 최신 타임스탬프가 복수이면 AskUserQuestion으로 선택한다.
5. **유추 결과 확인 게이트 (interactive 전용)**: AskUserQuestion으로 선택된 폴더와 `last_updated` 타임스탬프를 제시하며 "최신 task `{TASK_NAME}` (마지막 업데이트: {last_updated}) 상태를 저장할까요?" 확인. 사용자가 거부하면 목록을 보여주고 재선택. non-interactive 세션은 이 게이트를 건너뛰고 선택된 폴더로 진행한다.

### 2. 파일 갱신 규칙

**tasks.md**:
- 완료된 항목: `- [ ]` → `- [x]`로 변경
- 신규 task가 있으면 적절한 위치에 추가

**context.md**:
- `Current Status`: 지금 전체 진행 상황 1줄로 갱신
- `Decision Log`: 이번 세션에서 내린 결정 추가
- `Next Steps`: 다음에 할 작업으로 갱신
- `Blockers / Known Issues`: 막힌 것·미해결 갱신
- `Last Updated`: 오늘 날짜로 갱신
- `<!-- last_updated: ... -->`: ISO-8601 UTC 타임스탬프로 갱신

**plan.md**:
- 스코프 변경이 필요한 경우, 수정 전 **반드시 AskUserQuestion으로 사용자 확인**을 받는다.
- 확인 없이 plan.md를 수정하지 않는다.

### 3. 완료 보고

갱신된 파일 목록과 변경 요약을 출력한다.
