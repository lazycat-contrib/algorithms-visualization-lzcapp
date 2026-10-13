#!/bin/bash
# 懒猫发布构建：自动克隆上游源码 → 以 selfhost 模式（base=/）构建 → 预渲染 → 产出 dist/
#
#   · 不在本仓库里存上游源码：每次构建现拉（可换 UPSTREAM_REF 锁定版本）
#   · selfhost 模式 = VITE_BASE_URL=/ ，正是懒猫应用根路径所需的 base
#     （上游的 production 模式是 /algorithms-visualization/，那是 GitHub Pages 子路径）
#   · 预渲染（prerender.mjs）用 Playwright + vite preview 逐页生成 190 个静态页。
#     懒猫的 file:// 后端只做静态文件服务、没有 SPA 回退，所以预渲染产物是必需的，
#     不能只跑 vite build。
set -e

UPSTREAM_REPO=${UPSTREAM_REPO:-https://github.com/IllegalCreed/algorithms-visualization.git}
UPSTREAM_REF=${UPSTREAM_REF:-main}
WORK_DIR=${WORK_DIR:-.upstream}

echo "[build] 克隆上游 ${UPSTREAM_REPO} @ ${UPSTREAM_REF}"
rm -rf "$WORK_DIR"
git clone --depth=1 --branch "$UPSTREAM_REF" "$UPSTREAM_REPO" "$WORK_DIR"
echo "[build] 上游 commit: $(git -C "$WORK_DIR" rev-parse HEAD)"

cd "$WORK_DIR"

echo "[build] 安装依赖 (pnpm, frozen lockfile)"
pnpm install --frozen-lockfile

echo "[build] 确保 Playwright chromium 可用"
# CI（GitHub runner）上有免密 sudo，可顺带装系统依赖；本地/无 sudo 时只装浏览器
if [ "$(id -u)" = "0" ] || sudo -n true 2>/dev/null; then
  pnpm exec playwright install --with-deps chromium
else
  pnpm exec playwright install chromium
fi

echo "[build] 构建 + 预渲染（selfhost, base=/）"
pnpm run build:selfhost

cd ..
rm -rf dist
cp -R "$WORK_DIR/dist" dist

echo "[build] 校验产物"
[ -f dist/index.html ] || { echo "dist/index.html 缺失，构建失败"; exit 1; }
[ -f dist/en/index.html ] || { echo "dist/en/index.html 缺失，预渲染不完整"; exit 1; }
echo "[build] 完成：$(find dist -name 'index.html' | wc -l) 个静态页面"
