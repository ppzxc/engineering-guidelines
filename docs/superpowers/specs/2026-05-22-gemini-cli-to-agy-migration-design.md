# Design: gemini-cli → agy MCP 마이그레이션

**Date:** 2026-05-22  
**Author:** ppzxc  
**Status:** Approved

---

## Goal

`mcp__gemini-cli__*` 의존을 완전히 제거하고, 로컬 Python FastMCP wrapper로 감싼 `agy(Antigravity CLI)`를 단일 LLM 위임 백엔드로 교체한다. 동시에 비활성 스킬(feature-pipeline)과 orphan 규칙 파일을 제거해 플러그인 구조를 단순화한다.

---

## 변경 범위 (단일 PR)

### 신규 생성

| 경로 | 설명 |
|------|------|
| `plugins/llm/.claude-plugin/plugin.json` | llm 플러그인 메타데이터 (v0.1.0) |
| `plugins/llm/skills/agy/SKILL.md` | agy 크로스체크 스킬 |

### 삭제

| 경로 | 이유 |
|------|------|
| `plugins/workflow/skills/gemini-crosscheck/` | llm:agy로 대체 |
| `plugins/workflow/skills/feature-pipeline/` | 비활성 스킬 제거 |
| `.claude/rules/workflow-rules.md` | feature-pipeline 삭제로 전체 orphan |

### 수정

| 경로 | 변경 내용 |
|------|-----------|
| `plugins/workflow/skills/karpathy-original/` → `karpathy-guideline/` | 디렉토리 rename, description 업데이트 |
| `plugins/git/skills/review/SKILL.md` | Step 5a: gemini-cli → agy |
| `CLAUDE.md` | workflow-rules.md 행 제거 |
| `.claude-plugin/marketplace.json` | llm 플러그인 추가, workflow 버전 bump |
| `plugins/workflow/.claude-plugin/plugin.json` | 버전 bump |
| `docs/decisions/README.md` | ADR-0021 행 추가 |

### 신규 ADR

- `docs/decisions/0021-migrate-llm-backend-from-gemini-cli-to-agy.md` — ADR-0011 supersede

---

## llm:agy 스킬 설계

### 위치
`plugins/llm/skills/agy/SKILL.md`

### 역할
분석 출력 전용. Context Map 생성 + 실행 계획 교차검증. **실행 로직 없음.**

### 플로우

```
Step 1. Context Map 생성
  bash로 PROJECT_DATA 수집 (tree, build config, git log 등)
  → mcp__agy__agy_context_map(project_data=PROJECT_DATA)
  → .context-map.md 저장 + .gitignore 추가
  sentinel 응답 시 → Conservative mode

Step 2. Cross-check
  mcp__agy__agy_cross_check(plan=<계획 전문>, context_map=<.context-map.md 또는 "">)
  sentinel 응답 시 → Claude self-generate (재호출 금지)
```

### 도구 시그니처

| 도구 | 인자 | 반환 |
|------|------|------|
| `mcp__agy__agy_context_map` | `project_data: str` | Context Map Markdown 또는 sentinel |
| `mcp__agy__agy_cross_check` | `plan: str`, `context_map?: str` | Issue table + scenarios + pre-mortem 또는 sentinel |

**금지:** `model`, `temperature`, `max_tokens` 등 schema에 없는 인자 추가 시 `InputValidationError`.

### Sentinel 처리

| Sentinel prefix | 의미 | 처리 |
|-----------------|------|------|
| `AGY_TIMEOUT:` | 300s 초과 | 즉시 Claude self-generate |
| `AGY_ERROR(exit=...)` | agy 비정상 종료 | 즉시 Claude self-generate |
| `AGY_NOT_FOUND:` | agy 바이너리 부재 | self-generate + 설치 안내 |

동일 인자 **재호출 금지**. fallback은 2단계(도구 호출 → sentinel → self-generate).

### Conservative Mode 출력 포맷

```markdown
## Cross-check (Claude self-generated)

| Tag | Item | Severity |
|-----|------|----------|
| ... | ...  | H/M/L    |

## Test Scenarios (Claude self-generated)
1. [정상 케이스] ...
2. [경계 케이스] ...
3. [실패 케이스] ...

## Pre-mortem (Claude self-generated)
1. [실패 이유 1] ...
2. [실패 이유 2] ...
3. [실패 이유 3] ...
```

### Context Map 스킵 조건
세 조건 모두 충족 시 Step 1 스킵:
1. `.context-map.md` 존재
2. 60분 이내 생성
3. `git:<HEAD hash>` 마커가 파일 내에 존재

---

## karpathy-guideline 스킬 변경

`karpathy-original` → `karpathy-guideline` 으로 rename.

- 디렉토리: `plugins/workflow/skills/karpathy-guideline/`
- description 필드: `feature-pipeline` 참조 제거, 독립 가이드라인으로 업데이트
- 내용(11 principles 본문): 변경 없음

---

## git:review 스킬 변경 (Step 5a)

**Before:**
```
mcp__gemini-cli__ask-gemini
- model: "gemini-3.1-pro-preview"
- fallback: model: "gemini-3-flash-preview"
```

**After:**
```
mcp__agy__agy_cross_check(plan=<PR diff 전문>, context_map=<.context-map.md 또는 "">)
sentinel 응답 시 → Claude-only review 진행
```

> **설계 노트:** `agy_cross_check` wrapper는 "senior architect cross-check" 템플릿을 부착한다. PR diff를 `plan` 인자로 전달하면 코드 리뷰보다 아키텍처 일관성·위험·누락 관점의 분석이 나온다. 기존 Gemini 코드 리뷰(버그·보안·스타일)와 관점이 다르지만, 독립적인 2차 분석이라는 본래 목적은 유지된다. Claude(Step 5)가 버그·보안을 담당하고 agy(Step 5a)가 아키텍처·위험을 담당하는 역할 분담으로 해석한다.

fallback chain: 3단계 Pro→Flash→Claude → 2단계 도구→sentinel→Claude.

---

## ADR-0021 핵심 결정

- **Supersedes:** ADR-0011 (feature-pipeline orchestrator)
- **결정:** gemini-cli MCP 제거, agy FastMCP wrapper 채택
- **이유:** gemini-cli가 user scope에서 제거됨; agy가 단일 LLM 백엔드로 통일됨
- **결과:** model 선택 불가(단일 모델), ping/probe 불필요, fallback 2단계로 단순화

---

## 버전 계획

| 플러그인 | 이전 | 이후 |
|----------|------|------|
| `llm` | 없음 | v0.1.0 (신규) |
| `workflow` | v0.1.4 | v0.2.0 (gemini-crosscheck 제거 + feature-pipeline 제거 + karpathy rename) |
| `git` | v0.0.10 | v0.0.11 (review Step 5a 업데이트) |

---

## 검증 체크리스트 (PR 머지 전)

- [ ] `grep -r "mcp__gemini-cli__"` → 0건
- [ ] `grep -r "model.*pro\|model.*flash"` (SKILL.md 내) → 0건
- [ ] ping/quota probe 단계 → 0건
- [ ] `llm:agy` SKILL.md 단어 수 < 500
- [ ] ADR-0021 frontmatter에 `supersedes: ADR-0011` 명시
- [ ] `docs/decisions/README.md` ADR-0021 행 추가 확인
- [ ] `CLAUDE.md` workflow-rules.md 행 제거 확인
- [ ] marketplace.json + plugin.json 버전 동기화 3곳 확인
