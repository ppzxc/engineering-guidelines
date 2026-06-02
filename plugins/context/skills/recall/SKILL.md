---
name: recall
description: Use after a session break to re-anchor on a task by reading its Dev Docs folder — /context:recall, "컨텍스트 재개", "어디까지 했지"
user-invocable: true
---

# Context Recall — 세션 재개

세션 단절 후 `docs/context/{TASK_NAME}/`의 4파일을 읽어 작업을 정확히 재개한다.

---

## 실행 순서

### 1. 대상 폴더 선택

선택적 ARGUMENTS = TASK_NAME.

TASK_NAME이 생략된 경우:
1. `docs/context/*/context.md`를 glob으로 수집한다.
2. 각 파일에서 `<!-- last_updated:` 라인을 grep으로 추출한다.
3. ISO-8601 문자열로 `sort -r` 정렬 → 가장 최신 폴더를 선택한다.
4. 동일 최신 타임스탬프가 복수이면 AskUserQuestion으로 선택한다.

### 2. 4파일 읽기 및 재앵커링

선택된 `docs/context/{TASK_NAME}/`의 4파일을 모두 읽는다:
- `spec.md` — 설계 목표와 배경
- `plan.md` — 아키텍처와 파일 구조
- `tasks.md` — 전체 체크리스트와 완료 현황
- `context.md` — 현재 상태, 결정 로그, 다음 할 일, 블로커

읽은 내용을 바탕으로 현재 상황을 요약한다:
- 어디까지 완료했는지 (tasks.md의 `[x]` 항목)
- 바로 다음 할 일 (context.md의 Next Steps)
- 블로커 또는 미해결 이슈 (context.md의 Blockers)

### 3. 작업 재개

context.md의 Next Steps와 Blockers를 기준으로 이어서 작업한다.
Blockers가 있으면 먼저 사용자에게 알리고 해결 방향을 협의한다.
