"""
FastAPI 應用程式主入口點
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# 建立 FastAPI 應用程式實例
app = FastAPI(
    title="FastAPI Server Template",
    description="一個基於 FastAPI 的現代化後端服務模板",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# 設定 CORS 中介層
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 在生產環境中應該設定具體的域名
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    """根路徑健康檢查"""
    return {"message": "FastAPI Server Template is running!", "status": "healthy"}

@app.get("/health")
async def health_check():
    """健康檢查端點"""
    return {"status": "healthy", "message": "Service is running"}

# 這裡可以添加更多的路由
# from app.api.v1.router import api_router
# app.include_router(api_router, prefix="/api/v1")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
