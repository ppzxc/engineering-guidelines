# agy 스킬 — 운영 가이드라인

본 문서는 Antigravity CLI(`agy`) MCP Wrapper의 효율적인 운영 및 리소스 관리를 위한 지침을 담고 있습니다.

---

## 1. agy conversations 파일 누적 및 클린업 정책

Antigravity CLI는 비대화형 호출을 수행할 때마다 `~/.gemini/antigravity-cli/conversations/<uuid>.pb` 경로에 대화 상태 로그를 계속해서 누적 저장합니다.
Wrapper는 매번 새로운 stateless 분석 세션을 생성하므로(즉, `--continue`를 사용하지 않으므로), 이 로그들이 주기적으로 삭제되지 않으면 디스크 용량을 점차 낭비하게 됩니다.

### 🧹 디스크 관리 기준
* **권장 정리 주기**: 7일 경과 로그 삭제 또는 디스크 점유량 100MB 초과 시 정리.
* **현재 conversations 사용량 확인**:
  ```bash
  du -sh ~/.gemini/antigravity-cli/conversations/
  ```

### 🛠️ 수동 클린업 방법
다음 명령을 통해 오래된 세션 데이터들을 삭제할 수 있습니다.
```bash
# 7일 이상 된 .pb 파일 전체 삭제
find ~/.gemini/antigravity-cli/conversations -name '*.pb' -mtime +7 -delete

# conversations 내 파일 수가 너무 많은 경우 가장 오래된 파일 절반을 강제 삭제
ls -t ~/.gemini/antigravity-cli/conversations/*.pb | tail -n +$(( $(ls ~/.gemini/antigravity-cli/conversations/*.pb | wc -l) / 2 )) | xargs rm -f
```

### ⏰ 크론탭(crontab) 자동화 (권장)
매일 새벽 3시에 7일이 지난 데이터를 자동으로 삭제하도록 크론(cron)에 등록합니다. (`crontab -e` 명령으로 편집)
```cron
0 3 * * * find /root/.gemini/antigravity-cli/conversations -name '*.pb' -mtime +7 -delete
```

---

## 2. agy 인증 토큰 관리

`agy`는 구글 OAuth 토큰(`~/.gemini/antigravity-cli/antigravity-oauth-token`)을 통해 API 인증을 수행합니다. 토큰이 만료되면 MCP Wrapper 실행 도중 `AGY_ERROR`가 발생하며 호출이 차단될 수 있습니다.

### 🔐 토큰 만료 징후
* MCP 도구 호출 시 즉각 `AGY_ERROR(exit=...)` 또는 에러 메일/로그에 인증 에러가 포함되는 경우.

### 🔄 토큰 갱신 절차
1. 쉘 환경에서 `agy install` 또는 `agy update`를 실행하여 대화형 인증창을 띄웁니다.
2. 화면의 안내에 따라 로그인 인증 절차를 다시 완료하여 신규 OAuth 토큰을 발급받습니다.
