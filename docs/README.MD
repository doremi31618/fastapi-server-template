文件空間維護使用手冊（Docs Maintenance Guide）

這份手冊說明如何維護專案的文件空間，包含目錄結構、命名規則、規格（SPEC）編號與版號、與程式版號的對應、常見作業流程、指令、CI 檢查。

⸻

1) 文件目錄結構

docs/
├─ specs/                        # 規格文件（SPEC-xxx）
│  └─ SPEC-000-index.md         # 規格總索引（清單與狀態）
├─ api-reference/               # API 契約與補充
│  ├─ openapi.json              # 由程式產出的 OpenAPI 快照
│  └─ README.md
├─ system-design/               # 系統/架構/序列圖
│  └─ diagrams/
├─ adr/                         # Architecture Decision Records
├─ rfc/                         # 重大變更提案（草案）
├─ runbooks/                    # 操作手冊 & 故障排除
├─ onboarding/                  # 新人指南
├─ test-plans/                  # 測試/驗收計畫
├─ threat-model/                # 安全威脅建模
└─ CHANGELOG.md                 # 文件變更記錄

專案根目錄還有：

specs-map.yaml                  # 「程式版號 ↔ 規格版號」對應表
scripts/generate_openapi.py     # 產生 OpenAPI 快照
scripts/init_docs.sh            # 初始化文件目錄（一次性）
scripts/verify_spec_map.py      # （可選）CI 檢查腳本


⸻

2) 規格（SPEC）命名與編號

命名
	•	檔名：SPEC-<編號>-<slug>.md（例：SPEC-101-auth-signup.md）
	•	內文第一個區塊需包含 Frontmatter（見下一節）。

編號規則（建議）
	•	採「模組號段」分配：
	•	SPEC-1xx：auth 模組（例：註冊、登入）
	•	SPEC-2xx：其他模組（之後擴充）
	•	以後新增模組就新增號段；避免衝突與混用。

⸻

3) 規格 Frontmatter（強制）

每份 SPEC 檔頭必須有以下欄位（YAML 或簡單 Key/Value 皆可）：

---
spec_id: SPEC-101                  # 規格編號（與檔名一致）
spec_version: 1.0.0                # 規格版號（SemVer）
status: Draft | Accepted | Deprecated
module: auth
introduced_in_app: 1.2.0           # 程式從此版開始支援
last_compatible_app: 2.0.0         # （可選）到此版仍相容
endpoints:
  - POST /v1/auth/signup
tests:
  - tests/api/test_auth_api.py
  - tests/unit/test_auth_services.py
---

用途：
	•	自文件查程式：看 introduced_in_app / last_compatible_app 知道支援範圍。
	•	CI 校驗：比對 specs-map.yaml 與實際檔頭是否一致。

⸻

4) 程式版號 ↔ 規格版號對應（specs-map.yaml）

集中管理每次 release 的採用規格版號，並作為 CI 檢查依據：

app_versions:
  "1.4.0":
    release_date: 2025-09-27
    specs:
      SPEC-101: "1.1.0"     # Auth Signup
      SPEC-102: "1.0.0"     # Auth Login
    openapi: docs/api-reference/openapi.json

  "1.3.0":
    release_date: 2025-08-10
    specs:
      SPEC-101: "1.0.0"

modules:
  auth: [SPEC-101, SPEC-102]

關鍵：
	•	新發版要新增一段 app_versions["X.Y.Z"]，並列出此版採用的 spec_id → spec_version。
	•	CI 會檢查：specs-map.yaml 的 spec_version 是否與各 SPEC 檔頭一致；對應的測試檔是否存在與通過。

⸻

5) 常見作業流程

A. 初始化文件空間（第一次）

bash scripts/init_docs.sh

	•	會建立 docs/ 目錄與幾個基本檔；之後可按需修改。

B. 新增一份規格（SPEC）
	1.	指派編號（依號段），新增檔案：docs/specs/SPEC-101-auth-signup.md
	2.	填寫 Frontmatter（spec_version 從 1.0.0 起）
	3.	撰寫內容（需求、流程、驗收條件）
	4.	在 docs/specs/SPEC-000-index.md 增列
	5.	新增/更新對應測試（frontmatter 的 tests: 欄位要對得上）

C. 規格升版
	•	規格有非向下相容變更 → 升 spec_version 主版/次版（依 SemVer）
	•	規格僅補充敘述 → 可升 patch
	•	同步更新 docs/specs/SPEC-000-index.md 與 PR 說明

D. 產生 API 契約（OpenAPI 快照）

uv run python scripts/generate_openapi.py
# 會更新 docs/api-reference/openapi.json

E. 新的程式發版（例：v1.4.0）
	1.	冷凍採用規格：編輯 specs-map.yaml → 新增 app_versions["1.4.0"]
	2.	產出 openapi.json（上一節指令）
	3.	執行測試（含 SPEC 對應的 tests）
	4.	CI 檢查（下一節）通過
	5.	打 Git tag：git tag v1.4.0 && git push --tags

⸻

6) CI 檢查（建議規則）

在 .github/workflows/ 加入工作流程（概念）：
	•	Frontmatter 檢查：每份 docs/specs/SPEC-*.md 必須含 spec_id/spec_version/module/introduced_in_app。
	•	雙向一致：
	•	specs-map.yaml 中列出的 SPEC-xxx: "a.b.c"，需與該 SPEC 檔頭 spec_version 一致。
	•	introduced_in_app ≤ 本次發版 app_version。
	•	OpenAPI 冪等：用 scripts/generate_openapi.py 產出後，與 specs-map.yaml 指定的 openapi 檔做 diff。
	•	測試存在與通過：SPEC 檔頭 tests: 列出的路徑存在且測試通過。
	•	索引有效性：docs/specs/SPEC-000-index.md 內的清單與實際文件集合一致。

這些檢查可以由你自訂的 scripts/verify_spec_map.py 完成（parse frontmatter + YAML 比對），不需要很複雜，能擋住多數人為疏漏。

⸻

7) 寫作與命名規範
	•	規格檔名：SPEC-<編號>-<短描述>.md（英文小寫加連字號，避免空白）
	•	章節建議：背景/目標 → 非功能性需求 → 流程/序列圖 → API 契約 → 資料模型 → 驗收條件（測試連結） → 安全考量
	•	以 單一事實來源 為目標：API 契約以 openapi.json 為準；規格需引用到對應 Endpoint 與測試。
	•	變更紀錄：重大變更在 SPEC 內文註明（或在 docs/CHANGELOG.md 關聯）。

⸻

8) 常用指令速查

# 一次性建立文件骨架
bash scripts/init_docs.sh

# 產生 OpenAPI 快照（更新 docs/api-reference/openapi.json）
uv run python scripts/generate_openapi.py

# 檢查 specs-map 與 frontmatter（若你實作了 verify 腳本）
uv run python scripts/verify_spec_map.py

# 查看目前規格清單
ls docs/specs/SPEC-*.md | sort


⸻

9) PR 檢查清單（範本）
	•	有新增/修改 SPEC？→ 已更新 spec_version 與 frontmatter
	•	有影響 API？→ 已重產 docs/api-reference/openapi.json
	•	specs-map.yaml 是否需要更新（新發版或規格採用變更）？
	•	對應測試是否存在並通過？（frontmatter/tests 連結正確）
	•	docs/specs/SPEC-000-index.md 是否同步更新清單和狀態？

⸻

10) FAQ

Q：SPEC 要不要跟程式版號一致？
A：不用。SPEC 有自己的 spec_version（描述規格演進），在發版點，用 specs-map.yaml 鎖定「程式版號 → 採用哪個 spec 版號集合」。

Q：不同程式版可能採用同一份 SPEC 嗎？
A：可以。只要功能未變更，就沿用同一 spec_version，在 app_versions[...] 中重複引用即可。

Q：文件要不要做版本快照？
A：建議以程式發版為錨點：可在文件站用 vX.Y.Z 文件版本，或保留主線再透過 specs-map.yaml 查詢對應。openapi.json 每次釋出都應是快照。

⸻

如果你想，我可以再提供一個 scripts/new_spec.sh 的模板產生器（自動建立 SPEC-xxx-*.md 並帶入 Frontmatter），讓新增規格更順手。