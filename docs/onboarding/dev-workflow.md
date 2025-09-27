
⸻

開發工作流程與 Makefile 使用指南

0) 目錄約定與腳本位置

app/               # 程式碼（FastAPI）
scripts/           # 自動化腳本（new_module.sh、new_spec.sh、release.sh、generate_openapi.py…）
docs/              # 文件（specs、api-reference、adr、runbooks、onboarding…）
Makefile           # 指令入口
specs-map.yaml     # app 版號 ↔ 各 SPEC 版號對應


⸻

1) Makefile 常用目標（指令入口）

查看所有可用指令：make help

指令	用途	範例
make init	一次性初始化（設定腳本 + 建 docs 基礎）	make init
make dev / make run	啟動開發伺服器（FastAPI）	make dev
make streamlit	啟動 Streamlit 前端 UI（預設指向本機 FastAPI）	make streamlit
make docs	產生/更新 docs/api-reference/openapi.json	make docs
make module name=<mod>	建模組骨架 + 掛路由	make module name=billing
`make spec title=”…” module= [bump=patch	minor	major]`
make release app_version=X.Y.Z	發版：更新 mapping、產出 OpenAPI、可串測試	make release app_version=1.4.0
make remove-module name=<mod>	撤回模組（若有 remove_module.sh）	make remove-module name=billing
make remove-spec id=SPEC-xxx	撤回規格（若有 remove_spec.sh）	make remove-spec id=SPEC-101
make test	執行測試	make test
make clean	清除暫存	make clean

Windows 沒有內建 make：建議用 WSL 或安裝 GNU Make。不想裝也可以用 bash scripts/... 直接叫腳本。

⸻

2) 日常開發流程（Feature-First）

A. 建立功能規格（SPEC）
	1.	決定模組與功能標題
	2.	產生規格檔（自動編號、spec_version: 1.0.0）

make spec title="Auth Signup" module=auth


	3.	在 docs/specs/ 編輯內容（需求、API、驗收），同步新增/調整測試檔。

B. 建立/擴充模組

make module name=auth      # 若模組未建立

	•	生成 app/modules/<mod>/ 分層骨架與 app/api/v1/<mod>.py
	•	自動掛到 app/api/v1/router.py（有錨點 # <<modules>>）

C. 撰寫程式與測試
	•	業務寫在 services.py，存取由 repositories.py 實作，API 層僅轉接 DTO。
	•	善用依賴注入（deps.py）讓測試可以注入 fake repo。
	•	跑測試：make test

D. 建立 / 更新 Streamlit UI
	1.	啟動前端：

make streamlit


	2.	預設入口為 `frontend/main.py`，可依需求拆分 `frontend/pages/`。
	3.	透過側邊欄或環境變數 `FASTAPI_BASE_URL` 指向後端（預設 http://127.0.0.1:8000）。
	4.	新增元件時建議將後端呼叫封裝成函式，方便重用與測試。

E. 生成 API 契約（必要時）
	•	若新增/變更 API：

make docs


	•	會更新 docs/api-reference/openapi.json，供前端/第三方參考。

⸻

3) 修 Bug、優化與重構（Fix / Perf / Refactor）

判斷是否需動 SPEC / OpenAPI
	•	不影響對外行為（只修內部、效能、重構）：
	•	更新 docs/CHANGELOG.md（Fixed / Performance / Refactor）
	•	可新增 docs/system-design/benchmarks/...（效能數據）
	•	影響對外行為 / API / 驗收條件：
	•	更新對應 SPEC（spec_version ↑），同步 specs-map.yaml
	•	重新 make docs 產生 OpenAPI
	•	重大重構決策寫 ADR

建議採 Conventional Commits：fix(auth): ...、perf(auth): ...、refactor(auth): ...

⸻

4) 發版流程（Release）

目標：將「程式版號」與「SPEC 版號集合」凍結對齊。
	1.	冷凍規格對應 + 產生 OpenAPI + 跑測試

make release app_version=1.4.0

	•	如 specs-map.yaml 沒該版本節點會自動建立骨架
	•	會執行 scripts/generate_openapi.py 產出快照

	2.	檢查與補全
	•	在 specs-map.yaml 的 app_versions["1.4.0"].specs 中，填入「本次採用的 SPEC → spec_version」
	•	變更有影響 API 的 SPEC：應已升版，OpenAPI 已重新產生
	•	測試綠燈（CI 也會驗證）
	3.	打標籤

git tag v1.4.0
git push --tags



建議：CI 驗證 PR 是否有符合規範（變更影響 SPEC 時，必須看到 SPEC + mapping + openapi 的 diff）。

⸻

5) 撤回（安全指引）

撤回模組
	•	有自動腳本：make remove-module name=<mod>
	•	無腳本：刪 app/modules/<mod>/、app/api/v1/<mod>.py，並移除 router.py 的 import/include；清理相關 SPEC 與 specs-map.yaml。

撤回 SPEC
	•	有腳本：make remove-spec id=SPEC-xxx
	•	無腳本：刪 docs/specs/SPEC-xxx-*.md、索引、mapping 對應。
	•	安全做法：先移至 docs/deprecated/，避免歷史斷點。

⸻

6) 文件維護要點
	•	規格（SPEC）：docs/specs/SPEC-xxx-*.md（跨模組工程規範類放 9xx 段，如 SPEC-900）
	•	索引：docs/specs/SPEC-000-index.md（自動腳本會嘗試追加）
	•	對應表：specs-map.yaml（app 版號 → 本次採用 SPEC 版號）
	•	API 契約：docs/api-reference/openapi.json（由 make docs 產生）
	•	CHANGELOG：docs/CHANGELOG.md（每次 fix/perf/refactor/feat 都要補）
	•	ADR：docs/adr/ADR-xxxx-*.md（重大決策）
	•	Benchmarks：docs/system-design/benchmarks/（效能紀錄）

⸻

7) 團隊規範（PR Checklist）
	•	Commit 風格符合 Conventional Commits（feat/fix/perf/refactor…）
	•	若變更 API / 驗收 → 已更新 SPEC（升 spec_version）、specs-map.yaml、openapi.json
	•	已更新 docs/CHANGELOG.md
	•	測試存在並通過
	•	重大重構有 ADR 或補充說明

⸻

8) 常見問題

Q：Windows 沒有 make 怎麼辦？
A：用 WSL 或安裝 GNU Make；或直接執行對應腳本：
bash scripts/new_module.sh <mod>、bash scripts/new_spec.sh "<title>" <module>、uv run python scripts/generate_openapi.py。

Q：SPEC 編號怎麼來？
A：new_spec.sh 會依「模組號段」自動分配（未定義模組落到 9xx）。也可用 id=SPEC-123 覆蓋。

Q：spec_version 何時要升？
A：只要影響外部行為（輸入/輸出/錯誤碼/流程/驗收），依 SemVer 升 patch/minor/major。不影響對外則不升。

⸻

一句話總結

平常用 make module、make spec 開工；變更 API 就 make docs；發版用 make release 凍結對應。
有 fix/perf/refactor 都記在 CHANGELOG；影響對外行為就同步動 SPEC + OpenAPI + mapping。
