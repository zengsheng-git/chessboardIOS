#!/usr/bin/env bash
# 把安卓仓库的共享资产（识别模型 middle.onnx / NNUE pikafish.nnue）拷贝到本仓库 Assets/，
# 供 M4/M5 的 Xcode target 引用。单一大文件只在安卓仓库存一份，CI 构建时现场拷贝。
#
# CI 上先二次检出安卓仓库（见 .github/workflows/ios-build.yml 顶部注释），
# 本地开发时保持两个仓库为同级目录即可：
#   C:\w\chessboardAndroid    （安卓版，资产来源）
#   C:\w\chessboardIOS        （本仓库）
# 用法：bash scripts/fetch-assets.sh   （可用环境变量 ANDROID_ASSETS 覆盖来源目录）
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${ANDROID_ASSETS:-$ROOT/../chessboardAndroid/app/src/main/assets}"
DST="$ROOT/Assets"

for f in middle.onnx pikafish.nnue; do
  if [ ! -f "$SRC/$f" ]; then
    echo "缺少资产: $SRC/$f（先检出安卓仓库，或设 ANDROID_ASSETS 指向其 app/src/main/assets）" >&2
    exit 1
  fi
done

mkdir -p "$DST"
cp -f "$SRC/middle.onnx" "$SRC/pikafish.nnue" "$DST/"
echo "assets staged: $DST ($(ls -lh "$DST" | tail -n +2 | awk '{print $9, $5}' | tr '\n' ' '))"
