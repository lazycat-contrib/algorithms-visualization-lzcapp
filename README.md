# algorithms-visualization-lzcapp

[数据结构和算法可视化](https://github.com/IllegalCreed/algorithms-visualization) 的懒猫微服打包：**只发喵喵商店**。

- **形态**：纯静态站点，**没有容器镜像**（`contentdir: ./dist` + `upstreams.backend: file:///lzcapp/pkg/content/`）。
- **不存上游源码**：`build.sh` 每次构建现克隆上游（`UPSTREAM_REPO` / `UPSTREAM_REF` 可覆盖，默认 `main`），构建完只保留 `dist/`。
- **构建方式**：`pnpm run build:selfhost`。
  - `selfhost` 模式 = `VITE_BASE_URL=/`，正是懒猫应用根路径需要的 base；上游的 `production` 模式是 `/algorithms-visualization/`（GitHub Pages 子路径），不能用。
  - 预渲染（`prerender.mjs`，Playwright + `vite preview`）逐页生成 **190 个静态页面**（中英各 95）。懒猫的 `file://` 后端是静态文件服务、**没有 SPA 回退**，所以必须用预渲染产物，只跑 `vite build` 不够。
  - 构建后上游自带两道门禁：`verify-seo.mjs`（190 页 SEO/canonical 校验）与 `verify-bundle.mjs`（体积预算），任一不过就失败。
- **版本来源**：`version_source.type: git`（上游无 tag/release，版本由本仓库 `package.yml` 与 tag 决定）。
- **图标**：上游 `public/favicon.svg` 渲染成 512×512。
- **路由**：`/` → `file:///lzcapp/pkg/content/`，`public_path: [/]`。

## 上游的外部依赖（原样保留）

- **Google AdSense**：`vite.config.ts` 的 `adsenseHeadPlugin` 会在构建产物 `<head>` 注入 AdSense 加载脚本（作者变现用）。预渲染有断言要求它恰好出现一次。
- **Google Analytics (GA4)**：仅在用户点「允许」后加载（页面上有隐私同意面板，默认不加载）。
- **canonical / sitemap 指向作者自有域名** `https://algo.illegalscreed.cn`（SEO 元数据，不影响功能）。

以上都未改动。若要去掉广告/统计或改 canonical 为懒猫域名，需要在上游构建前做补丁，请先确认。

## 商店状态

- **喵喵商店**：`cloud.lazycat.app.algorithmsvisualization` 由 Action 发布（`stores.private`）。
- **官方商店**：未启用。
