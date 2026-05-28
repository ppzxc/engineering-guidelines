# Domain Docs

엔지니어링 스킬이 이 저장소의 도메인 문서를 소비하는 방법.

## 탐색 전 읽어야 할 파일

- **`CONTEXT.md`** (저장소 루트) — 도메인 용어집. 주요 개념(Plugin/Skill/ADR/Rule/Sentinel 등) 정의.
- **`docs/adr/`** — 작업 영역에 관련된 ADR을 읽는다. `docs/adr/README.md`에서 번호별 인덱스 확인.

파일이 없으면 조용히 진행한다 — 부재를 지적하거나 즉시 생성을 제안하지 않는다.

## 파일 구조

Single-context 저장소:

```
/
├── CONTEXT.md              ← 루트 도메인 용어집
├── docs/adr/               ← MADR 4.0 ADR (ADR-0037까지)
│   ├── README.md           ← 인덱스
│   ├── 0001-*.md
│   └── ...
├── docs/agents/            ← matt pocock 스킬 컨벤션 (이 파일 포함)
└── plugins/                ← 플러그인 코드
```

Task 별 컨텍스트는 `docs/context/{TASK}/context.md`에 추가 존재할 수 있다.

## 용어 사용 원칙

출력(이슈 제목, 리팩토링 제안, 테스트 이름)에서 도메인 개념을 언급할 때 `CONTEXT.md`의 용어를 그대로 사용한다. 동의어로 drift하지 않는다.

용어가 용어집에 없다면 두 가지 가능성 중 하나다: 프로젝트에 없는 언어를 만들고 있거나 (재고), 용어집에 빠진 실제 개념이거나 (`/grill-with-docs`로 추가).

## ADR 충돌 표시

출력이 기존 ADR과 모순될 경우 조용히 우선시하지 말고 명시적으로 표시:

> _ADR-0033과 모순 (severity-gated merge) — 그러나 다음 이유로 재검토 필요: …_
