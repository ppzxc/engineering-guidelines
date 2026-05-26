# engineering-guidelines

> [English](README.md)

소프트웨어 개발에 필요한 엔지니어링 가이드라인 모음 Claude Code 마켓플레이스입니다.

## 플러그인 목록

| 플러그인 | 버전 | 설명 |
|--------|------|------|
| [api](./plugins/api) | v0.2.4 | RESTful API 설계 가이드라인 — URL 구조, HTTP 메서드, 상태 코드, JSON 형식, 에러 응답, 버전 관리, 헤더, 비-CRUD action endpoint |
| [docs](./plugins/docs) | v0.0.7 | 문서 결정 기록 — ADR (Nygard 포맷) 및 MADR (MADR 4.0) 아키텍처 결정 기록 |
| [git](./plugins/git) | v0.0.16 | Git 워크플로우 스킬 — 안전한 커밋, 한글 PR 생성, 호스트 인지 peer 교차검증 PR 리뷰, squash merge, 이슈 생성, PR 전체 흐름, worktree 정리 |
| [llm](./plugins/llm) | v0.1.2 | LLM 위임 스킬 — agy(Antigravity CLI) 컨텍스트 맵 생성 및 실행 계획 교차검증 |
| [workflow](./plugins/workflow) | v0.2.3 | 워크플로우 스킬 — karpathy-guideline (Karpathy 11원칙 verbatim) |
| [dev](./plugins/dev) | v0.0.4 | 개발 방법론 스킬 — Tidy First, TDD, 언어 무관 개발 프랙티스 |

## 마켓플레이스 등록

```bash
claude plugin marketplace add https://github.com/ppzxc/engineering-guidelines.git
```

### Antigravity CLI (agy)에서 가져오기
Antigravity CLI 환경에서 본 스킬 플러그인을 정상적으로 설치하려면 [Antigravity CLI Import 가이드라인](docs/agy-import-guidelines.md)을 참조하세요.
