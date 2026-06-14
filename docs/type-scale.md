# 全站字号规则(Type Scale)

> 单一事实来源:`docs/style.css` 的 `:root`。改字号只动那一处,所有 `var(--fs-*)` 引用一起变。
> `--fs` = font-size。桌面 / 手机**统一**,不做断点适配。

## 5 级 scale

| Token | 字号 | 对应实现 | 用在哪 |
|---|---|---|---|
| `--fs-h1` | 52px | `<h1>` 大标题 | 文章标题 `.article-h1`(**特例:桌面 ≥769px 单独放大到 68px**,移动端 52) |
| `--fs-h2` | 32px | `<h2>` 小标题 | 文章章节 `.article-body h2`、Design/Writing 页模块标题 `.section-divider h2` |
| `--fs-h3` | 22px | 卡片标题(h3 级) | 首页卡片 `.w-title`、design 卡片 `.card-label`、文章列表标题 `.a-title`、文章内 `.article-body h3` |
| `--fs-p` | 18px | `<p>` 正文 | 文章正文 / highlight、二级 tab `.design-menu .nav-cat`、桌面顶栏导航(≥801)、页脚 `.pn-title`/`.ft-title`、菜单底部 `.nav-modal-desc` |
| `--fs-caption` | 14px | 小字(无单一标签) | 简介 `.w-excerpt/.a-excerpt`、日期 `.w-date/.card-date/.a-date`、tag `.a-tag`、图注 `.img-caption`、byline、`.same-collection`、`.ft-desc`、`.back-link` |

用法:`font-size: var(--fs-p);`

## 不在 scale 内的(刻意排除)

| 元素 | 现状 | 原因 |
|---|---|---|
| 顶栏导航 Blog / Cases / Contact | **桌面 ≥801 = `--fs-h3`(22)**;移动端仍 `clamp(13→28px)` | 桌面收进 scale,移动端保留响应式 |
| 移动端全屏菜单导航项 | Contact 72px、其余 `clamp(17,5vw,22)` | 菜单专用超大展示型排版 |
| 页脚 / 合集的 mono 微标签(`.pn-label`/`.sc-title`) | 11px 等宽 overline | overline/eyebrow,scale 无此级,刻意小 |
| VIBEUX 字标 / pixel banner / 图标 / `0.88em` 等 | 各自固定/响应/相对尺寸 | 装饰性,不属正文体系 |
| `docs/index.html`(旧 Andrei Rybin 作品集页) | 一堆 14/12/20px 字面值 | 疑似死代码(首页已换 index-v2),未纳入,待确认清理 |

## 维护要点

- **网站 CSS**(`writing.css` 等)一律用 `var(--fs-*)`。
- **文章正文是 inline 样式**,且要兼容微信公众号(不能用 `var`):按字面值 **18 / 32 / 14** 与 token 对齐。
  来源在 article-template skill:`render.py`(网站生成)+ `template.html`(公众号)+ `SKILL.md`(规范表)。
- 改了规范后,**已发布的老文章不会自动更新**,需重新跑同步或手动改对应 `writing/article-{slug}.html`。

## 字重 / 行高(配套)

| 角色 | 字重 | 行高 |
|---|---|---|
| H1 | 400 | 1.2 |
| H2 | 500 | 1.2 |
| 正文 / highlight | 300 | 1.4 |
| `<strong>` | 400(不加粗) | — |
