#!/bin/bash
# 将 shared/cloudbase-common.js 同步到每个云函数目录
# 使用方法：在项目根目录运行 bash scripts/sync-cloud-shared.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SHARED_SRC="$PROJECT_ROOT/cloudfunctions/shared/cloudbase-common.js"
FUNCTIONS_DIR="$PROJECT_ROOT/cloudfunctions"

if [ ! -f "$SHARED_SRC" ]; then
  echo "❌ 找不到源文件: $SHARED_SRC"
  exit 1
fi

count=0
for func_dir in "$FUNCTIONS_DIR"/*/; do
  func_name=$(basename "$func_dir")
  # 跳过 shared 目录和 __mocks__
  if [ "$func_name" = "shared" ] || [ "$func_name" = "__mocks__" ]; then
    continue
  fi
  # 只同步有 index.js 的目录（真实云函数）
  if [ -f "$func_dir/index.js" ]; then
    cp "$SHARED_SRC" "$func_dir/cloudbase-common.js"
    count=$((count + 1))
  fi
done

echo "✅ 已同步 cloudbase-common.js 到 $count 个云函数目录"
