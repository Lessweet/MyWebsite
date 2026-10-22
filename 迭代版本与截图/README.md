# 迭代版本与截图

个人站历次改版的存档索引。每个版本记录:时间、git 还原点、视觉特征、首页截图。
截图统一存在 [`screenshots/`](screenshots/) 目录。

> 还原某个版本:`git checkout <tag 或 commit>`,站点根在 `docs/`,本地起静态服务即可预览。

---

## v1 · 早期版(2026-05)

- **还原点:**`a917faa`(三段式 header)→ `2fa5094`(VIBEDESIGN banner)
- **特征:**重构 header 三段式布局,新增 logo + 分类筛选;VIBEDESIGN banner、二级分类与 Icon Studio 模块。没有统一的改版命名,当时用 `v1.2.x` 小版本号。
- **截图:**`screenshots/v1-early.png`(若该版本已跑不起来则缺省)

## v2 · 白色版(2026-07 上旬)

- **还原点:**tag `redesign-v2`(= `b1054be`,2026-07-14)
- **做法:**先写 `index-v2.html` 测试页,成熟后覆盖 `index.html` 上线(`eb3043d`,2026-07-09);commit 多以「设计改版测试版」开头。
- **特征:**米色渐变 banner + 二级筛选条 + 标题上方 tag 胶囊。
- **截图:**`screenshots/v2-white.png`

## v3 · 黑底版(2026-07-16)

- **还原点:**`82ad2a5`(合并 redesign-v3)
- **特征:**黑底、无 banner、无筛选条,合并为唯一 `index.html`,引入草稿机制。`redesign-v2` tag 就是为这次改版前存档打的。
- **截图:**`screenshots/v3-dark.png`

## v3.5 · 全站浅色版 light-redesign(2026-07-22)

- **还原点:**`4835251`(PR #2 合入,内容 commit `36dc616`)
- **特征:**全站回归浅色:CTR 字标、主题切换、icon 规范 token,banner 底色改 `--gray-200`,删除全屏菜单底部标语。现线上版本的底子。
- **截图:**`screenshots/v3.5-light.png`

## pre-v4 · v4 动工前的线上状态(截至 2026-10)

- **还原点:**tag `pre-redesign-v4`(= main `7310ba9`)
- **特征:**浅色版持续迭代后的状态:冷载空白修复、loader 爬行、iOS 26 灰阶并轨、封面系统重构(海报首帧 + 激活播放)、主题切换圆形揭开等。
- **截图:**`screenshots/pre-v4.png`

## v4 ·(进行中,2026-10-22 起)

- **分支:**`redesign-v4`(已从 main `7310ba9` 拉出)
- **动工前存档:**tag `pre-redesign-v4` 已打,截图见 `screenshots/pre-v4.png`。
- 方向待定。

---

### 维护约定

- 每次大改版上线时:在此文档加一节(还原点 + 特征),并截一张当时的首页图放入 `screenshots/`。
- 截图统一桌面宽度约 1440px,等 loading 动画走完再截。
