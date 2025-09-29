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

並在 `labs_portal/pages/` 下建立對應的實驗頁面範本，方便使用 Streamlit 驗證概念。

### Spike 是什麼？

- Spike 放在 `labs/<lab>/spikes/`，以單一腳本快速驗證概念、量測效能或測試外部套件。
- 不需整理成完整模組；驗證成功後，再把穩定的邏輯抽成 `prototype/` 供重用。
- 建議透過 `make lab-spike name=<lab> title="My Spike"` 產生模板，保持結構一致。

### 文件撰寫建議

- 使用 `labs/<lab>/docs/` 撰寫研究筆記、假設與決策說明（Markdown）。
- 將量測或比較結果輸出到 `docs/system-design/benchmarks/`，標註日期、樣本與指標。
- 產品化討論請補足對應的 RFC（`docs/rfc/`）與 SPEC 草稿（`docs/specs/`）。
- 在 PR 中引用上述文件位置，方便評審追蹤實驗進度。
