# Labs Workspace

`labs/` 目錄用來承載尚未產品化的實驗與原型。所有內容預設為內部研究用途，與正式模組 (`app/`) 完全隔離。

## 原則

- 每個子目錄是一個獨立 Lab，例如 `labs/ocr/`。
- Lab 內可以隨意迭代，但提交 PR 時務必附上對應的 RFC、Benchmarks 或筆記。
- 實驗依賴請透過 `uv sync -E <group>` 安裝，避免污染主環境。
- 敏感或大型資料放於外部儲存，僅在 `data/` 目錄放示意檔並以 `.gitkeep` 留位。

## 建立新的 Lab

```bash
make lab name=ocr title="OCR Pipeline"
```

會自動產生：

```
labs/ocr/
├─ README.md
├─ docs/
├─ notebooks/
├─ data/
├─ prototype/
└─ spikes/
```

並在 `ui/streamlit/pages/` 下建立對應的實驗頁面範本，方便使用 Streamlit 驗證概念。
