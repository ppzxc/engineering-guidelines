# Severity Taxonomy — 공유 어휘 SOT

`git:review`와 `llm:auto` 공통 severity 어휘 단일 SOT. [ADR-0047](../../../docs/adr/0047-severity-taxonomy.md)

---

## 4-Level 표준

| Severity | 정의 |
|----------|------|
| `critical` | 보안 취약점 / 데이터 손실 |
| `high` | 버그 / 런타임 에러 |
| `medium` | 오작동 가능성 / 로직 이슈 |
| `low` | 스타일 / 네이밍 |

프롬프트 인라인 표기:
```
severity: critical=security/data-loss, high=bug/runtime-error, medium=logic-issue, low=style/naming
```

---

## H/M/L Alias 매핑

`llm:auto` cross-check에서 사용하는 약식 표기:

| Alias | 4-Level | 의미 |
|-------|---------|------|
| `H` | `high` | blocking — 반드시 수정 |
| `M` | `medium` | should-fix |
| `L` | `low` | note |

`critical`은 alias 없음. cross-check 맥락에서는 `H`가 최고 severity.

---

## 머지 공식 범위 제한

severity taxonomy는 **어휘 SOT**만 제공. 아래 공식은 각 플러그인이 독립 유지:

- `llm:auto`: Union/Intersection 집계 공식 (SKILL.md 유지)
- `git:review`: severity×agreement fix-gate (SKILL.md 유지)

게이팅 축이 달라 통합 불가 — ADR-0047 참조.
