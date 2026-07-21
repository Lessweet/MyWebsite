# VibeUX · 个人网站

[vibeux.space](https://vibeux.space/) 的源码仓库，由 GitHub Pages 从 `main` 分支的 `docs/` 目录发布。

**2026-07 起主站已迁移为 React（Vite 多入口 MPA）**：15 个页面（首页 / Blog / Archive / 12 篇文章）的源码在 `site/`，`npm run build` 构建到 `docs/`（构建产物需提交，Pages 无 CI）。demo 页、动画封面、CSS（`style.css` / `writing.css`）与 `nav-boot.js` 仍是 `docs/` 里的静态文件，不经打包器。

## 开发

```bash
npm install        # 首次
npm run dev        # 本地开发(热更新),浏览器打开 http://localhost:5173
npm run build      # 构建到 docs/(发布前必跑)
npm run preview    # 预览构建产物(等同线上)
```

注意:迁移后 `docs/` 里的 15 个入口页引用打包产物,**不能再用 file:// 双击预览**,请用 `npm run dev`。

## 目录

- `site/` — React 源码(入口 HTML、组件、文章注册表与正文片段)
- `site/scripts/extract-articles.mjs` — 文章提取/入口生成器(迁移工具,新文章也可复用)
- `docs/` — 网站本体 = 构建产物 + 静态资产（demo、文章素材、封面与视频）
- `docs/nav-boot.js` — 首帧前原生 boot 层(导航注入/主题,自 writing.js 抽出)
- `docs/DESIGN.md` · `docs/DESIGN-SPEC.md` — 网站设计规范
- `PUBLISHING.md` — 发布流程
- `CNAME` — 自定义域名

## 分支

| 分支 | 内容 |
|---|---|
| `main` | 网站内容（当前分支，Pages 发布源） |
| `design-refresh` | 网站改版进行中 |
| `ios-demos` | iOS 原生 Demo 工程（SwiftUI / SceneKit） |
| `html-demos` | 网页 / Web Demo 与工具项目 |
