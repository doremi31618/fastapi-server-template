#!/usr/bin/env bash
# 自動建立 SPEC：自動編號、自動版號
# 用法：
#   bash scripts/new_spec.sh "<Title>" <module> [bump=patch|minor|major] [id=SPEC-123]
# 範例：
#   bash scripts/new_spec.sh "Auth Signup" auth
#   bash scripts/new_spec.sh "Auth Login" auth bump=minor
#   bash scripts/new_spec.sh "Billing Create Invoice" billing
#   bash scripts/new_spec.sh "Custom Spec" auth id=SPEC-150   # 手動指定 ID（跳過自動編號）

set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 \"<Title>\" <module> [bump=patch|minor|major] [id=SPEC-123]"
  exit 1
fi

TITLE="$1"
MODULE="$2"
BUMP="new"   # new=首次建立 → 1.0.0
ID_OVERRIDE=""
for arg in "${@:3}"; do
  case "$arg" in
    bump=patch|bump=minor|bump=major) BUMP="${arg#bump=}";;
    id=SPEC-*) ID_OVERRIDE="${arg#id=}";;
    *) echo "Unknown arg: $arg" ;;
  esac
done

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPECS_DIR="$ROOT/docs/specs"
INDEX_FILE="$SPECS_DIR/SPEC-000-index.md"
mkdir -p "$SPECS_DIR"

# 1) 模組 → 號段對應（可自行調整）
#   建議：auth=1xx、billing=3xx、… 未列到的模組走 9xx
declare -A MOD_RANGE=(
  [auth]=1
  [billing]=3
  [user]=4
)
RANGE_PREFIX="${MOD_RANGE[$MODULE]:-9}"   # 未列到給 9xx
RANGE_START=$((RANGE_PREFIX * 100))       # 100, 300, 400...
RANGE_END=$((RANGE_START + 99))           # 199, 399, 499...

slugify() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g;s/^-|-$//g'
}
SLUG="$(slugify "$TITLE")"

# 2) 自動編號（若未手動指定 ID）
if [[ -n "$ID_OVERRIDE" ]]; then
  SPEC_ID="$ID_OVERRIDE"
else
  # 找出該號段目前最大編號
  # 例：auth → SPEC-1xx，掃描 docs/specs/SPEC-1*.md
  max_n=0
  shopt -s nullglob
  for f in "$SPECS_DIR"/SPEC-*.md; do
    base="$(basename "$f")"
    # 取出數字：SPEC-123-xxx.md → 123
    if [[ "$base" =~ ^SPEC-([0-9]{3,})- ]]; then
      n="${BASH_REMATCH[1]}"
      if (( n >= RANGE_START && n <= RANGE_END )); then
        (( n > max_n )) && max_n=$n
      fi
    fi
  done
  shopt -u nullglob

  next=$(( max_n > 0 ? max_n + 1 : RANGE_START ))
  if (( next > RANGE_END )); then
    echo "❌ 號段已滿：${RANGE_START}-${RANGE_END}，請調整 MOD_RANGE 或手動提供 id=SPEC-xxx"
    exit 1
  fi
  SPEC_ID="SPEC-$(printf "%03d" "$next")"
fi

OUT_FILE="$SPECS_DIR/${SPEC_ID}-${MODULE}-${SLUG}.md"

# 3) 自動版號
#   new → 1.0.0；bump=patch/minor/major → 掃描同 SPEC_ID 舊檔（如重開規格）或直接從 1.0.0 依 bump
semver_bump() {
  local ver="$1" part="$2"
  IFS='.' read -r MA MI PA <<< "$ver"
  case "$part" in
    patch) echo "${MA}.${MI}.$((PA+1))" ;;
    minor) echo "${MA}.$((MI+1)).0" ;;
    major) echo "$((MA+1)).0.0" ;;
    *) echo "$ver" ;;
  esac
}

DEFAULT_NEW="1.0.0"
SPEC_VERSION="$DEFAULT_NEW"

# 若該 SPEC_ID 曾存在其他檔（理論上不會重複；這裡保留邏輯供擴充），可從中取最後版號再 bump
# 目前簡化：new → 1.0.0；如果你想強制 bump，依參數 bump=xxx 從 1.0.0 升
if [[ "$BUMP" != "new" ]]; then
  SPEC_VERSION="$(semver_bump "$DEFAULT_NEW" "$BUMP")"
fi

# 4) 產出檔案
if [[ -f "$OUT_FILE" ]]; then
  echo "❌ File exists: $OUT_FILE"
  exit 1
fi

cat > "$OUT_FILE" <<EOF
---
spec_id: $SPEC_ID
spec_version: $SPEC_VERSION
status: Draft
module: $MODULE
introduced_in_app: 0.0.0
endpoints: []
tests: []
---
# $SPEC_ID: $TITLE

## 背景
（描述目標與動機）

## 需求
- 功能性：
- 非功能性：

## API
（列出 endpoint、請求/回應模型）

## 驗收
- 測試案例：
- 錯誤處理：

## 安全
（驗證、授權、風險）
EOF

echo "✅ SPEC created: $OUT_FILE"

# 5) 更新索引（若存在）
if [[ -f "$INDEX_FILE" ]]; then
  # 若索引裡沒有這筆才追加
  if ! grep -qE "^\| ${SPEC_ID} " "$INDEX_FILE"; then
    # 兼容 macOS/BSD sed：先備份再移除
    cp "$INDEX_FILE" "$INDEX_FILE.bak"
    printf '| %s | %s | %s | %s | %s | %s |\n' "$SPEC_ID" "$TITLE" "$SPEC_VERSION" "$MODULE" "Draft" "0.0.0" >> "$INDEX_FILE"
    rm -f "$INDEX_FILE.bak"
    echo "📝 index updated: $INDEX_FILE"
  fi
else
  echo "ℹ️ No index file found: $INDEX_FILE (optional)"
fi