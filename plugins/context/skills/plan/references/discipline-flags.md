# Discipline Flags — 파싱 규칙 및 Opt-out Blockquote 주입

`context:plan` Step 0a 및 Step 4 opt-out 처리의 SOT.

---

## 플래그 파싱 (Step 0a)

ARGUMENTS에서 아래 패턴의 토큰을 추출하여 제거한다.

| 플래그 형식 | 변수 |
|------------|------|
| `--no-karpathy=<reason>` | `NO_KARPATHY=1`, `KARPATHY_REASON=<reason>` |
| `--no-tdd-tidy=<reason>` | `NO_TDD_TIDY=1`, `TDD_TIDY_REASON=<reason>` |

**reason 누락** (플래그만 존재, `=` 없거나 우측 공백):
- 대화 모드: AskUserQuestion으로 reason 수집 ("옵트아웃 사유를 입력해 주세요: `--no-{flag}` 를 사용하는 이유").
- 비대화 모드: 에러 메시지 출력 후 즉시 종료. (`--no-{flag}=<reason>` 형식으로 다시 호출하도록 안내)

플래그 토큰 제거 후 잔여 ARGUMENTS를 `RAW_IDEA`로 사용한다. **이후 모든 단계는 RAW_IDEA만 사용한다 (flag 누출 차단).**

---

## Opt-out Blockquote 주입 (Step 4 전 브랜치 공통)

옵트아웃 플래그가 설정된 경우, spec 내용 작성 시 **본문 첫 줄 위치**에 blockquote 라인을 삽입한다:

```markdown
> Discipline opt-out: --no-tdd-tidy (reason: <TDD_TIDY_REASON>)
> Discipline opt-out: --no-karpathy (reason: <KARPATHY_REASON>)
```

해당 플래그가 설정된 만큼만 (최대 2줄). 디폴트 케이스(옵트아웃 없음)는 변경 없음.
