@AGENTS.md

## 스킬 라우팅

사용자가 `/context:plan`을 입력하면 다른 행동 이전에 `Skill` 도구로 `context:plan`을 호출할 것.

## Claude Code 전용

설계, 아키텍처, 프로젝트 컨벤션에 대한 새로운 결정이 발생하면, 반드시 `docs/adr/0000-template.md` (또는 minimal)를 참고하여 ADR 문서를 작성하고, 강제할 규칙은 `.claude/rules/`의 관련 파일에 `[ADR-NNNN]` 태그와 함께 추가하여 동기화할 것.

### 규칙 파일

작업 전 관련 규칙 파일을 읽는다.

| 작업 | 파일 |
|------|------|
| ADR 작성 / 규칙 수정 | `.claude/rules/rules-maintenance.md` |
| git 스킬 사용 / 수정 | `.claude/rules/git-rules.md` |
| context 스킬 사용 / 수정 | `.claude/rules/context-rules.md` |
| llm 스킬 사용 / 수정 | `.claude/rules/llm-rules.md` |

### 참조

- `@docs/adr/README.md` — ADR 인덱스

결정의 근거는 [`docs/adr/README.md`](docs/adr/README.md) 참조.
규칙 파일의 `[ADR-NNNN]` 태그가 해당 ADR을 가리킨다.
