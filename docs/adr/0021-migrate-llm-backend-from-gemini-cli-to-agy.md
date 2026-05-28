# gemini-cli MCP 제거 및 agy(Antigravity CLI) 백엔드 교체

* Status: accepted
* Supersedes: ADR-0011
* Date: 2026-05-22
* Decision Makers: ppzxc

## Context and Problem Statement

gemini-cli MCP 서버가 user scope에서 제거됨에 따라 `mcp__gemini-cli__ask-gemini` 도구가 더 이상 사용 불가. feature-pipeline, gemini-crosscheck, git:review 스킬이 이 도구에 의존하고 있어 전면 마이그레이션이 필요하다. agy(Antigravity CLI)는 Python FastMCP wrapper(`~/agy-mcp/main.py`)를 통해 `mcp__agy__agy_context_map`과 `mcp__agy__agy_cross_check` 두 도구를 제공하는 대체 백엔드다.

## Decision Outcome

Chosen option: "agy FastMCP wrapper 채택 + llm 플러그인 신설 + feature-pipeline 제거", because gemini-cli 의존을 완전히 끊고 agy를 단일 LLM 위임 백엔드로 통일한다. model 선택 불필요(단일 모델), ping/probe 불필요, fallback 2단계(도구 호출 → sentinel → self-generate)로 단순화된다. 동시에 비활성 스킬(feature-pipeline)과 orphan 규칙 파일(workflow-rules.md)을 제거해 플러그인 구조를 단순화한다.
