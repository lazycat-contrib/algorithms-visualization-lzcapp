#!/bin/bash
# 懒猫发布构建：把上游 Vue/Vite 站点以 selfhost 模式（base=/）构建到 dist/
#
#   · selfhost 模式 = VITE_BASE_URL=/ ，正是懒猫应用根路径所需的 base
#     （上游的 production 模式是 /algorithms-visualization/，那是 GitHub Pages 子路径）
#   · 预渲染（prerender.mjs）用 Playwright + vite preview 逐页生成静态 HTML，
#     190 个页面（中英各 95）。懒猫的 file:// 后端只做静态文件服务，没有 SPA
#     回退，所以预渲染出的静态页面是必需的，不能只跑 vite build。
set -e

export CI=${CI:-1}   # 跳过 husky 等交互式安装钩子
export PLAYWRIGHT_BROWSERS_PATH=${PLAYWRIGHT_BROWSERS_PATH:-0}

echo "[build] 安装依赖 (pnpm, frozen lockfile)"
pnpm install --frozen-lockfile

echo "[build] 确保 Playwright chromium 可用"
pnpm exec playwright install chromium

echo "[build] 构建 + 预渲染（selfhost, base=/）"
pnpm run build:selfhost

echo "[build] 校验产物"
[ -f dist/index.html ] || { echo "dist/index.html 缺失，构建失败"; exit 1; }
[ -f dist/en/index.html ] || { echo "dist/en/index.html 缺失，预渲染不完整"; exit 1; }
echo "[build] 完成：$(find dist -name 'index.html' | wc -l) 个静态页面"
