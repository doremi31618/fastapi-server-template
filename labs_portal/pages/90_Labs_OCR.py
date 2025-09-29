"""Streamlit interface for OCR labs experiments."""
from __future__ import annotations

import io

from PIL import Image
import streamlit as st

from labs.ocr.prototype import run_ocr

st.set_page_config(page_title="Labs: OCR", layout="wide")
st.title("Labs: OCR Prototype")
st.caption(
    "此頁面僅供內部實驗使用，尚未對外提供 API。請先於終端執行 `uv sync -E labs-ocr` 安裝依賴。"
)

uploaded = st.file_uploader("上傳圖片", type=["png", "jpg", "jpeg", "bmp"])

col_in, col_out = st.columns(2)

with col_in:
    st.subheader("輸入影像")
    if uploaded:
        image = Image.open(uploaded)
        st.image(image, use_container_width=True)

with col_out:
    st.subheader("OCR 結果")
    if uploaded and st.button("執行 OCR", type="primary"):
        content = uploaded.read()
        try:
            text = run_ocr(content)
            st.text_area("文字輸出", text, height=320)
        except RuntimeError as exc:
            st.error(str(exc))
        except Exception as exc:  # pylint: disable=broad-except
            st.error(f"處理失敗: {exc}")
    else:
        st.info("上傳影像並按下按鈕開始辨識。")

st.divider()
st.markdown(
    "- 原始樣本可放於 `labs/ocr/data/` 內測試。\n"
    "- 實驗過程請同步更新 `docs/rfc/`、`docs/system-design/benchmarks/` 與 SPEC 草稿。"
)
