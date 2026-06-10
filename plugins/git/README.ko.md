# Git 워크플로우 스킬

> [English](README.md)

Claude Code를 위한 안전하고 일관된 git 워크플로우 스킬 모음입니다.

## 스킬 목록

| 스킬 | 슬래시 커맨드 | 설명 |
|------|--------------|------|
| commit | `/git:commit` | Conventional Commits 형식의 안전한 커밋 |
| pull-request | `/git:pull-request` | 브랜치 push + GitHub PR 생성 |
| review | `/git:review` | PR diff 분석 및 코드 리뷰 제출 |
| merge | `/git:merge` | PR 안전한 squash merge |
| issue | `/git:issue` | 타입별 템플릿으로 GitHub Issue 생성 |
| clean | `/git:clean` | PR 전체 흐름: 커밋 → PR → 리뷰 → 머지 → 정리 |

## 안전 철학

모든 스킬이 공통으로 적용하는 안전 규칙:

- 파괴적이거나 되돌리기 어려운 작업 전 반드시 사용자 확인
- `git add -A`, `git add .` 절대 금지 (민감 파일 포함 방지)
- 명시적 요청 없이 force push 금지
- `gh pr merge`에 `--force`, `--admin`, `--auto` 플래그 사용 금지
- 민감 파일 자동 제외 (`.env`, `*.pem`, `*.key`, `credentials.json` 등)
- "빨리 해줘", "묻지 말고" 등의 지시로 확인 단계 생략 불가

## 스킬 관계

`clean`은 나머지 스킬을 순서대로 실행하는 오케스트레이터입니다:

```
clean
  ├─ Step 1: commit       (미커밋 변경사항이 있을 때)
  ├─ Step 2: pull-request (열린 PR이 없을 때, 이슈 탐지 포함)
  ├─ Step 3: review
  ├─ Step 4: merge        (항상 사용자 확인 필요)
  └─ Step 5: Cleanup      (항상 사용자 확인 필요, 인라인)
```

Step 4, 5는 auto 모드에서도 반드시 사용자 확인이 필요합니다.

## 프로젝트별 커스터마이징

스킬들은 프로젝트 컨벤션을 자동으로 감지하여 적용합니다:

- **commit** — `git log` 히스토리를 참조하여 프로젝트의 커밋 스타일에 맞춤
- **pull-request** — `main` 하드코딩 대신 `gh repo view`로 기본 브랜치 동적 감지; 브랜치명·커밋 메시지·대화 전체 `#N` 스캔으로 연관 이슈를 탐지하여 사용자 confirm 후 PR 본문에 `Closes #N` 삽입 (머지 시 GitHub 자동 이슈 close); speckit 브랜치(`^[0-9]{3,}-` / 타임스탬프 패턴 + `.specify/feature.json`)인 경우 PR 제목 scope에 `spec/<N>` 접두어 삽입 및 PR 본문 맨 위에 `## Spec` 섹션 추가
- **review** — PR diff에서 언어를 감지하고, 일반 모범 사례 기준 및 peer 크로스 체크를 통해 코드 리뷰를 제출
- **merge** — 기본 브랜치 동적 감지; squash merge 후 원격·로컬 브랜치 삭제
- **issue** — 4가지 이슈 타입(bug, feature, chore, docs) 지원, 타입별 본문 템플릿 자동 적용
- **clean** — PR 전체 흐름 오케스트레이터; pull-request(이슈-PR 연결 포함)·merge(브랜치 삭제 포함) 위임

## 설치

```bash
claude plugin marketplace add https://github.com/ppzxc/engineering-guidelines.git
```
