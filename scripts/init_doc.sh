#!/usr/bin/env bash
# 初始化文件目錄結構
# 用法: bash scripts/init_docs.sh

set -e

echo "📂 建立 docs 目錄結構..."

mkdir -p docs/{specs,api-reference,system-design/diagrams,adr,rfc,runbooks,onboarding,test-plans,threat-model}

# 規格索引
cat > docs/specs/SPEC-000-index.md <<'EOF'
# 規格索引 (SPEC Index)

| Spec ID   | Title         | Version | Module | Status    | Introduced in App |
|-----------|---------------|---------|--------|-----------|-------------------|
| SPEC-101  | Auth Signup   | 1.0.0   | auth   | Accepted  | 1.0.0             |

EOF

# ADR 範例
cat > docs/adr/ADR-0001-use-fastapi.md <<'EOF'
# ADR-0001: Use FastAPI as Web Framework

- Status: Accepted
- Date: 2025-09-27
- Context: Evaluate web frameworks
- Decision: Use FastAPI
- Consequences: Async-first, strong typing, OpenAPI out-of-box
EOF

# README for API reference
cat > docs/api-reference/README.md <<'EOF'
# API Reference

本資料夾包含：
- OpenAPI 規格檔 (`openapi.json`)
- 其他補充文件
EOF

# system-design context-map
cat > docs/system-design/context-map.md <<'EOF'
# 系統設計 - Context Map

此處收錄整體架構圖、模組互動圖與序列圖。
EOF

# changelog
cat > docs/CHANGELOG.md <<'EOF'
# Changelog

## [Unreleased]

## [1.0.0] - 2025-09-27
- 初始化文件架構
EOF

echo "✅ 文件目錄建立完成！"