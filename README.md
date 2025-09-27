
# FastAPI Server Template

一個基於 FastAPI 的現代化後端服務模板，採用 DDD（領域驅動設計）架構模式。

## 快速開始

### 1. 專案初始化

```bash
# 建立專案目錄結構
./project-initiator.sh

# 建立隔離環境（自動處理venv）
uv sync
```

### 2. 環境設定

```bash
# 複製環境變數範本
cp .env.example .env

# 編輯環境變數
nano .env
```

### 3. 啟動服務

```bash
# 開發模式啟動
uv run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# 或使用預設腳本
uv run python main.py
```

### 4. 驗證安裝

訪問 http://localhost:8000/docs 查看 API 文檔

## 專案特色

- 🏗️ **DDD 架構**: 採用領域驅動設計，模組化清晰
- 🔒 **安全認證**: JWT Token 認證機制
- 📊 **結構化日誌**: 整合 uvicorn 日誌系統
- 🧪 **測試友好**: 完整的單元測試和 API 測試架構
- ⚡ **高效能**: 基於 FastAPI 和 SQLAlchemy
- 🔧 **開發工具**: 整合 uv 包管理器

## 開發指南

### 依賴管理

```bash
# 新增依賴
uv add package-name

# 新增開發依賴
uv add --dev package-name

# 更新依賴
uv sync --upgrade
```

### 資料庫遷移

```bash
# 建立遷移檔案
alembic revision --autogenerate -m "描述"

# 執行遷移
alembic upgrade head

# 回滾遷移
alembic downgrade -1
```

### 測試

```bash
# 執行所有測試
uv run pytest

# 執行特定測試
uv run pytest tests/unit/test_auth_services.py

# 生成覆蓋率報告
uv run pytest --cov=app --cov-report=html
```

### 程式碼品質

```bash
# 格式化程式碼
uv run black .

# 檢查程式碼風格
uv run flake8 .

# 型別檢查
uv run mypy app/
```

## 部署

### Docker 部署

```bash
# 建構映像
docker build -t fastapi-app .

# 執行容器
docker run -p 8000:8000 fastapi-app
```

### 環境變數

主要環境變數設定：

```env
# 應用設定
APP_NAME=FastAPI Server
DEBUG=true
SECRET_KEY=your-secret-key

# 資料庫
DATABASE_URL=postgresql://user:password@localhost/dbname

# JWT 設定
JWT_SECRET_KEY=your-jwt-secret
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=30
```

## 架構說明

### 設計原則

- **分層架構**: 清晰的分層設計，職責分離
- **依賴注入**: 使用 FastAPI 的依賴注入系統
- **領域驅動**: 每個模組代表一個業務領域
- **測試驅動**: 完整的測試覆蓋

### 模組說明

- **core/**: 核心功能，包含配置、安全、異常處理
- **middleware/**: 全域中介層，處理請求/響應
- **shared/**: 共用工具和技術組件
- **api/**: API 層，處理 HTTP 請求和響應
- **modules/**: 業務模組，每個模組包含完整的 DDD 結構

## 貢獻指南

1. Fork 專案
2. 建立功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交變更 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 開啟 Pull Request

## 授權

此專案採用 MIT 授權 - 查看 [LICENSE](LICENSE) 檔案了解詳情。

## 聯絡方式

如有問題或建議，請開啟 Issue 或聯絡開發團隊。

---

### Folder Structure

``` text
app/
├─ main.py                         # 入口：掛 Router、Middleware、啟動鉤子
│
├─ core/                           # 橫切關注（環境設定/安全/錯誤/日誌）
│  ├─ config.py                    # pydantic-settings 讀 .env，集中設定
│  ├─ security.py                  # JWT、API Key、密鑰工具
│  ├─ exceptions.py                # 自訂例外與全域處理器
│  └─ logging.py                   # 結構化日誌/uvicorn 整合
│
├─ middleware/                     # 全域 ASGI 中介層
│  └─ timings.py                   # 請求耗時、追蹤 header 等
│
├─ shared/                         # 技術共用（與業務無關）
│  ├─ db.py                        # SQLAlchemy/SQLModel engine、SessionLocal
│  ├─ utils.py                     # 雜項工具、格式轉換
│  └─ types.py                     # 共用型別、基底 class
│
├─ api/                            # Presentation 層（僅 I/O 與 orchestration）
│  ├─ deps.py                      # 跨模組 Depends（如 get_current_user）
│  └─ v1/
│     ├─ router.py                 # /v1 聚合所有模組路由
│     ├─ auth.py                   # auth 對外 API（呼叫 modules.auth.services）
│     └─ ocr.py                    # ocr 對外 API（呼叫 modules.ocr.services）
│
├─ modules/                        # ⭐ 每個模組自成分層（DDD 子域）
│  └─ auth/
│    ├─ domain/
│    │  ├─ models.py              # POJO/值物件（不依賴框架）
│    │  └─ ports.py               # 抽象介面（UserRepository, TokenService）
│    ├─ schemas.py                # DTO（SignupIn, TokenOut…）
│    ├─ services.py               # 業務邏輯（註冊/登入/發 token）
│    ├─ infra/
│    │  ├─ orm.py                 # ORM 實體（UserORM）→ Alembic 追蹤
│    │  ├─ repositories.py        # SqlUserRepo 實作 UserRepository
│    │  └─ token_jwt.py           # JwtTokenService 實作 TokenService
│    └─ deps.py                   # 本模組依賴注入（get_auth_service）
│  
│
└─ tests/                          # 測試
   ├─ unit/                        # Service/Domain 單元測試（注入 fake ports）
   │  └─ test_auth_services.py
   └─ api/                         # API 測試（TestClient + dependency_overrides）
      └─ test_auth_api.py
```