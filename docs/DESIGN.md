# VibeUX Portfolio · Design Spec

个人作品集网站 (`vibeux.space`) 的设计规范,记录布局、组件、动效与响应式行为。

---

## 1. Overview

- **Brand**: VibeUX
- **Tagline (deprecated)**: "Build step by step." (已从 footer 删除)
- **Aesthetic**: Apple-inspired,纯白背景 + 黑灰层级,克制留白
- **Stack**: 静态 HTML / CSS / Vanilla JS,GitHub Pages 部署

---

## 2. Color Tokens

CSS 变量定义于 `:root`:

| Token | Value | Usage |
|---|---|---|
| `--white` | `#ffffff` | 页面背景、按钮 active 文字 |
| `--gray-900` / `--black` | `#1d1d1f` | 主文字、active 按钮背景 |
| `--gray-700` | `#48484a` | 次要文字、按钮默认文字 |
| `--gray-600` | `#636366` | 卡片日期、辅助说明 |
| `--gray-500` | `#8e8e93` | — |
| `--gray-400` | `#aeaeb2` | — |
| `--gray-300` | `#d1d1d6` | 按钮默认描边 |
| `--gray-200` | `#e5e5ea` | 分割线 |
| `--gray-100` | `#f2f2f7` | **卡片默认背景** |
| `--gray-50` | `#f9f9f9` | — |

---

## 3. Typography

```css
--font: -apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Segoe UI', sans-serif;
```

| 元素 | 字号 | 字重 | 颜色 |
|---|---|---|---|
| Body base | 16px | 400 | gray-900 |
| Header link / name | 14px | 600 | gray-900 |
| Card label (标题) | 14px | 600 | gray-900 |
| Card date (副标题) | 12px | 400 | gray-600 |
| Category button | 13px | 500 | gray-700 → gray-900 (active: white) |

`-webkit-font-smoothing: antialiased`,`line-height: 1.5`。

---

## 4. Layout

### 4.1 Header(`position: fixed`,白色实底)

**≥ 801px(三段式)**

```
[Logo + VibeUX]              [All] [Poster] [Motion] [3D] [Interactive]              [✉]
       ←                              center (absolute)                              →
```

- `.header-left` `margin-right: auto` 贴左
- `.header-center` `position: absolute; left: 50%; translateX(-50%)` 视觉居中
- `.header-right` `margin-left: auto` 贴右

**≤ 800px(双行)**

```
Row 1:  [Logo + VibeUX]                                              [✉]
Row 2:           [All] [Poster] [Motion] [3D] [Interactive]           
```

- `flex-wrap: wrap`
- `.header-left` order 1,`.header-right` order 2(同行,`justify-content: space-between`)
- `.header-center` order 3,`width: 100%`,`margin-top: 12px`,内部按钮 `justify-content: center`,`gap: 8px`

**Header placeholder** 防止 fixed header 遮挡内容:

| 视口 | placeholder |
|---|---|
| ≥ 801px | 110px |
| ≤ 800px | 160px |

### 4.2 Masonry Grid

```css
.masonry-grid { display: grid; gap: 40px 16px; }
```

| 视口宽度 | 列数 |
|---|---|
| ≤ 800px | 1 |
| 801–900px | 2 |
| 901–1439px | 3 |
| 1440–1799px | 4 |
| 1800–2199px | 5 |
| ≥ 2200px | 6 |

`work-section` padding `0 32px 80px`(narrow: `0 32px 60px`)。

---

## 5. Components

### 5.1 Logo

- 200×200 SVG,16 个层叠对角线"挥笔"路径,黑色实色填充
- 渲染尺寸 40×40px(`.logo-icon`)
- **动效**:`shimmer` wave — 每条 path 透明度 `1 ↔ 0.18` 脉动,0.06s 间隔启动,2.6s 周期,缓动 `cubic-bezier(0.4, 0, 0.2, 1)`
- 动画 CSS 内嵌于 SVG 文件,经 `<img>` 加载也能播放

### 5.2 Category Button(`.category-btn`)

```css
border-radius: 999px;
padding: 6px 14px;
font-size: 13px;
font-weight: 500;
border: 1px solid var(--gray-300);
gap: 8px;
```

| 状态 | 背景 | 文字 | 描边 |
|---|---|---|---|
| Default | transparent | gray-700 | gray-300 |
| Hover | gray-100 | gray-900 | gray-400 |
| Active | gray-900 | white | gray-900 |

### 5.3 Card(`.card`)

```css
aspect-ratio: 1 / 1;
background: var(--gray-100);
border-radius: 28px;
overflow: hidden;
position: relative;
```

`.card-wrapper` 上下结构:展示区(article) → 20px gap → 信息区(`.card-info`) → 2px gap →(标题 + 日期,均居中)

### 5.4 Card 变体

| 类 | 行为 |
|---|---|
| `.card-video-full` | 视频铺满整张卡(`object-fit: cover`) |
| `.card-video-contained` | 视频高 100% / 宽 auto / `aspect-ratio: 834/980` / `object-fit: cover` / `object-position: center bottom` — 顶部裁掉 ~12% 隐藏水印,左右留白,卡片背景设为 `transparent` |
| `.card-full-demo` | iframe 全填,1:1 |
| `.card-dynamic-scale` | iframe 按 JS 算的 `--content-scale` 缩放(如 iPhone 模拟器、375×812 的 web demo) |
| `.card-tall card-video-full` | 老的 iPhone 框装载视频(部分项目还在用) |

---

## 6. Animations

### 6.1 Card Entrance

`IntersectionObserver` 监听 `.card-wrapper` 进入视口(threshold 0.1, rootMargin `-50px`),按 `data-delay`(0–600ms)逐个加 `.visible` class:

```css
.card-wrapper {
    opacity: 0;
    transform: translateY(30px);
    transition: opacity 0.5s var(--ease), transform 0.5s var(--ease);
}
.card-wrapper.visible { opacity: 1; transform: translateY(0); }

--ease: cubic-bezier(0.25, 0.46, 0.45, 0.94);
```

### 6.2 Logo Shimmer

详见 5.1。

---

## 7. Filter Logic

每张 `.card-wrapper` 带 `data-category="<key>"`,header 按钮带 `data-filter="<key>"`。

JS 行为(`script.js`):
1. 点击按钮 → `.active` 互斥切换
2. 不匹配的卡片设为 `display: none`
3. `data-filter="all"` 显示全部

### Categories

| Key | Label | 包含项目 |
|---|---|---|
| `poster` | Poster | Dynamic Poster ×4(立体未来感系列) |
| `motion` | Motion | AI Assistant Motion(lottie 动效卡片) |
| `3d` | 3D | 3D Rotation / 3D Card Glass / 3D Sphere / Glass Balls / Gesture Interaction / Gyroscope(SwiftUI / Metal iOS demos) |
| `interactive` | Interactive | Eye Tracking / Voice Particles(网页交互 demos) |

---

## 8. Asset Conventions

- `style.css?v=N` / `script.js?v=N` / `logo.svg?v=N` / `favicon.png?v=N` — 每次改动 bump 版本号绕过浏览器缓存
- 视频:用 ffmpeg 压成 `*_compressed.mp4`,libx264 / crf 23 / `+faststart`
- Lottie 动画:5MB+ 的 `animation.json` 包成 `animation.js`(`window.aiAssistantAnimationData = {...}`),通过 `<script>` 加载,绕开 Chrome `file://` 协议下 `fetch()` 的限制

---

## 9. File Structure

```
docs/
├── index.html              # 主页面
├── style.css               # 样式(单文件)
├── script.js               # 入场动画 + 分类过滤
├── logo.svg                # 带内嵌动画的 SVG
├── favicon.png
├── DESIGN.md               # 本文档
├── ai-assistant-motion/    # 卡片 2 的 lottie demo
│   ├── index.html
│   ├── animation.js
│   └── ButtonBasic.png
├── 动态海报/立体未来感/    # 卡片 1, 3, 4, 5 的视频
│   ├── 1.mp4 ... 4.mp4
├── multi-scene-character-demo/  # Eye Tracking iframe
├── voice-particles/        # Voice Particles iframe
└── *_compressed.mp4        # 各 3D 项目录屏
```

---

## 10. Open Conventions / TODO

- 卡片标签(`card-tag`)CSS 仍存在但已无 HTML 实例 — 视觉上已删除 tag 行
- `card-like` 点赞按钮 `display: none` — 完全隐藏,如复用需重写交互
- `--ease` 仅用于卡片入场;动画相关曲线建议统一引用此变量
- footer 已整体删除,如恢复需重新添加 HTML + CSS
