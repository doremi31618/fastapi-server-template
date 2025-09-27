# Labs: OCR Research

此區域用於探索與驗證 OCR 能力，尚未進入正式後端模組。請遵循以下原則：

- **目的**：紀錄假設、原型、數據，支援 RFC 與產品化評估。
- **範圍**：僅供內部實驗；輸出結果需在 docs/ 下對應的 RFC/SPEC/benchmarks 中整理。
- **依賴**：使用 `uv sync -E labs-ocr` 安裝附加套件，避免污染主專案。
- **資料**：僅放匿名或合規樣本於 `data/`，大型資料集請改用雲端儲存並以環境變數指示路徑。

## 目錄對應

- `notebooks/`：Jupyter 筆記或互動實驗。
- `spikes/`：短期驗證腳本或 CLI 原型，用來快速試驗概念；成功後再將穩定邏輯抽到 `prototype/`。
- `prototype/`：可供他人重複操作的函式與 PoC。
- `docs/`：實驗紀錄、觀察結果。
- `data/`：小型示例資料（確保 .gitignore 遮蔽私密檔）。

## 研究流程建議

1. 於 RFC 撰寫問題與預期成果（草稿可放在 docs/rfc/）。
2. 在 `spikes/` 撰寫快速驗證腳本，或於 `notebooks/` 試驗不同方案。
3. 將穩定做法抽象成 `prototype/` 下的函式，提供 Streamlit 頁面或其他人調用。
4. 撰寫 Benchmark 腳本並輸出數據到 `docs/system-design/benchmarks/`。
5. 達成產品化條件後，再進入 app/modules/ 完整實作與規格更新。

---

需要新的 spike? 使用 `make lab-spike name=ocr title="My Experiment"`。
