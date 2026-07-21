#!/bin/bash
# 双击启动本地预览:起 Vite 开发服务器并自动打开浏览器(热更新,改代码即时生效)。
# 关闭这个终端窗口 = 停止预览服务器。
cd "$(dirname "$0")"
if [ ! -d node_modules ]; then
  echo "首次使用,正在安装依赖(仅需一次)..."
  npm install
fi
npm run dev -- --open
