# Context — engineering-guidelines

Claude Code 마켓플레이스 플러그인 저장소. 소프트웨어 개발 엔지니어링 가이드라인 모음.

## Glossary

- **Plugin** — `plugins/<name>/`의 독립 배포 단위. `.claude-plugin/plugin.json` + `skills/` + (선택) `hooks/`로 구성.
- **Skill** — `plugins/<name>/skills/<skill>/SKILL.md` 또는 글로벌 `~/.claude/skills/<skill>/SKILL.md`. 사용자가 `/<skill>` 또는 `/<plugin>:<skill>`로 호출.
- **Marketplace** — `.claude-plugin/marketplace.json`에 등재된 플러그인 카탈로그. 버전 동기화는 `plugin.json`, `marketplace.json`, 루트 `README.md` 세 곳 동시 갱신.
- **ADR** — `docs/adr/`의 MADR 4.0 결정 기록. 번호는 immutable. 번복 시 supersede 패턴 사용.
- **Rule** — `.claude/rules/<topic>.md`의 원칙/제약 모음. 100줄 이하, `[ADR-NNNN]` 태그로 ADR과 연결.
- **Canonical Source** — 규칙 정본 소스: `AGENTS.md` / `.claude/rules/*` / `docs/adr/*` / `docs/agents/*` / `CONTEXT.md`.
- **Task Folder** — `docs/context/{TASK}/`의 4파일 (spec/plan/tasks/context.md). `context:plan` 스킬 산출물.
- **Cross-check** — peer LLM (agy/gemini/codex) 에게 리뷰 위임. self-host 호출 금지 (ADR-0022, ADR-0034).
- **Tracer Bullet** — 모든 통합 레이어를 가로지르는 vertical slice 단위 이슈. `to-issues` 스킬 기본 분해 단위.
- **Peer** — self-host가 아닌 외부 LLM (agy/gemini/codex). Cross-check 위임 대상.
- **Sentinel** — CLI 부재·타임아웃·오류 시 발생하는 신호 (NOT_FOUND/TIMEOUT/ERROR). 다음 peer로 폴백 트리거.
- **Severity-gated Merge** — critical/high = union, medium/low = intersection 방식의 리뷰 결과 병합 정책 (ADR-0033).

## Architecture decisions

`docs/adr/`의 ADR 인덱스(`docs/adr/README.md`) 참조.

최신 결정 (ADR-0037): matt pocock 스킬 컨벤션 채택 — ADR 경로 `docs/adr/` 이동, triage label 5종, `docs/agents/` 신규 정본 추가.
