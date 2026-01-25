#!/bin/bash
# 从 icon-zhuanlema.svg 导出 AppIcon 所需的三个 PNG（在项目根目录执行: ./scripts/export-app-icon.sh）
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ASSETS="$PROJECT_ROOT/Zhuanlema/Assets.xcassets/AppIcon.appiconset"
SVG="$ASSETS/icon-zhuanlema.svg"

if [ ! -f "$SVG" ]; then
  echo "Error: $SVG not found."
  exit 1
fi

cd "$ASSETS"

# macOS qlmanage 按尺寸导出 SVG → PNG（输出名为 输入名.svg.png）
qlmanage -t -s 1024 -o . "$SVG" 2>/dev/null
[ -f "icon-zhuanlema.svg.png" ] && mv "icon-zhuanlema.svg.png" "AppIcon-1024.png"

qlmanage -t -s 180 -o . "$SVG" 2>/dev/null
[ -f "icon-zhuanlema.svg.png" ] && mv "icon-zhuanlema.svg.png" "AppIcon-180.png"

qlmanage -t -s 120 -o . "$SVG" 2>/dev/null
[ -f "icon-zhuanlema.svg.png" ] && mv "icon-zhuanlema.svg.png" "AppIcon-120.png"

echo "Exported to $ASSETS"
ls -la AppIcon-*.png 2>/dev/null || echo "If no PNGs: open the SVG in Safari or Preview and export as PNG, then resize to 1024/180/120."
