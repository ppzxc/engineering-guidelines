# engineering-guidelines

> [English](README.md)

소프트웨어 개발에 필요한 엔지니어링 가이드라인 모음 Claude Code 마켓플레이스입니다.

## 플러그인 목록

| 플러그인 | 버전 | 설명 |
|--------|------|------|
| [api](./plugins/api) | v0.0.10 | RESTful API 설계 가이드라인 — URL 구조, HTTP 메서드, 상태 코드, JSON 형식, 에러 응답, 버전 관리, 헤더, 비-CRUD action endpoint |
| [docs](./plugins/docs) | v0.0.3 | 문서 결정 기록 — ADR (Nygard 포맷) 및 MADR (MADR 4.0) 아키텍처 결정 기록 |
| [git](./plugins/git) | v0.0.4 | Git 워크플로우 스킬 — 안전한 커밋, PR 생성, PR 리뷰, squash merge, 이슈 생성, PR 전체 흐름, worktree 정리 |

## 마켓플레이스 등록

```bash
claude plugin marketplace add https://github.com/ppzxc/engineering-guidelines.git
```
