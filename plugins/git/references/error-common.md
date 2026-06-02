# Git 공통 에러 처리

commit / merge / pull-request 스킬의 공통 에러 SOT.

---

## 공통 에러 카탈로그

| Situation | Action |
|-----------|--------|
| gh authentication error | `gh auth status` 실행 안내. 미인증 시 `gh auth login` 안내 후 중단. |
| Network / connectivity error | 네트워크 상태 확인 안내. `git remote -v` 로 remote URL 검증 후 재시도. |
| Hook failure (pre-push) | hook 에러 출력 표시. 원인 수정 후 재시도 안내. `--no-verify` 우회 절대 금지. |
