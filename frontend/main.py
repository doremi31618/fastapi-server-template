"""Streamlit app bootstrap for the FastAPI server template."""
from __future__ import annotations

import json
import os
from typing import Any, Dict

import httpx
import streamlit as st

DEFAULT_BACKEND_URL = os.getenv("FASTAPI_BASE_URL", "http://localhost:8000")


def build_url(base: str, path: str) -> str:
    """Return a normalized URL for the backend."""
    base = base.rstrip("/")
    if not path.startswith("/"):
        path = "/" + path
    return base + path


def request_json(url: str, method: str = "GET", payload: Dict[str, Any] | None = None) -> Dict[str, Any]:
    """Send an HTTP request to the backend and return JSON payload."""
    with httpx.Client(timeout=5.0) as client:
        response = client.request(method, url, json=payload)
        response.raise_for_status()
        return response.json()


st.set_page_config(
    page_title="FastAPI + Streamlit Starter",
    page_icon="⚡",
    layout="wide",
)

st.title("FastAPI + Streamlit Starter")
st.write(
    "此頁面提供與 FastAPI 後端互動的簡易界面，適合作為前端原型與可視化起點。"
)

with st.sidebar:
    st.header("後端設定")
    st.caption("設定 Streamlit 與 FastAPI 後端的連線資訊。")
    backend_url = st.text_input("FastAPI Base URL", value=DEFAULT_BACKEND_URL)
    st.write("預設指向本機端的 8000 連接埠。")
    st.divider()
    st.markdown("**使用技巧**")
    st.markdown(
        "- 若後端部署於其他主機，請填入完整 URL (例如 https://api.example.com)\n"
        "- 可在終端機執行 `make dev` 以啟動 FastAPI，再執行 `make streamlit`"
    )

col_health, col_root = st.columns(2)

with col_health:
    st.subheader("健康檢查")
    try:
        health_data = request_json(build_url(backend_url, "/health"))
        st.success("後端健康檢查成功！")
        st.json(health_data, expanded=False)
    except httpx.HTTPError as exc:
        st.error(f"無法連線至後端: {exc}")
    except Exception as exc:  # pylint: disable=broad-except
        st.error(f"發生未知錯誤: {exc}")

with col_root:
    st.subheader("根路徑回應")
    try:
        root_data = request_json(build_url(backend_url, "/"))
        st.success("成功取得根路徑回應")
        st.code(json.dumps(root_data, indent=2, ensure_ascii=False))
    except httpx.HTTPError as exc:
        st.error(f"無法取得根路徑資料: {exc}")
    except Exception as exc:  # pylint: disable=broad-except
        st.error(f"發生未知錯誤: {exc}")

st.divider()

st.subheader("即席 API 請求")
st.caption("輸入任意路徑發送 GET 請求，快速檢視 JSON 回應。")

with st.form("api-prober"):
    path = st.text_input("路徑", value="/health", help="例如 /api/v1/users")
    submitted = st.form_submit_button("發送請求")

if submitted:
    try:
        data = request_json(build_url(backend_url, path))
        st.write("### 回應 JSON")
        st.json(data)
    except httpx.HTTPError as exc:
        st.error(f"後端回應錯誤: {exc}")
        if exc.response is not None:
            try:
                st.code(json.dumps(exc.response.json(), indent=2, ensure_ascii=False))
            except Exception:  # pylint: disable=broad-except
                st.code(exc.response.text)
    except Exception as exc:  # pylint: disable=broad-except
        st.error(f"請求失敗: {exc}")

st.info(
    "✅ 建議做法：在 `frontend/` 目錄新增頁面或元件，將此範例擴充成完整 UI。"
)
