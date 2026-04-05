# AGENTS.md

Claude Code, Cursor, GitHub Copilot 등 모든 AI 도구에 공통으로 적용되는 프로젝트 규칙이다.

설계, 아키텍처, 프로젝트 컨벤션에 대한 새로운 결정이 발생하면, 반드시 `docs/decisions/0000-template.md` (또는 minimal)를 참고하여 ADR 문서를 작성하고, 강제할 규칙은 `.claude/rules/`의 관련 파일에 `[ADR-NNNN]` 태그와 함께 추가하여 동기화할 것.

## 프로젝트 정체성

Claude Code 마켓플레이스 플러그인 저장소. 소프트웨어 개발 엔지니어링 가이드라인 모음.

플러그인 목록 및 버전: 루트 [README.md](README.md) 참조.

## 프로젝트 구조

```
plugins/api/        # RESTful API 설계 가이드라인
plugins/docs/       # 문서 결정 기록 스킬
plugins/git/        # Git 워크플로우 스킬
docs/decisions/     # ADR (MADR 4.0)
.claude/rules/      # 프로젝트 규칙
```

## 컨벤션

- **문서 언어**: 한국어
- **ADR 형식**: MADR 4.0 (`docs/decisions/0000-template.md` 참조)
- **버전 동기화**: 플러그인 버전 변경 시 세 곳을 동시에 업데이트한다
  - `.claude-plugin/marketplace.json`
  - `plugins/<name>/.claude-plugin/plugin.json`
  - 루트 `README.md` / `README.ko.md`
- **규칙 파일**: 100줄 이하, 원칙/제약만 기술 (구현 디테일 금지)

## 정본 규칙 소스

규칙의 정본은 아래 세 경로뿐이다. 이 외의 위치에 규칙을 작성하지 않는다.

1. `AGENTS.md` — 공통 프로젝트 규칙
2. `.claude/rules/*` — 작업별 세부 규칙
3. `docs/decisions/*` — 결정의 근거 (ADR)
