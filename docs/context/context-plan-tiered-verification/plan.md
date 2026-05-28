# context:plan 계층형 자가검증 게이트 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `context:plan` 스킬의 각 산출 스텝(4/6/7)에 tier 1 self-review gate + tier 2 GAN cross-check를 추가해 검증 공백을 제거한다.

**Architecture:** `references/verification.md`(신규)에 게이트 정의·체크리스트·CLI 호출 패턴·GAN 프롬프트를 집중하고, `SKILL.md`는 각 스텝 말미에 산문 지시 1줄만 추가한다. 멀티 LLM(AGY→Gemini→Codex→Claude self-generate)은 CLI 직접 호출로 구현하며 ADR-0029로 결정 근거를 기록한다.

**Tech Stack:** Markdown 스킬 파일, Bash(agy/gemini/codex CLI), MADR 4.0 ADR

---

## File Structure

| 경로 | 역할 | 동작 |
|------|------|------|
| `plugins/context/skills/plan/references/verification.md` | 게이트 정의 허브 | **신규** |
| `plugins/context/skills/plan/SKILL.md` | context:plan 오케스트레이터 | **수정** |
| `docs/adr/0029-context-plan-tiered-verification.md` | ADR | **신규** |
| `docs/adr/README.md` | ADR 인덱스 | **수정** |
| `.claude/rules/context-rules.md` | 가드레일 | **수정** |
| `plugins/context/.claude-plugin/plugin.json` | 버전 | **수정** |
| `plugins/context/plugin.json` | 버전 | **수정** |
| `README.md` | 버전 표 | **수정** |
| `README.ko.md` | 버전 표 | **수정** |
