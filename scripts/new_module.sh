#!/usr/bin/env bash
# 用法:
#   bash scripts/new_module.sh <module_name>
# 例:
#   bash scripts/new_module.sh billing
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <module_name>"; exit 1
fi

MOD="$1"                          # 模組代號（路由/資料夾用）
MOD_TAG="$(echo "$MOD" | tr '[:lower:]' '[:upper:]')"   # 路由 tags 顯示
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 基本路徑檢查
[[ -d "$ROOT_DIR/app" ]]  || { echo "❌ 找不到 app/，請在專案根目錄下執行"; exit 1; }
[[ -d "$ROOT_DIR/docs" ]] || { echo "❌ 找不到 docs/，請在專案根目錄下執行"; exit 1; }

MOD_DIR="$ROOT_DIR/app/modules/$MOD"
API_DIR="$ROOT_DIR/app/api/v1"
ROUTER_FILE="$API_DIR/router.py"

if [[ -d "$MOD_DIR" ]]; then
  echo "⚠️ 模組已存在: $MOD_DIR"; exit 1
fi

echo "📦 建立模組骨架：$MOD"
mkdir -p "$MOD_DIR"/{domain,infra,docs}
touch "$MOD_DIR/__init__.py" "$MOD_DIR/domain/__init__.py" "$MOD_DIR/infra/__init__.py"

# schemas.py
cat > "$MOD_DIR/schemas.py" <<'EOF'
from pydantic import BaseModel

class PingOut(BaseModel):
    ok: bool = True
EOF

# domain/models.py
cat > "$MOD_DIR/domain/models.py" <<'EOF'
from dataclasses import dataclass
@dataclass(slots=True)
class Example:
    id: int | None
    name: str
EOF

# domain/ports.py
cat > "$MOD_DIR/domain/ports.py" <<'EOF'
from typing import Protocol, Iterable
from .models import Example

class ExampleRepository(Protocol):
    def save(self, obj: Example) -> Example: ...
    def list_all(self) -> Iterable[Example]: ...
EOF

# infra/orm.py（可按需替換為實際 ORM）
cat > "$MOD_DIR/infra/orm.py" <<'EOF'
# 放置 SQLModel/SQLAlchemy ORM 實體（如需）
# 例:
# from typing import Optional
# from sqlmodel import SQLModel, Field
#
# class ExampleORM(SQLModel, table=True):
#     __tablename__ = "examples"
#     id: Optional[int] = Field(default=None, primary_key=True)
#     name: str
EOF

# infra/repositories.py（in-memory 範例，之後可換 SQL 版本）
cat > "$MOD_DIR/infra/repositories.py" <<'EOF'
from typing import Iterable
from app.modules.__MODULE__.domain.ports import ExampleRepository
from app.modules.__MODULE__.domain.models import Example

class InMemoryExampleRepo(ExampleRepository):
    def __init__(self):
        self._store: list[Example] = []
    def save(self, obj: Example) -> Example:
        self._store.append(obj); return obj
    def list_all(self) -> Iterable[Example]:
        return list(self._store)
EOF
# 替換占位符
sed -i.bak "s/__MODULE__/$MOD/g" "$MOD_DIR/infra/repositories.py" && rm "$MOD_DIR/infra/repositories.py.bak"

# services.py
cat > "$MOD_DIR/services.py" <<'EOF'
from app.modules.__MODULE__.domain.ports import ExampleRepository
from app.modules.__MODULE__.domain.models import Example

class __CLASS__Service:
    def __init__(self, repo: ExampleRepository):
        self.repo = repo

    def ping(self) -> dict:
        return {"ok": True}

    def create_example(self, name: str) -> Example:
        return self.repo.save(Example(id=None, name=name))
EOF
# 產生類別名（首字母大寫）
CLASS_NAME="$(python - <<PY
s="$MOD"
print(s[:1].upper()+s[1:])
PY
)"
sed -i.bak "s/__MODULE__/$MOD/g; s/__CLASS__/$CLASS_NAME/g" "$MOD_DIR/services.py" && rm "$MOD_DIR/services.py.bak"

# deps.py
cat > "$MOD_DIR/deps.py" <<'EOF'
from fastapi import Depends
from app.modules.__MODULE__.infra.repositories import InMemoryExampleRepo
from app.modules.__MODULE__.services import __CLASS__Service

def get___MODULE___service(repo: InMemoryExampleRepo = Depends(lambda: InMemoryExampleRepo())) -> __CLASS__Service:
    return __CLASS__Service(repo=repo)
EOF
sed -i.bak "s/__MODULE__/$MOD/g; s/__CLASS__/$CLASS_NAME/g" "$MOD_DIR/deps.py" && rm "$MOD_DIR/deps.py.bak"

# 模組 docs
cat > "$MOD_DIR/docs/README.md" <<EOF
# Module: $MOD

- **Responsibility**: （請描述此模組的業務範圍）
- **Related SPECs**: （列出 SPEC IDs，如 SPEC-1xx）
- **Key Endpoints**: （舉例：/v1/$MOD/ping）
- **DB Entities**: （如有 ORM，列出）
- **Ownership**: （負責團隊/聯絡人）
EOF

# API 路由檔
API_FILE="$API_DIR/$MOD.py"
cat > "$API_FILE" <<EOF
from fastapi import APIRouter, Depends
from app.modules.$MOD.deps import get_${MOD}_service
from app.modules.$MOD.schemas import PingOut
from app.modules.$MOD.services import ${CLASS_NAME}Service

router = APIRouter(tags=["$MOD_TAG"])

@router.get("/$MOD/ping", response_model=PingOut)
def ping(svc: ${CLASS_NAME}Service = Depends(get_${MOD}_service)):
    return svc.ping()
EOF

# 確保 router.py 存在
mkdir -p "$API_DIR"
if [[ ! -f "$ROUTER_FILE" ]]; then
  cat > "$ROUTER_FILE" <<'EOF'
from fastapi import APIRouter
api_router = APIRouter()
# <<modules>>
EOF
fi

# 將新路由掛到 router.py
IMPORT_LINE="from .${MOD} import router as ${MOD}_router"
INCLUDE_LINE="api_router.include_router(${MOD}_router)"
if ! grep -q "$IMPORT_LINE" "$ROUTER_FILE"; then
  # 在 # <<modules>> 前插入 import；若找不到，就追加到檔尾
  if grep -q "# <<modules>>" "$ROUTER_FILE"; then
    # 插入 import
    awk -v imp="$IMPORT_LINE" '/# <<modules>>/ {print imp} {print}' "$ROUTER_FILE" > "$ROUTER_FILE.tmp" && mv "$ROUTER_FILE.tmp" "$ROUTER_FILE"
    # 插入 include
    awk -v inc="$INCLUDE_LINE" '/# <<modules>>/ {print; print inc; next}1' "$ROUTER_FILE" > "$ROUTER_FILE.tmp" && mv "$ROUTER_FILE.tmp" "$ROUTER_FILE"
  else
    # 不存在錨點就直接附加
    {
      echo "$IMPORT_LINE"
      echo "$INCLUDE_LINE"
    } >> "$ROUTER_FILE"
  fi
fi

echo "✅ 模組 $MOD 已建立："
echo " - $MOD_DIR"
echo " - $API_FILE"
echo " - $ROUTER_FILE 已加入對應路由"
echo "🧪 試試看：GET /v1/$MOD/ping"