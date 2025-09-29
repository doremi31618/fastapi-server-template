"""Streamlit page for Labs: Pdfdf Analysisnalysis Processrocess."""
from __future__ import annotations

import streamlit as st

from labs.pdf-analysis-process.prototype import placeholder

st.set_page_config(page_title="Labs: Pdfdf Analysisnalysis Processrocess", layout="wide")
st.title("Labs: Pdfdf Analysisnalysis Processrocess")
st.caption("此頁面僅供內部實驗使用，尚未對外提供 API。")

st.write("請在  內撰寫可重複的實驗函式並於此處呼叫。")

with st.form("labs-pdf-analysis-process-form"):
    st.text_input("輸入參數", key="input")
    submitted = st.form_submit_button("執行 Prototype")

if submitted:
    result = placeholder()
    st.success("Placeholder 執行完成，請替換為實際邏輯。")
    st.write(result)
else:
    st.info("調整 prototype.placeholder 後，可在此檢視結果。")
