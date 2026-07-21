# VibeUX 设计规范

全站统一的设计语言。所有颜色、间距、圆角、分割线、图标都以这里为准，新页面 / 新模块直接复用 token，不要再写散落的硬编码值。

token 定义在 `style.css` 的 `:root`，跨页面共用；`writing.css` 只在此基础上扩展列表页 / 阅读页 / Design 页布局。

---

## 设计原则

- **纯白底 + 黑灰层次**：背景永远是白，信息层级靠灰阶拉开，不靠色块。
- **细线分隔，不用重边框**：模块之间用一条 `--hairline` 细线，而不是粗边框或卡片阴影堆叠。
- **描边图标**：统一 outline 风格，细线、圆角端点，和正文一样安静。
- **克制的动效**：只用一条缓动曲线，进场是轻微上浮，不抢内容。

---

## 颜色

灰阶是主力，黑灰之间 9 档，够用且统一。

| Token | 值 | 用途 |
| --- | --- | --- |
| `--white` | `#ffffff` | 页面背景、卡片、导航底 |
| `--gray-900` | `#1d1d1f` | 主文字、标题、激活态 |
| `--gray-700` | `#48484a` | 次级正文 |
| `--gray-600` | `#636366` | 描述、摘要文字 |
| `--gray-500` | `#8e8e93` | 占位、未激活菜单 |
| `--gray-400` | `#aeaeb2` | 弱提示、eyebrow |
| `--gray-300` | `#d1d1d6` | 按钮 / 标签描边 |
| `--gray-200` | `#e5e5ea` | 列表行内分隔 |
| `--gray-100` | `#f2f2f7` | 浅填充、标签底 |
| `--gray-50` | `#f9f9f9` | 最浅填充(合集卡底) |
| `--hairline` | `#f0f0f0` | **全站统一细分割线**(见下) |

**特殊表面**

- Icon Library(Outlined / Pixel 封面 + 模态 + 二级页)统一暖纸白 `#FDFBF6`。

---

## 细分割线 hairline（统一规范）

全站只用一种分隔线：**`1px solid var(--hairline)`（`#f0f0f0`）**。它就是顶部导航栏底部那条线，所有模块分隔都向它看齐。

已统一的位置：

- 顶部导航栏底部 —— `.home-v2 .header.home-nav { border-bottom: 1px solid var(--hairline); }`
- Design 页右侧每个模块顶部 —— `.design-page .design-content .category-section .section-divider { border-top: 1px solid var(--hairline); }`
- 移动端 Design 横向菜单底部 —— 同 token。

规则：

- 结构性分隔（导航、模块、区块）一律用 `--hairline`。
- 列表内部行与行之间（如文章清单 `.article-item`）可继续用更深一点的 `--gray-200`，因为那是「同一模块内的条目分隔」，层级不同。
- 不要再出现 `#f0f0f0`、`#eee` 这类硬编码，统一走 `var(--hairline)`。

---

## 字体与字号

```
正文  --font: -apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Segoe UI', sans-serif
等宽  "SF Mono", Menlo, Monaco, Consolas, monospace   （日期、eyebrow、标签编号）
```

字号阶梯（实际在用的值）：

| 层级 | 字号 | 字重 |
| --- | --- | --- |
| 阅读页大标题 `article-h1` | 34px | 680 |
| 首页区块标题 `section-divider h2` | 32px | 650 |
| 列表页标题 `writing-intro h1` | 30px | 680 |
| 阅读页正文小标题 | 24px | — |
| Design 模块小标题 | 21px | 650 |
| 文章条目标题 `a-title` | 19px | 600 |
| 正文 | 14–17px | 400–500 |
| 元信息 / 日期(等宽) | 11–13px | — |

行高正文 `1.5`，标题 `1.2–1.35`。英文 / 数字前后留一个空格。

---

## 间距与布局

内容宽度（居中容器）：

| 场景 | 宽度 |
| --- | --- |
| Design 页 / 首页内容 | `min(1280px, 100% - 48px)` |
| 阅读页(目录 + 正文) | `1040px` |
| 列表页 | `min(760px, 100% - 40px)` |
| 阅读正文栏 | `700px` |

断点（max-width，从大到小）：

- `1023px` —— 阅读页隐藏侧边目录，单栏
- `900px` —— Design 页布局收成单栏
- `860px` —— 卡片网格 3 列 → 2 列
- `800px` —— 顶栏重排(logo 居中 + 导航换行)
- `620px` —— 移动端：网格保持 2 列、间距收紧

---

## 圆角

| 值 | 用途 |
| --- | --- |
| `8px` | 小元素、foundation 小卡 |
| `10px` | 文章缩略图 |
| `12px` | **主卡片 / 作品卡 / banner**(最常用) |
| `14px` | 文章封面 |
| `16px` | 模态框、合集卡、大容器 |
| `999px` | 胶囊按钮 / 标签 |
| `50%` | 圆形按钮(关闭、点赞、箭头) |

新卡片默认 `12px`，没有特殊理由不要新增其它值。

---

## 图标

全站图标统一一套 SVG 描边规范：

```html
<svg viewBox="0 0 24 24" fill="none" stroke="currentColor"
     stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">
  <!-- path... -->
</svg>
```

- `viewBox` 恒为 `0 0 24 24`，`fill="none"`，`stroke="currentColor"`（跟随文字色）。
- 线宽 `1.6`，端点 / 拐角都 `round`。
- 渲染尺寸：顶部导航 / Design 一级菜单 `18px`，二级菜单 `16px`，模块标题 `22px`。

各入口图标语义：

| 入口 | 图标 |
| --- | --- |
| Writing | 铅笔 |
| Design（顶部导航） | 钢笔尖 + 闪光（= AI Design） |
| AI-Native Design | 四角闪光星 |
| AIGC | 魔法棒 + 闪光 |
| Visual Motion | 运动物体 + 速度线 |
| Visual UX | 立方体 / 体块 |

点赞心形是唯一例外（实心、线宽 2），属于交互态标记。

---

## 卡片网格

`.category-grid` 是作品 / 文章列表的统一容器：

- 默认 3 列，列间距 **流体**：`gap: 40px clamp(12px, 2.5vw, 24px)`（行距固定 40px，列距随视口连续收缩，最宽 24px、最窄 12px）。
- `≤860px`：2 列。
- `≤620px`：保持 2 列，行距收到 28px（列距继续走上面的 clamp）。
- 满宽变体 `.icon-showcase-grid` 永远单列（整块 iframe 展示），靠更高优先级不受上面影响。

---

## 组件

**顶部导航 `header`**：`position: fixed`，白底，内容左右边缘对齐 1280 容器，底部一条 `--hairline`。滚动用 `transform` + `box-shadow` 过渡。

**作品卡 `card`**：圆角 12px；视频 / iframe 内层按分类决定是否同步圆角（Motion Posters 内层方角，VisualUX 内层 12px）。hover 轻微上浮 / 阴影。

**模态框 `icon-modal`**（点封面在当前页打开图标库）：
- 遮罩 `rgba(0,0,0,0.45)` + `blur(2px)`。
- 对话框 `min(1120px, 94vw) × 94vh`，底色 `#FDFBF6`，圆角 16px，阴影 `0 24px 70px rgba(0,0,0,0.28)`。
- 关闭：✕ 按钮 / 点遮罩 / `Esc`；打开时 `body` 锁滚动。
- 模态内的图标库页隐藏滚动条（保留滚动）、隐藏返回链接。

**胶囊标签 / 按钮**：圆角 999px，`--gray-300` 描边，激活态填 `--gray-900` 白字。

---

## 动效

- 缓动统一：`--ease: cubic-bezier(0.25, 0.46, 0.45, 0.94)`。
- **封面 hover 放大（全站唯一规则）**：放大到 `--hover-zoom: 1.08`；移入 `--hover-zoom-in: 0.77s`，移出 `--hover-zoom-out: 1.54s`（收回是放大的 2 倍慢），缓动都用 `--ease-soft: cubic-bezier(0.22, 1, 0.36, 1)`。首页 / Blog（`.writing-card`）与 Cases（`.card`）共用这一组，token 定义在 `style.css :root`。以后任何 hover 放大交互一律引用这三个变量，禁止另写数值。
- 进场：`.reveal-up`（上浮 24px + 渐显，0.5s）；标题用 `heading-rise-in`。
- 尊重 `prefers-reduced-motion`：关闭位移与过渡。
- Icon Library 内动效另有独立规范（Outlined 用平滑 CSS keyframes，Pixel 用 `step-end` 帧跳）。

---

_本规范从现有 `style.css` / `writing.css` 提炼。新增样式优先复用 token；确需新值时，先在此登记再使用。_
