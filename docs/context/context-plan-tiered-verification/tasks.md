# Tasks — context:plan 계층형 자가검증 게이트

## Task 1: references/verification.md 신규 작성

- [ ] **Step 1: `references/` 디렉토리 존재 여부 확인**
- [ ] **Step 2: `verification.md` 작성** (plan.md Task 1 Step 2 전체 내용)
- [ ] **Step 3: 파일 존재 확인** — `test -f plugins/context/skills/plan/references/verification.md && echo "OK"`
- [ ] **Step 4: 커밋** — `git commit -m "feat(context): verification gate 정의 파일 추가"`

## Task 2: SKILL.md 수정

- [ ] **Step 1: SKILL.md 읽기** — `cat -n plugins/context/skills/plan/SKILL.md`
- [ ] **Step 2: Step 4 말미 게이트 참조 추가** — 체크포인트 문단 뒤에 Step-4 Gate 지시 삽입
- [ ] **Step 3: Step 6 말미 게이트 참조 추가** — `재확인 후 Step 7로 진행` 뒤에 Step-6 Gate 지시 삽입
- [ ] **Step 4: Step 7 ORIG_COUNT 픽스 + Step-7 Gate 참조** — tasks.md 추출 문단 교체
- [ ] **Step 5: Decision Log 템플릿 provenance 주석 추가** — `## Decision Log` 주석 교체
- [ ] **Step 6: Step 8 핸드오프 GAN review 라인 추가** — `context.md — 동적 재개 앵커` 뒤에 삽입
- [ ] **Step 7: 수정 결과 확인** — `grep -n "Step-4 Gate\|Step-6 Gate\|Step-7 Gate\|ORIG_COUNT\|provenance\|GAN review" SKILL.md`
- [ ] **Step 8: 커밋** — `git commit -m "feat(context): SKILL.md 검증 게이트 + ORIG_COUNT 픽스 + provenance"`

## Task 3: ADR-0029 작성

- [ ] **Step 1: ADR 파일 작성** — `docs/adr/0029-context-plan-tiered-verification.md` (plan.md Task 3 Step 1 전체 내용)
- [ ] **Step 2: 파일 존재 확인** — `test -f docs/adr/0029-context-plan-tiered-verification.md && echo "OK"`
- [ ] **Step 3: 커밋** — `git commit -m "docs(adr): ADR-0029 context:plan 계층형 자가검증 게이트 도입"`

## Task 4: ADR README 갱신 + context-rules.md 가드레일

- [ ] **Step 1: ADR README에 ADR-0029 행 추가** — ADR-0028 줄 뒤에 삽입
- [ ] **Step 2: context-rules.md 가드레일 4줄 추가** — 파일 말미에 append
- [ ] **Step 3: 100줄 제한 확인** — `wc -l .claude/rules/context-rules.md`
- [ ] **Step 4: 변경 내용 확인** — `grep "ADR-0029" docs/adr/README.md .claude/rules/context-rules.md`
- [ ] **Step 5: 커밋** — `git commit -m "docs: ADR-0029 인덱스 갱신 + context-rules.md 가드레일 추가"`

## Task 5: 버전 동기화 0.2.0 → 0.3.0

- [ ] **Step 1: 네 파일 버전 문자열 일괄 확인** — `grep -n '"version"\|v0\.2\.0' plugins/context/.claude-plugin/plugin.json plugins/context/plugin.json README.md README.ko.md`
- [ ] **Step 2: plugin.json 두 파일 버전 교체** — `"version": "0.2.0"` → `"0.3.0"`
- [ ] **Step 3: README.md 버전 교체** — context 행 `v0.2.0` → `v0.3.0`
- [ ] **Step 4: README.ko.md 버전 교체** — context 행 `v0.2.0` → `v0.3.0`
- [ ] **Step 5: 동기화 확인** — 네 파일 모두 `0.3.0` 표기 확인
- [ ] **Step 6: 커밋** — `git commit -m "chore(context): 버전 bump 0.2.0 → 0.3.0"`
