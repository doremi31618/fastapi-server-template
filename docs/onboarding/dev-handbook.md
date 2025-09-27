# 開發手冊 (Developer Handbook)

本手冊說明如何在專案中使用並維護文件目錄，確保程式碼與文件保持一致。

---

## 1. 文件目錄概觀

```text
docs/
├─ specs/                        # 規格文件 (SPEC-xxx)
│  └─ SPEC-000-index.md          # 規格總索引
├─ api-reference/                # API 契約與補充
│  └─ openapi.json
├─ system-design/                # 架構設計與圖表
│  └─ diagrams/
├─ adr/                          # Architecture Decision Records
├─ rfc/                          # 重大變更草案
├─ runbooks/                     # 操作手冊與排錯
├─ onboarding/                   # 新人上線指南
├─ test-plans/                   # 測試與驗收計畫
├─ threat-model/                 # 安全威脅建模
└─ CHANGELOG.md                  # 文件變更紀錄
```

專案根目錄中與文件相關的重點檔案：

- `specs-map.yaml`：程式版號 ↔ 規格版號對應表。
- `scripts/`：文件與自動化相關工具腳本。

---

## 2. 規格 (SPEC) 管理

### 命名規則

- 檔名：`SPEC-<編號>-<slug>.md`。
- 編號分段建議：
  - `SPEC-1xx` → auth 模組。
  - `SPEC-2xx` → 其他模組。
- `slug` 使用英文小寫加連字號，避免空白。

### Frontmatter 範例

每份 SPEC 檔頭需包含以下欄位：

```yaml
---
spec_id: SPEC-101
spec_version: 1.1.0
status: Accepted
module: auth
introduced_in_app: 1.2.0
last_compatible_app: 2.0.0
endpoints:
  - POST /v1/auth/signup
tests:
  - tests/api/test_auth_api.py
---
```

---

## 3. 文件與程式對應

### `specs-map.yaml`

集中管理程式版號與規格版號對應：

```yaml
app_versions:
  "1.4.0":
    specs:
      SPEC-101: "1.1.0"
      SPEC-102: "1.0.0"
    openapi: docs/api-reference/openapi.json
```

每次發版務必更新此檔，確保採用的規格版本清楚可查。

---

## 4. 常見流程

### A. 初始化文件空間

```bash
bash scripts/init_docs.sh
```

### B. 新增規格 (SPEC)

1. 指派編號 (依模組號段)。
2. 建立檔案 `docs/specs/SPEC-xxx-*.md`。
3. 填寫 frontmatter 與內容。
4. 更新 `docs/specs/SPEC-000-index.md`。
5. 新增或更新對應測試 (frontmatter 的 `tests` 欄位需對應真實測試檔)。

### C. 升級規格版號

- 功能變更 → 升主版或次版 (`major`/`minor`)。
- 敘述補充 → 升修訂版 (`patch`)。
- 記得同步更新 `specs-map.yaml` 與索引。

### D. 產生 API 契約

```bash
uv run python scripts/generate_openapi.py
```

### E. 發版流程

1. 更新 `specs-map.yaml`，新增 `app_version` 區塊。
2. 產生最新 `openapi.json`。
3. 執行測試。
4. CI 全數通過後打 Git tag：`git tag vX.Y.Z`。

---

## 5. CI 檢查規則

- 規格檔必須具備完整 frontmatter。
- `specs-map.yaml` 與規格檔的 `spec_version` 一致。
- API 契約 (`openapi.json`) 與程式碼一致。
- frontmatter 所列測試存在且通過。
- 規格索引 (`SPEC-000-index.md`) 與實際檔案對應。

---

## 6. 寫作規範

- 使用英文 slug 與模組號段，維持一致性。
- 建議章節：背景與目標 → 非功能性需求 → 流程 / 圖表 → API 契約 → 資料模型 → 驗收條件 → 安全考量。
- 重大決策建立 ADR，重大變更提出 RFC。

---

## 7. 常用指令

```bash
# 產生文件骨架
bash scripts/init_docs.sh

# 產生 OpenAPI 快照
uv run python scripts/generate_openapi.py

# 查看規格清單
ls docs/specs/SPEC-*.md | sort
```

---

## 8. PR Checklist

- 新增或修改的 SPEC 已更新 `spec_version`。
- `openapi.json` 已重新產生 (若有影響 API)。
- `specs-map.yaml` 已更新。
- 對應測試存在並通過。
- 規格索引 (`SPEC-000-index.md`) 已更新。
