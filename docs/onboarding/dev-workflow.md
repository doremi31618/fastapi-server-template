# 開發工作流程與 Makefile 使用指南

本指南整理專案目錄約定、Makefile 常用指令，以及日常開發、發版與文件維護流程。

---

## 0. 目錄約定與腳本位置

```text
app/               # FastAPI 程式碼
scripts/           # 自動化腳本 (new_module.sh、new_spec.sh、release.sh、generate_openapi.py…)
docs/              # 文件 (specs、api-reference、adr、runbooks、onboarding…)
Makefile           # 指令入口
specs-map.yaml     # app 版號 ↔ 各 SPEC 版號對應
```

---

## 1. Makefile 常用目標

使用 `make help` 可查看所有可用指令。下表整理常用目標：

| 指令 | 用途 | 範例 |
| --- | --- | --- |
| `make init` | 一次性初始化 (設定腳本並建立 docs 基礎) | `make init` |
| `make dev` / `make run` | 啟動 FastAPI 開發伺服器 | `make dev` |
| `make streamlit` | 啟動 Streamlit 前端 UI (預設指向本機 FastAPI) | `make streamlit` |
| `make labs-ui` | 啟動 Labs Streamlit 入口 (載入 `ui/streamlit/pages/`) | `make labs-ui` |
| `make lab name=<lab>` | 建立 Labs 實驗骨架 | `make lab name=ocr title="OCR Pipeline"` |
| `make lab-spike name=<lab> title="..."` | 在指定 Lab 新增 spike 腳本 | `make lab-spike name=ocr title="Test pytesseract"` |
| `make docs` | 產生或更新 `docs/api-reference/openapi.json` | `make docs` |
| ``make module name=<mod>`` | 建立模組骨架並掛上路由 | ``make module name=billing`` |
| ``make spec title="…" module=<mod> [bump=patch|minor|major]`` | 建立規格檔 (可指定版號升級) | ``make spec title="Auth Signup" module=auth`` |
| `make release app_version=X.Y.Z` | 發版：更新 mapping、產出 OpenAPI，可串測試 | `make release app_version=1.4.0` |
| `make remove-module name=<mod>` | 撤回模組 (若提供 `remove_module.sh`) | `make remove-module name=billing` |
| `make remove-spec id=SPEC-xxx` | 撤回規格 (若提供 `remove_spec.sh`) | `make remove-spec id=SPEC-101` |
| `make test` | 執行測試 | `make test` |
| `make clean` | 清除暫存 | `make clean` |

> **Windows 提示**：系統未預載 GNU Make，建議透過 WSL 或自行安裝；也可直接執行 `scripts/` 底下的 Bash 腳本。

---

## 2. 日常開發流程 (Feature First)

### A. 建立功能規格 (SPEC)

1. 決定模組與功能標題。
2. 產生規格檔 (自動編號，預設 `spec_version: 1.0.0`)：

   ```bash
   make spec title="Auth Signup" module=auth
   ```

3. 於 `docs/specs/` 編輯需求、API、驗收，並同步新增或調整測試檔。

### B. 建立或擴充模組

```bash
make module name=auth  # 若模組尚未建立
```

- 生成 `app/modules/<mod>/` 分層骨架與 `app/api/v1/<mod>.py`。
- 自動掛載至 `app/api/v1/router.py` (透過錨點 `# <<modules>>`)。

### C. 撰寫程式與測試

- 業務邏輯放在 `services.py`，資料存取由 `repositories.py` 實作，API 層僅處理 DTO。
- 善用依賴注入 (`deps.py`) 讓測試可注入 fake repository。
- 執行測試：

  ```bash
  make test
  ```

### D. 建立 / 更新 Streamlit UI

1. 啟動前端：

   ```bash
   make streamlit
   ```

2. 預設入口為 `frontend/main.py`，可視需求拆分 `frontend/pages/`。
3. 透過側邊欄或環境變數 `FASTAPI_BASE_URL` 指向後端 (預設 `http://127.0.0.1:8000`)。
4. 新增元件時，建議將後端呼叫封裝成函式以利重用與測試。

### E. 生成 API 契約

- 若新增或變更 API，需重新產生 OpenAPI：

  ```bash
  make docs
  ```

- 指令會更新 `docs/api-reference/openapi.json`，供前端或第三方使用。

### F. Labs 研究流程 (尚未產品化的實驗)

1. 建立 Lab 骨架：

   ```bash
   make lab name=ocr title="OCR Pipeline"
   ```

2. 安裝必要依賴 (依 Lab 選擇 optional group)：

   ```bash
   uv sync -E labs-ocr
   ```

3. 在 `labs/<lab>/spikes/` 內新增驗證腳本：

   ```bash
   make lab-spike name=ocr title="Test pytesseract"
   ```

4. 將可重用的邏輯整理到 `labs/<lab>/prototype/`，並透過 `make labs-ui` 的 Streamlit 頁面呈現。
5. 實驗數據與觀察記錄於 `docs/system-design/benchmarks/` 與 `docs/rfc/`，作為產品化評估依據。
6. 通過審查後，回到 SPEC 與 `app/modules/` 進行正式實作。

---

## 3. 修 Bug、優化與重構 (Fix / Perf / Refactor)

### 判斷是否需更新 SPEC / OpenAPI

- **不影響對外行為** (僅內部修正、效能、重構)：
  - 更新 `docs/CHANGELOG.md` (Fixed / Performance / Refactor)。
  - 可新增 `docs/system-design/benchmarks/...` (效能數據)。
- **影響對外行為 / API / 驗收條件**：
  - 更新對應 SPEC (`spec_version` 升級) 並同步 `specs-map.yaml`。
  - 重新 `make docs` 產生 OpenAPI。
  - 重大重構決策請撰寫 ADR。

> 建議採用 Conventional Commits：`fix(auth): ...`、`perf(auth): ...`、`refactor(auth): ...`。

---

## 4. 發版流程 (Release)

目標：將「程式版號」與「SPEC 版號集合」凍結對齊。

1. 冷凍規格對應、產生 OpenAPI、執行測試：

   ```bash
   make release app_version=1.4.0
   ```

   - 若 `specs-map.yaml` 尚無該版本節點會自動建立骨架。
   - 指令會執行 `scripts/generate_openapi.py` 產出快照。

2. 檢查與補全：
   - 在 `specs-map.yaml` 的 `app_versions["1.4.0"].specs` 中填入「本次採用的 SPEC → spec_version」。
   - 變更影響 API 的 SPEC 已升版，`openapi.json` 已重新產生。
   - 測試全數綠燈 (CI 亦會驗證)。

3. 打標籤：

   ```bash
   git tag v1.4.0
   git push --tags
   ```

> 建議在 CI 中驗證 PR 是否包含必要的文件更新 (SPEC、mapping、OpenAPI diff)。

---

## 5. 撤回 (安全指引)

### 撤回模組

- 有自動腳本：`make remove-module name=<mod>`。
- 無腳本：刪除 `app/modules/<mod>/`、`app/api/v1/<mod>.py`，移除 `router.py` 的 import / include，並清理相關 SPEC 與 `specs-map.yaml`。

### 撤回 SPEC

- 有腳本：`make remove-spec id=SPEC-xxx`。
- 無腳本：刪除 `docs/specs/SPEC-xxx-*.md`、索引與 mapping 對應。
- 安全作法：先移至 `docs/deprecated/`，避免歷史斷點。

---

## 6. 文件維護要點

- 規格：`docs/specs/SPEC-xxx-*.md` (跨模組工程規範可使用 `SPEC-9xx`)。
- 索引：`docs/specs/SPEC-000-index.md` (自動腳本會嘗試追加)。
- 對應表：`specs-map.yaml` (app 版號 → 採用 SPEC 版號)。
- API 契約：`docs/api-reference/openapi.json` (由 `make docs` 產生)。
- 變更紀錄：`docs/CHANGELOG.md` (feat/fix/perf/refactor 都需更新)。
- 決策紀錄：`docs/adr/ADR-xxxx-*.md` (重大決策)。
- 效能紀錄：`docs/system-design/benchmarks/`。

---

## 7. 團隊規範 (PR Checklist)

- Commit 風格符合 Conventional Commits (`feat` / `fix` / `perf` / `refactor` …)。
- 若變更 API 或驗收條件：已更新 SPEC (升 `spec_version`)、`specs-map.yaml` 與 `openapi.json`。
- 已更新 `docs/CHANGELOG.md`。
- 測試存在並通過。
- 重大重構具備 ADR 或補充說明。

---

## 8. 常見問題 (FAQ)

**Q：Windows 沒有 make 怎麼辦？**  
A：使用 WSL 或安裝 GNU Make；或直接執行對應腳本，例如：

```bash
bash scripts/new_module.sh <module>
bash scripts/new_spec.sh "<title>" <module>
uv run python scripts/generate_openapi.py
```

**Q：SPEC 編號如何產生？**  
A：`new_spec.sh` 會依「模組號段」自動分配 (未定義模組則落到 `9xx`)；也可使用 `id=SPEC-123` 覆蓋。

**Q：`spec_version` 何時要升級？**  
A：只要影響外部行為 (輸入 / 輸出 / 錯誤碼 / 流程 / 驗收) 即依 SemVer 升 `patch` / `minor` / `major`；不影響對外則可維持原版號。

---

## 9. 一句話總結

日常使用 `make module`、`make spec` 開工；變更 API 就 `make docs`；發版用 `make release` 凍結對應。凡是 `fix` / `perf` / `refactor` 記得補 `CHANGELOG`；影響對外行為時，同步更新 SPEC、OpenAPI 與 mapping。
