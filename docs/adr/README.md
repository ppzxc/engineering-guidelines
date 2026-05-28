# Architecture Decision Records

이 디렉토리는 프로젝트의 주요 결정(ADR)을 기록한다.
형식은 [MADR 4.0](https://adr.github.io/madr/)을 따른다.

## 인덱스

| ADR | 상태 | 주제 |
|-----|------|------|
| [ADR-0001](0001-docs-plugin-adr-madr-skills.md) | accepted | docs 플러그인 ADR/MADR 스킬 채택 |
| [ADR-0002](0002-plugin-skill-evaluation-system.md) | accepted | 플러그인별 독립 평가 시스템 채택 |
| [ADR-0003](0003-adopt-rfc-6648-for-custom-http-header-naming.md) | accepted | RFC 6648 커스텀 HTTP 헤더 네이밍 채택 |
| [ADR-0004](0004-adopt-non-crud-action-endpoint-pattern.md) | superseded by ADR-0005 | Non-CRUD Action Endpoint 패턴 |
| [ADR-0005](0005-adopt-aip-resource-oriented-design-and-colon-custom-methods.md) | accepted | AIP 리소스 중심 설계 및 콜론 커스텀 메서드 채택 |
| [ADR-0006](0006-git-plugin-rename-and-consolidation.md) | accepted | Git 플러그인 리네이밍 및 통합 |
| [ADR-0007](0007-adopt-aip-resource-lifecycle-patterns.md) | accepted | AIP 리소스 수명주기 패턴 2차 도입 |
| [ADR-0008](0008-adopt-aip-filter-fieldmask-partial-response.md) | accepted | AIP filter 표현식, updateMask 필수화, Partial Response 도입 |
| [ADR-0009](0009-adopt-strict-api-security-and-versioning-rules.md) | accepted | 엄격한 API 보안 및 버저닝 규칙 도입 (OWASP Top 10, 하위 호환성) |
| [ADR-0010](0010-adopt-tiered-api-profile-system.md) | accepted | API 플러그인 계층화 프로필 시스템 도입 (T1/T2/T3 점진적 채택) |
| [ADR-0011](0011-add-feature-pipeline-orchestrator.md) | superseded by ADR-0021 | feature-pipeline 오케스트레이터 스킬 추가 (아이디어→PR 단일 파이프라인) |
| [ADR-0013](0013-integrate-karpathy-guidelines-into-feature-pipeline.md) | superseded by ADR-0018 | feature-pipeline에 karpathy-guidelines 정신 통합 (S1.5 invoke + 단계별 가드레일) |
| [ADR-0014](0014-strengthen-feature-pipeline-evidence-based-gates.md) | accepted | feature-pipeline 오케스트레이션 강화: 외부 증거 기반 게이트 도입 (grep/pwd 검증, 8단계 재편) — cwd 검증 시점 변경은 [ADR-0019](0019-make-feature-pipeline-plan-mode-compatible.md) 참조 |
| [ADR-0015](0015-remove-writing-plans-from-feature-pipeline.md) | accepted | feature-pipeline S3에서 writing-plans 외부 스킬 호출 제거 (자체 작성으로 전환, 토큰 절약) |
| [ADR-0016](0016-avoid-plan-mode-in-feature-pipeline.md) | accepted | feature-pipeline에서 플랜 모드 회피 및 plan 파일 슬림화 (압축 폭주 차단) — 외부 plan mode 활성 시나리오는 [ADR-0019](0019-make-feature-pipeline-plan-mode-compatible.md) 참조, 사이즈 캡 변경은 [ADR-0020](0020-raise-feature-pipeline-plan-size-cap-to-16kb.md) 참조 |
| [ADR-0017](0017-concentrate-karpathy-guardrails-in-s6-subagent-prompt.md) | superseded by ADR-0018 | S6 subagent 프롬프트에 karpathy §2/§4 가드레일 집중 매핑 (paste-only 규약 정합) |
| [ADR-0018](0018-replace-external-karpathy-with-local-original-skill.md) | accepted | 외부 karpathy 의존 제거, 로컬 workflow:karpathy-original 신설 (원문 11원칙 verbatim) |
| [ADR-0019](0019-make-feature-pipeline-plan-mode-compatible.md) | accepted | feature-pipeline 단계 재구성 — S2를 S5 뒤로 이동, plan mode 외부 활성 통합 (supersedes ADR-0014 부분, ADR-0016 부분) |
| [ADR-0020](0020-raise-feature-pipeline-plan-size-cap-to-16kb.md) | accepted | feature-pipeline plan 파일 사이즈 캡 16KB 상향 + plan-skip HIGH 위험 차단 (supersedes ADR-0016 8KB 수치 부분) |
| [ADR-0021](0021-migrate-llm-backend-from-gemini-cli-to-agy.md) | accepted | gemini-cli MCP 제거 및 agy 백엔드 교체 (feature-pipeline 제거, llm 플러그인 신설) |
| [ADR-0022](0022-bidirectional-peer-cross-review.md) | accepted | `git:review` 양방향 peer cross-review (호스트별 라우팅, Claude↔agy↔Gemini) |
| [ADR-0023](0023-git-clean-bidirectional-peer-cross-check.md) | superseded by ADR-0035 | `git:clean` 양방향 peer cross-check 도입 (호스트별 라우팅, Claude↔agy↔Gemini) |
| [ADR-0027](0027-add-context-devdocs-plugin.md) | superseded by ADR-0030 (HARD-GATE 부분) | context Dev Docs 플러그인 추가 (4파일 자기완결 폴더, workflow와 공존) |
| [ADR-0028](0028-context-guard-opt-in-stop-hook.md) | superseded by ADR-0031 | context 플러그인 옵트인 Stop hook 도입 — context:guard 설치 스킬로 호스트 프로젝트에 staleness reminder 제공 |
| [ADR-0029](0029-context-plan-tiered-verification.md) | superseded by ADR-0030 | context:plan 계층형 자가검증·리뷰 게이트 도입 (Tier 1 self-review + Tier 2 비-Claude CLI cross-check) |
| [ADR-0030](0030-context-plan-pipeline-redesign.md) | accepted | context:plan 파이프라인 재설계 — grill 우선, spec 사람 리뷰 최우선(ExitPlanMode), GAN 단일 게이트 |
| [ADR-0031](0031-context-guard-auto-run-via-block.md) | accepted | context:guard Stop hook — decision:block 자동 실행, IDE 아티팩트 필터, 관련 context 매칭 (ADR-0028 supersede) |
| [ADR-0032](0032-context-plan-discipline-injection.md) | accepted | context:plan 디시플린 주입 — karpathy/tdd/tidy 원칙 디폴트 ON (설계 lens + [S]/[B] 검증 + GAN prompt 확장) |
| [ADR-0033](0033-git-review-parallel-subagent-cross-review.md) | accepted | `git:review` 병렬 SUBAGENT 크로스 리뷰 — Self/Peer SUBAGENT 병렬 dispatch, 호스트별 폴백 체인, severity-gated 머지 |
| [ADR-0034](0034-llm-plugin-4way-and-context-map-deprecation.md) | accepted | llm 플러그인 4-way 폴백 체인 확장 + context-map 전면 폐기 (ADR-0021/0022/0023 부분 supersede) |
| [ADR-0035](0035-deprecate-git-clean-peer-crosscheck.md) | accepted | `git:clean` entry peer crosscheck 폐지 — post-work pipeline 본질 재확인, ADR-0023 full supersede |
| [ADR-0036](0036-git-review-self-reviewer-migration.md) | accepted | `git:review` Self-Review agent를 pr-review-toolkit:code-reviewer로 교체 (언어별 스킬 제거, Step 4a 제거) |
| [ADR-0037](0037-adopt-matt-pocock-skill-conventions.md) | accepted | matt pocock 스킬 컨벤션 채택 — ADR 경로 `docs/adr/` 이동, CONTEXT.md, docs/agents/, triage labels 5종 |

## 새 ADR 추가

`.claude/rules/rules-maintenance.md`의 MADR 작성 형식을 따른다.
번호는 현재 최대값 + 1, 파일명은 `NNNN-<kebab-case-title>.md`.

- 옵션이 3개 이상이거나 트레이드오프가 중요한 결정: `0000-template.md` (full)
- 옵션이 2개 이하이고 트레이드오프가 경미한 결정: `0000-template-minimal.md` (minimal)
