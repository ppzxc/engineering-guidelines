# Rules Maintenance

## ADR ↔ Rules 동기화 원칙

ADR(`docs/decisions/NNNN-*.md`)을 새로 작성할 때:
1. 결정에서 **제약 조건**을 추출하여 관련 `.claude/rules/` 파일에 추가
2. 규칙 항목에 `[ADR-NNNN]` 태그 달기
3. ADR에는 근거(why)를 유지, rules에는 제약(what)만 작성

ADR 없이 규칙을 추가할 때:
- 근거가 비자명하면 ADR 먼저 작성
- 명백한 컨벤션은 ADR 없이 rules에 직접 추가 가능

## Rules 작성 기준

rules 파일은 **스켈레톤 가드레일**이다. 구현자가 매번 직접 작성해야 할 내용을 대신 지시하지 않는다.

**허용** (원칙/제약):
- `~할 것`, `~금지`, `~사용 금지` 형식의 한 문장
- 플러그인 간 경계 규칙, 버전 관리 원칙, 문서 형식 원칙
- 형식: `<원칙 한 문장> [ADR-NNNN]`

**금지** (구현 디테일):
- SKILL.md 내 구현 코드 블록
- 특정 CLI 명령어 시퀀스
- 플러그인 내부 파일 경로 하드코딩
- JSON/YAML 설정 예시 블록
- 스킬 실행 순서 지정 (오케스트레이터 스킬 내부 사항)

예시:
```
✓ 커스텀 HTTP 헤더에서 X- 접두사를 사용하지 않을 것 [ADR-0003]
✗ Idempotency-Key 헤더를 모든 POST 요청에 추가하고 UUID v4 형식으로 생성할 것
```

## 규칙 파일 크기 관리

- 파일 하나당 **100줄 이하** 유지
- 100줄 초과 시 → 주제별로 파일 분리
- 예: `api.md`가 커지면 `api-url.md`, `api-headers.md`로 분리

## 규칙 정리 기준

| 상태 | 대응 |
|------|------|
| 같은 규칙이 두 파일에 중복 | 한 파일로 통합, 나머지에서 참조 |
| 6개월 이상 참조되지 않은 규칙 | 삭제 또는 `docs/decisions/`로 이동 |
| 규칙이 서로 모순 | ADR 작성 후 한쪽 삭제 |
| 규칙이 현재 코드와 불일치 | 코드 또는 규칙 중 하나를 맞춤 |

## MADR 작성 형식 [MADR 4.0]

`docs/decisions/NNNN-<kebab-case-title>.md` 형식으로 저장.
번호는 앞에 있는 최대 번호 + 1.

템플릿:
- full: `docs/decisions/0000-template.md` — 대부분의 결정에 사용
- minimal: `docs/decisions/0000-template-minimal.md` — 검토 옵션이 2개 이하이고 트레이드오프가 경미한 결정

frontmatter 필수 필드:
- `status`: accepted / deprecated / superseded by ADR-NNNN
- `date`: YYYY-MM-DD
- `decision-makers`: 결정 참여자

full 템플릿 필수 섹션:
- Context and Problem Statement
- Considered Options (최소 2개)
- Decision Outcome + Consequences

섹션명 규칙:
- ADR 섹션명은 반드시 영문 MADR 4.0 표준을 따를 것 (템플릿 파일 참조 필수)
- 프로젝트 고유 섹션은 `##` 레벨 한글 허용, 단 표준 섹션 순서 뒤에 배치

## CLAUDE.md 유지 원칙

- 항상 50줄 이하로 유지
- 세부 규칙은 CLAUDE.md에 쓰지 않고 `.claude/rules/`에 위임
- rules 파일이 추가되면 CLAUDE.md의 규칙 파일 목록 테이블 업데이트
- ADR 추가 시 `docs/decisions/README.md` 인덱스 테이블도 업데이트
