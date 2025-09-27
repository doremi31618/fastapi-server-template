"""Entry point for Labs Streamlit multi-page app."""
from __future__ import annotations

import pathlib
import textwrap

import streamlit as st

PAGES_DIR = pathlib.Path(__file__).resolve().parent / "pages"

st.set_page_config(page_title="Labs Portal", page_icon="🧪", layout="wide")
st.title("🧪 Labs Portal")
st.caption("集中管理所有 labs/ 實驗頁，視作內部研究入口。")

st.markdown(
    textwrap.dedent(
        """
        - 若列表中沒有你的 Lab，可執行 `make lab name=<lab> title="..."` 自動建立。
        - Streamlit 會自動載入 `ui/streamlit/pages/*.py` 作為分頁。
        - Prototype 相關函式放在 `labs/<lab>/prototype/`，並由對應分頁呼叫。
        """
    )
)

existing_pages = sorted(PAGES_DIR.glob("*.py"))
if not existing_pages:
    st.warning("目前沒有任何 Lab 頁面。請先執行 make lab 建立新 Lab。")
else:
    st.write("### 可用的 Lab Pages")
    for page in existing_pages:
        st.write(f"- `{page.name}`")

st.info("使用左側 Streamlit Pages 選單切換不同實驗頁面。")
