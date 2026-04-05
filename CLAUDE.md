@AGENTS.md

## Claude Code 전용

설계, 아키텍처, 프로젝트 컨벤션에 대한 새로운 결정이 발생하면, 반드시 `docs/decisions/0000-template.md` (또는 minimal)를 참고하여 ADR 문서를 작성하고, 강제할 규칙은 `.claude/rules/`의 관련 파일에 `[ADR-NNNN]` 태그와 함께 추가하여 동기화할 것.

### 규칙 파일

작업 전 관련 규칙 파일을 읽는다.

| 작업 | 파일 |
|------|------|
| ADR 작성 / 규칙 수정 | `.claude/rules/rules-maintenance.md` |

### 참조

- `@docs/decisions/README.md` — ADR 인덱스

결정의 근거는 [`docs/decisions/README.md`](docs/decisions/README.md) 참조.
규칙 파일의 `[ADR-NNNN]` 태그가 해당 ADR을 가리킨다.
