# ========= Project Makefile =========
# 使用方式： make <target> [name=xxx] [id=SPEC-xxx] [title="..."] [module=xxx] [version=X.Y.Z] [app_version=X.Y.Z]
# 例：
#   make init
#   make run
#   make module name=billing
#   make spec id=SPEC-101 title="Auth Signup" module=auth version=1.0.0
#   make release app_version=1.4.0
#   make remove-module name=billing
#   make remove-spec id=SPEC-101
#
# 依賴：
# - 已存在 scripts/new_module.sh、scripts/new_spec.sh、scripts/release.sh、scripts/generate_openapi.py
# - 建議安裝：uv、pytest（或依專案調整）

SHELL := /bin/bash

# ---- 可調整參數 ----
PY        := uv run python
UV        := uv run
APP_ENTRY := app/main.py
HOST      := 127.0.0.1
PORT      := 8000
FRONTEND_APP  := frontend/main.py
FRONTEND_HOST := 0.0.0.0
FRONTEND_PORT := 8501
FASTAPI_BASE_URL := http://$(HOST):$(PORT)
LABS_PORT := 8502

# ---- 便利函式 ----
define assert_nonempty
	@if [ -z "$($(1))" ]; then echo "❌ Missing variable: $(1). Usage: $(2)"; exit 1; fi
endef

# ---- 假目標宣告 ----
.PHONY: help init perms run dev serve streamlit labs-ui docs openapi test lint fmt module lab lab-spike spec release remove-module remove-spec clean

## help: 顯示所有可用指令
help:
	@echo ""
	@echo "可用指令："
	@grep -E '^[a-zA-Z0-9_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS=":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'
	@echo ""

## init: 一次性初始化（腳本授權、建立 docs 基礎結構）
init: perms
	@[ -d docs ] || mkdir -p docs
	@[ -d docs/api-reference ] || mkdir -p docs/api-reference
	@echo "✅ init done"

## perms: 設定 scripts/*.sh 可執行
perms:
	@chmod +x scripts/*.sh 2>/dev/null || true
	@echo "✅ scripts permission set"

## run: 啟動 FastAPI（uvicorn）
run:
	$(UV) uvicorn app.main:app --reload --host $(HOST) --port $(PORT)

## streamlit: 啟動 Streamlit 前端（預設連線到本機 FastAPI）
streamlit:
	FASTAPI_BASE_URL=$(FASTAPI_BASE_URL) $(UV) streamlit run $(FRONTEND_APP) --server.address $(FRONTEND_HOST) --server.port $(FRONTEND_PORT)

## labs-ui: 啟動 Labs Streamlit App（載入 ui/streamlit/pages/）
labs-ui:
	FASTAPI_BASE_URL=$(FASTAPI_BASE_URL) $(UV) streamlit run ui/streamlit/main.py --server.address $(FRONTEND_HOST) --server.port $(LABS_PORT)

## dev: 使用 fastapi CLI 啟動（若已安裝 fastapi[standard]）
dev: serve
serve:
	$(UV) fastapi dev $(APP_ENTRY) --host $(HOST) --port $(PORT)

## docs: 產生/更新 OpenAPI 快照到 docs/api-reference/openapi.json
docs: openapi
openapi:
	$(PY) scripts/generate_openapi.py

## test: 執行測試（可依專案調整）
test:
	$(UV) pytest -q

## lint: 進行 Lint（可依專案調整 flake8/ruff/mypy）
lint:
	@echo "ℹ️ 你可以在此接上 ruff/flake8/mypy，例如：uv run ruff check ."
	@echo "（預設無動作）"

## fmt: 程式碼格式化（可依專案調整 black/ruff）
fmt:
	@echo "ℹ️ 你可以在此接上 black/ruff fmt，例如：uv run ruff format ."
	@echo "（預設無動作）"

## module: 新增模組骨架（name=<module>）
module:
	$(call assert_nonempty,name,"make module name=<module>")
	bash scripts/new_module.sh $(name)

## lab: 建立新的 Lab 實驗空間（name=<lab> [title="..."]）
lab:
	$(call assert_nonempty,name,"make lab name=<lab> [title=\"...\"]")
	bash scripts/new_lab.sh $(name) $(if $(title),"$(title)",)

## lab-spike: 在指定 Lab 建立 spike 腳本（name=<lab> title="..."）
lab-spike:
	$(call assert_nonempty,name,"make lab-spike name=<lab> title=\"...\"")
	$(call assert_nonempty,title,"make lab-spike name=<lab> title=\"...\"")
	LAB_DIR=$$(echo $(name) | tr '[:upper:]' '[:lower:]' | tr '_' '-') && \
	bash scripts/new_spike.sh labs/$$LAB_DIR/spikes "$(title)"

## spec: 新增規格檔（title="..." module=<mod> [bump=patch|minor|major]）
spec:
	@if [ -z "$(title)" ] || [ -z "$(module)" ]; then \
	  echo "Usage: make spec title='Title' module=<mod> [bump=patch|minor|major]"; exit 1; fi
	bash scripts/new_spec.sh "$(title)" "$(module)" $(if $(bump),bump=$(bump),)

## release: 發版流程（app_version=X.Y.Z：更新 specs-map.yaml 節點、產生 OpenAPI、可掛測試）
release:
	$(call assert_nonempty,app_version,"make release app_version=X.Y.Z")
	bash scripts/release.sh "$(app_version)"

## fix: 建立修復 PR 模板（附 checklist）
fix:
	@echo "開 PR 時請使用標題：fix(<module>): <what>"
	@echo "記得在 PR 勾選：更新 CHANGELOG；若 spec 受影響要同步更新"

## perf: 建立效能報告模板
perf:
	@bash scripts/new_benchmark.sh "$(title)" "$(module)"

## remove-module: 撤回/移除模組（name=<module>）— 需自備 scripts/remove_module.sh
remove-module:
	$(call assert_nonempty,name,"make remove-module name=<module>")
	@if [ -f scripts/remove_module.sh ]; then \
		bash scripts/remove_module.sh $(name); \
	else \
		echo "⚠️ 未找到 scripts/remove_module.sh，請手動移除："; \
		echo "   - app/modules/$(name)/"; \
		echo "   - app/api/v1/$(name).py"; \
		echo "   - app/api/v1/router.py 內的 import/include"; \
	fi

## remove-spec: 撤回/移除規格（id=SPEC-xxx）— 需自備 scripts/remove_spec.sh
remove-spec:
	$(call assert_nonempty,id,"make remove-spec id=SPEC-xxx")
	@if [ -f scripts/remove_spec.sh ]; then \
		bash scripts/remove_spec.sh $(id); \
	else \
		echo "⚠️ 未找到 scripts/remove_spec.sh，請手動移除："; \
		echo "   - docs/specs/$(id)-*.md"; \
		echo "   - docs/specs/SPEC-000-index.md 中對應行"; \
		echo "   - specs-map.yaml 中對應 $(id)"; \
	fi

## clean: 清理暫存檔案
clean:
	@find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
	@find . -name "*.pyc" -delete 2>/dev/null || true
	@echo "🧹 cleaned"
