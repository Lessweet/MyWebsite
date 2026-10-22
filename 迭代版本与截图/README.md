# 迭代版本与截图

个人站历次改版的存档索引。每个版本记录:时间、git 还原点、视觉特征、首页截图、录屏。
截图在 [`screenshots/`](screenshots/),录屏在 [`recordings/`](recordings/),两边文件名一致。
录屏流程统一:全新会话首次进入 → loading → 首页露出 → 点进两个二级页各浏览一段。

> 还原某个版本:`git checkout <tag 或 commit>`,站点根在 `docs/`,本地起静态服务即可预览。

---

## v1 · 早期版(2026-05)

- **还原点:**`a917faa`(三段式 header)→ `2fa5094`(VIBEDESIGN banner)
- **特征:**重构 header 三段式布局,新增 logo + 分类筛选;VIBEDESIGN banner、二级分类与 Icon Studio 模块。没有统一的改版命名,当时用 `v1.2.x` 小版本号。
- **截图:**`screenshots/v1-early.png`(若该版本已跑不起来则缺省)
- **录屏:**`recordings/v1-early.mp4`

## v2 · 白色版(2026-07 上旬)

- **还原点:**tag `redesign-v2`(= `b1054be`,2026-07-14)
- **做法:**先写 `index-v2.html` 测试页,成熟后覆盖 `index.html` 上线(`eb3043d`,2026-07-09);commit 多以「设计改版测试版」开头。
- **特征:**米色渐变 banner + 二级筛选条 + 标题上方 tag 胶囊。
- **截图:**`screenshots/v2-white.png`
- **录屏:**`recordings/v2-white.mp4`

## v3 · 黑底版(2026-07-16)

- **还原点:**`82ad2a5`(合并 redesign-v3)
- **特征:**黑底、无 banner、无筛选条,合并为唯一 `index.html`,引入草稿机制。`redesign-v2` tag 就是为这次改版前存档打的。
- **截图:**`screenshots/v3-dark.png`
- **录屏:**`recordings/v3-dark.mp4`

## v3.5 · 全站浅色版 light-redesign(2026-07-22)

- **还原点:**`4835251`(PR #2 合入,内容 commit `36dc616`)
- **特征:**全站回归浅色:CTR 字标、主题切换、icon 规范 token,banner 底色改 `--gray-200`,删除全屏菜单底部标语。现线上版本的底子。
- **截图:**`screenshots/v3.5-light.png`
- **录屏:**`recordings/v3.5-light.mp4`

## pre-v4 · 去色修复版,v4 动工前的线上状态(2026-10-23)

- **还原点:**tag `pre-redesign-v4`(= main `5fb9832`,合并 PR #41)
- **特征:**浅色版持续迭代后的完整形态(loading 黑幕揭幕、首页→Blog/Archive 模态展开、动态封面、主题切换圆形揭开),
  加上 10-23 这轮加载优化与修复:进度条改为合成器驱动的连续曲线;首屏去掉 NetEase 红环、UI 设计师下划线改灰(去色);
  NetEase / UI 设计师 hover 微交互;Astra 封面修复;feed 上滑不再重播入场。
- **截图:**`screenshots/pre-v4.png`
- **录屏:**`recordings/pre-v4.mp4`

## v4 · 简化版(规划中,2026-10-23 起)

- **目标:**更清爽、更快 —— 大幅精简样式与动效,Blog 不再有详情页。
- **素材:**全部保留在仓库(`docs/writing/assets` 等原地不动),简化版只是不再引用;完整版随时可从 `pre-redesign-v4` 还原。
- **分支:**另开新分支(`redesign-v4` 已用于 PR #41 的修复)。

---

### 维护约定

- 每次大改版上线时:在此文档加一节(还原点 + 特征),截图放入 `screenshots/`、录屏放入 `recordings/`。
- 截图与录屏统一桌面视口 1440×900;录屏用全新会话(保证 loading 会播),转 H.264 mp4。
