#!/usr/bin/env bash
# Bootstrap a new labs workspace with documentation, prototype, and Streamlit page.
# Usage: bash scripts/new_lab.sh <lab-name> ["Title"]
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <lab-name> [\"Title\"]" >&2
  exit 1
fi

RAW_NAME="$1"
RAW_TITLE="${2:-}"

if [[ ! "$RAW_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
  echo "❌ lab-name must be alphanumeric with optional hyphen/underscore." >&2
  exit 1
fi

SLUG=$(echo "$RAW_NAME" | tr '[:upper:]' '[:lower:]' | tr '_' '-')

if [[ -z "$RAW_TITLE" ]]; then
  RAW_TITLE="$(echo "$SLUG" | tr '-' ' ' )"
fi

TITLE=$(echo "$RAW_TITLE" | awk '{for(i=1;i<=NF;i++){sub(".",toupper(substr($i,1,1))substr($i,2),$i)}; print}')

LAB_DIR="labs/${SLUG}"
PAGES_DIR="ui/streamlit/pages"
STREAMLIT_SUFFIX=$(echo "$TITLE" | tr '[:lower:]' '[:upper:]' | sed -E 's/[^A-Z0-9]+/_/g;s/^_+//;s/_+$//')
[[ -z "$STREAMLIT_SUFFIX" ]] && STREAMLIT_SUFFIX="LAB"
STREAMLIT_PAGE="${PAGES_DIR}/90_Labs_${STREAMLIT_SUFFIX}.py"

if [[ -d "$LAB_DIR" ]]; then
  echo "❌ Lab already exists: $LAB_DIR" >&2
  exit 1
fi

mkdir -p "$LAB_DIR"/{docs,data,notebooks,prototype,spikes}

cat > "${LAB_DIR}/README.md" <<MD
# Lab: ${TITLE}

此 Lab 用於研究「${TITLE}」，尚未進入正式後端模組。請維持以下慣例：

- 在 \
`docs/` 紀錄假設、觀察、風險。
- 將練習腳本放入 `spikes/`，可使用 `make lab-spike name=${SLUG} title="My Spike"` 自動生成。
- 可重複的 PoC/函式整理到 `prototype/`，供 Streamlit 或其他工具呼叫。
- 小型示例資料放 `data/`，避免存放真實/敏感資料。
- 落實評估後，於 docs/rfc/ 與 docs/specs/ 撰寫對應文件，方可進入產品化流程。
MD

touch "${LAB_DIR}/docs/.gitkeep" "${LAB_DIR}/data/.gitkeep" \
      "${LAB_DIR}/notebooks/.gitkeep" "${LAB_DIR}/spikes/.gitkeep"

cat > "${LAB_DIR}/prototype/__init__.py" <<PY
"""Prototype helpers for the ${TITLE} lab."""
from __future__ import annotations

from typing import Any


def placeholder(*args: Any, **kwargs: Any) -> str:
    """Temporary prototype entry-point. Replace with real implementation."""
    _ = (args, kwargs)
    return "TODO: implement prototype logic."
PY

mkdir -p "$PAGES_DIR"

cat > "$STREAMLIT_PAGE" <<PY
"""Streamlit page for Labs: ${TITLE}."""
from __future__ import annotations

import streamlit as st

from labs.${SLUG}.prototype import placeholder

st.set_page_config(page_title="Labs: ${TITLE}", page_icon="🧪", layout="wide")
st.title("🧪 Labs: ${TITLE}")
st.caption("此頁面僅供內部實驗使用，尚未對外提供 API。")

st.write("請在 `labs/${SLUG}/prototype/` 內撰寫可重複的實驗函式並於此處呼叫。")

with st.form("labs-${SLUG}-form"):
    st.text_input("輸入參數", key="input")
    submitted = st.form_submit_button("執行 Prototype")

if submitted:
    result = placeholder()
    st.success("Placeholder 執行完成，請替換為實際邏輯。")
    st.write(result)
else:
    st.info("調整 prototype.placeholder 後，可在此檢視結果。")
PY

echo "✅ Lab created: ${LAB_DIR}"
echo "✅ Streamlit page: ${STREAMLIT_PAGE}"
