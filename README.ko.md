# engineering-guidelines

> [English](README.md)

소프트웨어 개발에 필요한 엔지니어링 가이드라인 모음 Claude Code 마켓플레이스입니다.

## 플러그인 목록

| 플러그인 | 버전 | 설명 |
|--------|------|------|
| [guideline](./plugins/guideline) | v0.3.0 | 소프트웨어 엔지니어링 가이드라인 및 코딩 원칙 — RESTful API 가이드라인, Andrej Karpathy의 11가지 코딩 행동 지침, Honest Judgment 안티-sycophancy 리뷰 규칙 포함 |
| [workflow](./plugins/workflow) | v0.2.0 | 오케스트레이션된 개발 프로세스 워크플로우 스킬 — 고강도 개발 기율 강제를 위한 init, idea, feature, develop, planning 스킬 포함 |
| [docs](./plugins/docs) | v0.0.8 | 문서 결정 기록 — ADR (Nygard 포맷) 및 MADR (MADR 4.0) 아키텍처 결정 기록 |
| [git](./plugins/git) | v0.7.3 | Git 워크플로우 스킬 — 안전한 커밋, 한글 PR 생성, 호스트 인지 peer 교차검증 PR 리뷰(fast/balanced/deep tier 선택), union 머지+agreement 태그 자동수정, squash merge, 이슈 생성, Closes #N 이슈 연결, PR 전체 흐름, worktree 정리 |
| [llm](./plugins/llm) | v0.5.2 | LLM 위임 스킬 — 4-way peer 교차검증 (agy, claude, gemini, codex), 호스트 인지 폴백 체인 |
| [dev](./plugins/dev) | v0.1.0 | 개발 방법론 스킬 — Tidy First, TDD, 언어 무관 개발 프랙티스 |
| [context](./plugins/context) | v0.10.1 | Dev Docs 시스템 스킬 — 세션 단절에도 재개 가능한 4파일 자기완결 작업 폴더 |

## 마켓플레이스 등록

```bash
claude plugin marketplace add https://github.com/ppzxc/engineering-guidelines.git
```

### Antigravity CLI (agy)에서 가져오기
Antigravity CLI 환경에서 본 스킬 플러그인을 정상적으로 설치하려면 [Antigravity CLI Import 가이드라인](docs/agy-import-guidelines.md)을 참조하세요.
