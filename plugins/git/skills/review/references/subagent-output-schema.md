# Subagent Output Schema

Self-Review SUBAGENT와 Peer-Review Coordinator SUBAGENT 모두 이 포맷으로 출력한다.
Main thread가 이 포맷을 파싱해 findings를 머지하므로 **정확히 준수**할 것.

## 출력 포맷

```
reviewer: <claude-opus|agy|gemini|codex|claude-self-generate>

| severity | file:line | category | issue |
| --- | --- | --- | --- |
| critical | src/Foo.java:42 | security | SQL injection via user input |
| high | main.go:87 | bug | nil pointer deref when result is empty |
| medium | handler.go:23 | style | exported type missing doc comment |
| low | utils.go:11 | naming | `tmp` should be more descriptive |
```

각 finding 직후 fix 블록:

````
```diff
- old code line
+ fixed code line
```
````

## Severity 분류 기준

| Severity | 정의 |
|----------|------|
| `critical` | 보안 취약점 / 데이터 손실 |
| `high` | 버그 / 런타임 에러 |
| `medium` | 오작동 가능성 / 로직 이슈 |
| `low` | 스타일 / 네이밍 |

## 규칙

- 테이블의 모든 finding에 fix 블록이 따라와야 한다 (순서 일치)
- fix 불가능한 finding(아키텍처 우려 등)은 fix 블록 대신 `<!-- no-fix: <reason> -->` 작성
- finding 없음: `reviewer: <name>\n\nNo issues found.` 출력
- reviewer 헤더 라인은 반드시 첫 줄에 단독으로 위치
