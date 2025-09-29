
⸻

Coding Standards

這份文件定義專案共用的 Clean Architecture 原則與程式撰寫風格，供開發與 Code Review 參考。所有新加入的同仁請在開始實作前閱讀一次；Review 時也以此文作為討論基準。

⸻

1. Clean Architecture 約定

系統分層

app/
├─ api/            # FastAPI endpoints, routing, request/response DTO
├─ modules/
│  └─ <feature>/   # 每個模組含 use cases、domain、repositories 等
└─ core/           # 共用基礎（config、errors、infrastructure）

依賴方向
- API 層 → Modules（use case/service）
- Modules → Domain models → Repository 介面
- Infrastructure（資料庫、外部 API 實作）反向注入到 Repository 介面
- Tests 可針對 Repository 介面提供 fake / stub

實作指引
- Use Case 函式（services.py）不直接存取 FastAPI context；透過輸入 DTO/domain model 與 repository 介面來達成。
- Domain 層保持無框架依賴，僅純 Python 或 Pydantic 型別。
- Repository 介面聲明於 modules/<feature>/repositories.py，實作放 infrastructure 模組或 modules/<feature>/repositories_impl.py。
- 以 dependency override（app/api/deps.py）注入實作，方便測試替換。
- 禁止跨模組直接 import 彼此的 repository/DTO；改透過明確定義的服務介面或事件。
- 新增模組以 `make module name=<mod>` 生成標準骨架。

資料流與錯誤處理
- 所有錯誤轉換成 domain/custom errors，API 層統一轉換成 HTTPException。
- 日誌（logging）在 service 層記錄業務決策點；API 層僅負責 request/response。
- 阻塞 I/O 儘量使用 async repository 方法（遵循 FastAPI async 流程），必要時包裝到執行緒池。

測試策略
- 單元測試主要覆蓋 services/domain；API 層使用 TestClient 進行整合。
- 測試時以 fake repository 取代實際實作，不直接打 DB。

⸻

2. Coding Style（Code Review 指標）

語言與工具
- 全面啟用型別標註（PEP 484）；缺少型別時 Review 應要求補齊。
- Docstring 使用 Google 風格或簡短描述，僅在邏輯複雜的 use case / helper 函式撰寫。
- 遵守 Ruff / Black 預設規則；必要時以 `# noqa` / `fmt: off` 註記並附註理由。

模組/檔案規範
- services.py：僅含 use case 邏輯；避免直接調用 CRUD。
- schemas.py：定義 API 層輸入輸出 DTO；內部 domain 模型放在 entities.py。
- repositories.py：只定義界面；實作細節分離。
- __init__.py：不做 wildcard export；僅暴露需要的介面。

程式風格要點
- 函式命名採動詞_名詞，例如 `create_user`、`list_tokens`。
- 類別使用 PascalCase，常數採 SCREAMING_SNAKE_CASE。
- 控制流程偏好 guard clause，避免巢狀 if。
- 例外處理只捕捉可預期錯誤並加入說明訊息；不要吞掉 Exception。
- logging 使用結構化訊息，例如 `logger.info("user.signup", user_id=user.id)`。
- 需共用的 magic number / 字串拉到設定或常數檔。

測試撰寫
- 測試檔案命名 `test_<module>_*.py`；測試函式 `test_should_<結果>`。
- 使用 Given/When/Then 註解或空行區隔場景。
- 對 async 邏輯使用 pytest mark `@pytest.mark.asyncio` 或 python 3.11 task fixture。
- 測試資料固定值集中在 fixture；避免在測試內硬編碼多組 ID。

Code Review 核對清單
- **Architecture**：依賴方向正確？Domain 是否被 API 層或框架綁定？
- **Readability**：函式/變數命名準確？是否拆分為可重用的純邏輯？
- **Correctness**：Edge cases 是否有測試覆蓋？例外是否轉換成標準錯誤？
- **Performance**：資料庫/網路呼叫是否在迴圈內？是否需要快取策略？
- **Security**：輸入驗證充足？是否有權限檢查與敏感資訊遮罩？
- **Docs & Specs**：功能是否更新對應 SPEC、OpenAPI、CHANGELOG？
- **Tooling**：Ruff/pytest 是否通過？CI 需要的 scripts 是否更新？

⸻

3. 實務建議
- 新功能起手式：先補 SPEC 與 use case 草稿，再開發。
- 寫 Code 前先想測試場景；PR 前確定 `make test` 綠燈。
- Review 時針對「偏離規範」部分提出具體改善建議，附上條目編號。
- 若有合理例外，請在 PR 描述或程式碼旁以註解說明原因。

⸻

