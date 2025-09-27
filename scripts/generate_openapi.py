# scripts/generate_openapi.py
import json
import os
import sys

# 確保能找到 app/ 資料夾
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.main import app  # 從 app/main.py 匯入 FastAPI 物件

def main():
    output_dir = os.path.join("docs", "api-reference")
    os.makedirs(output_dir, exist_ok=True)

    output_file = os.path.join(output_dir, "openapi.json")
    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(app.openapi(), f, indent=2, ensure_ascii=False)

    print(f"✅ OpenAPI spec 已產生：{output_file}")

if __name__ == "__main__":
    main()