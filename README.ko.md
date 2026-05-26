# engineering-guidelines

> [English](README.md)

소프트웨어 개발에 필요한 엔지니어링 가이드라인 모음 Claude Code 마켓플레이스입니다.

## 플러그인 목록

| 플러그인 | 버전 | 설명 |
|--------|------|------|
| [guideline](./plugins/guideline) | v0.1.2 | 소프트웨어 엔지니어링 가이드라인 및 코딩 원칙 — RESTful API 가이드라인 및 Andrej Karpathy의 11가지 코딩 행동 지침 포함 |
| [workflow](./plugins/workflow) | v0.1.1 | 오케스트레이션된 개발 프로세스 워크플로우 스킬 — 고강도 개발 기율 강제를 위한 init, idea, feature, develop, planning 스킬 포함 |
| [docs](./plugins/docs) | v0.0.7 | 문서 결정 기록 — ADR (Nygard 포맷) 및 MADR (MADR 4.0) 아키텍처 결정 기록 |
| [git](./plugins/git) | v0.0.16 | Git 워크플로우 스킬 — 안전한 커밋, 한글 PR 생성, 호스트 인지 peer 교차검증 PR 리뷰, squash merge, 이슈 생성, PR 전체 흐름, worktree 정리 |
| [llm](./plugins/llm) | v0.2.0 | LLM 위임 스킬 — agy (Antigravity CLI) 컨텍스트 맵 생성, claude 정밀 분석 및 auto 양방향 교차검증 |
| [dev](./plugins/dev) | v0.0.4 | 개발 방법론 스킬 — Tidy First, TDD, 언어 무관 개발 프랙티스 |

## 마켓플레이스 등록

```bash
claude plugin marketplace add https://github.com/ppzxc/engineering-guidelines.git
```

### Antigravity CLI (agy)에서 가져오기
Antigravity CLI 환경에서 본 스킬 플러그인을 정상적으로 설치하려면 [Antigravity CLI Import 가이드라인](docs/agy-import-guidelines.md)을 참조하세요.
