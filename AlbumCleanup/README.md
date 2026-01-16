# PureShot - 智能相册清理工具

> **让清理成为一种治愈** | iPhone 16 Pro 优化 | iOS 26 Liquid Glass 设计语言

---

## 项目简介

PureShot 是一款极简主义 iOS 原生感的相册清理工具，通过 AI 智能识别相似照片，以"治愈系"的交互体验帮助用户整理相册，让清理变成一种享受。

### 核心特性

- **秒级响应**：利用 TaskGroup 并行处理 Vision 请求，下采样至 224x224 提升特征提取速度
- **智能聚类**：按地理位置、拍摄时间、视觉相似度自动分组
- **AI 智能甄选**：自动选择清晰度最高、构图最好的照片
- **液态玻璃 UI**：iOS 26 Liquid Glass 设计语言，液态透镜材质
- **治愈系动画**：光波扫描、内爆粒子、灵动岛呼吸等流体动画

---

## 技术栈

- **SwiftUI** (iOS 26 最新特性)
- **Photos Framework** (获取与删除权限)
- **Vision Framework** (`VNGenerateImageFeaturePrintRequest` 计算特征向量)
- **Metal Shader** (liquidBend.metal 液态弯曲效果)
- **Swift Concurrency** (async/await, actor, TaskGroup)

---

## 项目文件结构

```
PureShot/
├── PureShotApp.swift                  # App 入口
├── ContentView.swift                  # 根视图
│
├── Models/
│   ├── PhotoGroup.swift               # 相似照片组数据结构
│   ├── PhotoAsset.swift               # 单张照片封装
│   └── QualityScore.swift             # 照片质量评分模型
│
├── Services/
│   ├── PhotoLibraryService.swift      # Photos Framework 交互
│   ├── SimilarityEngine.swift         # Vision 相似度计算引擎
│   ├── QualityEvaluator.swift         # AI 照片质量评估
│   └── ClusteringService.swift        # 时间/地点/相似度聚类
│
├── ViewModels/
│   ├── HomeViewModel.swift            # 主页状态管理
│   └── CleanupViewModel.swift         # 清理交互状态
│
├── Views/
│   ├── Home/
│   │   └── HomeView.swift             # 主页
│   │
│   ├── Cleanup/
│   │   └── CleanupView.swift          # 清理交互主视图 (纵向平铺布局)
│   │
│   ├── Components/
│   │   ├── GlassCard.swift            # iOS 26 原生 Liquid Glass 卡片
│   │   ├── LiquidGlassActionBar.swift # 底部液态玻璃操作栏
│   │   ├── LiquidBendSettings.swift   # 液态弯曲参数调节面板
│   │   ├── DynamicIslandToast.swift   # 灵动岛液态提示条
│   │   └── PhotoThumbnail.swift       # 照片缩略图
│   │
│   └── Preview/
│       └── PureShotPreview.swift      # SwiftUI 预览
│
├── Animations/
│   ├── LightWaveScanEffect.swift      # 光波扫描动画
│   ├── LiquidDissolveEffect.swift     # 液态熔化分解动画
│   ├── FluidMotion.swift              # 液态滚动弯曲效果 (Metal Shader 集成)
│   └── HapticManager.swift            # 触觉反馈管理
│
├── Shaders/
│   ├── LiquidBend.metal               # 液态弯曲 Metal Shader
│   └── GenieLightWave.metal           # 光波效果 Shader
│
├── Utilities/
│   ├── ImageDownsampler.swift         # 图片下采样工具
│   └── Constants.swift                # 常量定义
│
└── Extensions/
    ├── PHAsset+Extensions.swift       # PHAsset 扩展
    ├── Color+Theme.swift              # 主题色扩展
    └── View+Glass.swift               # 液态玻璃 modifier
```

---

## 卡片呈现 (Card Presentation)

> 当前实现：纵向平铺布局，每张照片占屏幕高度 55%

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   【布局参数】 CleanupView.swift                                 │
│                                                                 │
│   horizontalPadding = 20px        // 左右边距各 20px            │
│   photoWidth = screenWidth - 40   // 照片宽度                   │
│   maxPhotoHeight = screenHeight × 0.50  // 最大高度 50%        │
│   pageHeight = screenHeight × 0.55      // 每页高度 55%        │
│                                                                 │
│   ┌─────────────────────────────────────────────┐              │
│   │                                             │              │
│   │  ┌─────────────────────────────────────┐   │              │
│   │  │                                     │   │              │
│   │  │              照片 1                 │   │  ← 居中显示  │
│   │  │           (AI 选中保留)              │   │              │
│   │  │                                     │   │              │
│   │  └─────────────────────────────────────┘   │              │
│   │                                             │              │
│   │  ┌─────────────────────────────────────┐   │              │
│   │  │              照片 2                 │   │  ← 露出顶部  │
│   │  │            (待删除)                 │   │     约 20%   │
│   │  └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘   │              │
│   │                                             │              │
│   └─────────────────────────────────────────────┘              │
│                                                                 │
│   【照片尺寸计算】 PhotoCardView                                 │
│                                                                 │
│   naturalHeight = photoWidth / photo.aspectRatio               │
│   finalHeight = min(naturalHeight, maxPhotoHeight)             │
│   finalWidth = finalHeight × photo.aspectRatio                 │
│                                                                 │
│   支持各种比例：竖图、横图、超长图等比缩小                       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 布局代码实现

```swift
// CleanupView.swift - 照片纵向平铺列表
private func photoFlatList(geometry: GeometryProxy, ...) -> some View {
    let screenHeight = geometry.size.height
    let screenWidth = geometry.size.width
    let horizontalPadding: CGFloat = 20
    let photoWidth = screenWidth - horizontalPadding * 2
    let maxPhotoHeight = screenHeight * 0.50
    let pageHeight = screenHeight * 0.55
    let firstPhotoTopOffset = (screenHeight - pageHeight) / 2

    return ScrollViewReader { proxy in
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.photos) { photo in
                    VStack {
                        Spacer()
                        PhotoCardView(
                            photo: photo,
                            photoWidth: photoWidth,
                            maxPhotoHeight: maxPhotoHeight,
                            isSelected: photo.isSelected || photo.isBestInGroup,
                            ...
                        )
                        .liquidScrollEffect()  // 液态滚动效果
                        Spacer()
                    }
                    .frame(height: pageHeight)
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.top, firstPhotoTopOffset)
        }
    }
}
```

---

## 视觉效果 (Visual Effects)

> iOS 26 原生 Liquid Glass API + Metal Shader 实现

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   【iOS 26 原生 Liquid Glass】                                   │
│                                                                 │
│   所有玻璃效果使用原生 .glassEffect() API:                       │
│                                                                 │
│   // GlassCard.swift - 基础玻璃卡片                             │
│   .glassEffect(                                                 │
│       .regular,                                                 │
│       in: RoundedRectangle(cornerRadius: 24, style: .continuous)│
│   )                                                             │
│                                                                 │
│   // 可交互玻璃效果                                              │
│   .glassEffect(.regular.interactive(), in: Capsule())          │
│                                                                 │
│   // 品牌色玻璃                                                  │
│   .glassEffect(.regular.tint(Color.psAccent), in: ...)         │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   【照片选中状态】 PhotoCardView                                 │
│                                                                 │
│   ┌─────────────────────────────────────┐                      │
│   │ ╭─────╮                         ✓  │  ← 右上角勾选图标     │
│   │ │最佳│                              │     checkmark.circle │
│   │ ╰─────╯                             │                      │
│   │                                     │                      │
│   │              照片内容                │                      │
│   │                                     │                      │
│   │                                     │                      │
│   └─────────────────────────────────────┘                      │
│     ↑ 选中时显示 psAccent 边框 (3px)                            │
│                                                                 │
│   // 选中边框实现                                               │
│   .overlay {                                                    │
│       if isSelected {                                          │
│           RoundedRectangle(cornerRadius: 16, style: .continuous)│
│               .strokeBorder(Color.psAccent, lineWidth: 3)      │
│       }                                                        │
│   }                                                            │
│                                                                 │
│   // 最佳标签 (左上角玻璃胶囊)                                   │
│   Text("最佳")                                                  │
│       .glassEffect(.regular, in: Capsule())                    │
│       .padding(10)                                             │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   【底部操作栏】 LiquidGlassActionBar.swift                      │
│                                                                 │
│   ╭───────────────────────────────────────────╮                │
│   │                                           │                │
│   │  ╭─────────╮              ╭─────────╮    │                │
│   │  │ 保留 2  │              │ 删除 5  │    │                │
│   │  ╰─────────╯              ╰─────────╯    │                │
│   │   (玻璃胶囊)               (红色文字)     │                │
│   │                                           │                │
│   ╰───────────────────────────────────────────╯                │
│                                                                 │
│   Button { ... } label: {                                      │
│       Text("保留 \(keepCount)")                                 │
│   }                                                            │
│   .glassEffect(.regular.interactive(), in: Capsule())          │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   【导航栏】 GlassNavigationBar                                  │
│                                                                 │
│   ╭──╮              标题              ╭──╮                     │
│   │◀│                                │⚙│                      │
│   ╰──╯                                ╰──╯                     │
│   (圆形玻璃按钮)                       (设置按钮)               │
│                                                                 │
│   .glassEffect(.regular.interactive(), in: Circle())           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 交互设计 (Interaction Design)

> 点击/长按切换选择 + 滚动触觉反馈

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   【选择交互】 PhotoCardView                                     │
│                                                                 │
│   点击照片 (onTapGesture):                                      │
│   └─ viewModel.toggleSelection(for: photo)                     │
│   └─ 切换选中状态，更新 ✓ 标记                                  │
│                                                                 │
│   长按照片 (onLongPressGesture):                                │
│   └─ viewModel.toggleSelection(for: photo)                     │
│   └─ HapticManager.shared.mediumTap()  // 中等触觉反馈         │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   【滚动触觉反馈】 CleanupView                                   │
│                                                                 │
│   .onPreferenceChange(ScrollOffsetKey.self) { value in         │
│       let delta = newOffset - scrollOffset                     │
│       scrollVelocity = delta                                   │
│       scrollOffset = newOffset                                 │
│       isScrolling = abs(delta) > 0.5                          │
│                                                                 │
│       // 同步滚动状态到液态弯曲效果                              │
│       LiquidBendParameters.shared.isScrolling = isScrolling    │
│                                                                 │
│       // 快速滚动时触觉反馈                                     │
│       if abs(delta) > 30 {                                     │
│           HapticManager.shared.lightTap()                      │
│       }                                                        │
│   }                                                            │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   【滚动状态检测】 onScrollPhaseChange                           │
│                                                                 │
│   .onScrollPhaseChange { oldPhase, newPhase in                 │
│       switch newPhase {                                        │
│       case .idle:                                              │
│           // 完全停止 → 禁用液态效果                             │
│           LiquidBendParameters.shared.isScrolling = false      │
│       case .interacting, .decelerating, .animating:            │
│           // 正在交互/惯性滚动 → 启用液态效果                    │
│           LiquidBendParameters.shared.isScrolling = true       │
│       }                                                        │
│   }                                                            │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   【触觉反馈类型】 HapticManager.swift                           │
│                                                                 │
│   lightTap()   → UIImpactFeedbackGenerator(.light)             │
│   mediumTap()  → UIImpactFeedbackGenerator(.medium)            │
│   softTap()    → UIImpactFeedbackGenerator(.soft)              │
│   success()    → UINotificationFeedbackGenerator(.success)     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 物理效果 (Physics & Animation)

> Metal Shader 液态弯曲 + 内爆粒子系统 + 灵动岛呼吸光晕

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   【液态滚动弯曲】 FluidMotion.swift + LiquidBend.metal         │
│                                                                 │
│   核心原理：滚动时边缘照片产生梯形收缩变形                       │
│                                                                 │
│   静止时：              滚动时（向上滚出）：                     │
│   ┌─────────────┐            ╭─────────╮                       │
│   │             │           /           \                      │
│   │    照片     │          /             \                     │
│   │             │         │      照片     │                    │
│   │             │         │               │                    │
│   └─────────────┘         └───────────────┘                    │
│   (完美矩形)              (顶部收缩梯形)                         │
│                                                                 │
│   Metal Shader 算法 (LiquidBend.metal):                        │
│                                                                 │
│   1. 非线性压缩 (Quadratic Ease)                               │
│      taper = pow(edgeProgress, 2.0)                            │
│      → 边缘弯曲从平滑过渡到剧烈                                 │
│                                                                 │
│   2. Y轴拉伸 (灵动岛协同)                                       │
│      stretchIntensity = strength * 0.08                        │
│      → 顶部像素向上轻微拉伸                                     │
│                                                                 │
│   3. 动态圆角补偿                                               │
│      cornerPull = cornerFactorX * cornerFactorY * 0.3          │
│      → 角落额外收缩，使边缘更圆润                               │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   【参数配置】 LiquidBendParameters (可调节)                     │
│                                                                 │
│   @Observable class LiquidBendParameters {                     │
│       var isScrolling: Bool = false    // 是否正在滚动          │
│       var intensity: Double = 0.3      // 弯曲强度 (0-2)       │
│       var triggerZone: Double = 0.15   // 触发区域 (屏幕比例)  │
│       var scaleEffect: Double = 0.08   // 边缘缩放效果         │
│       var blurEffect: Double = 4.0     // 边缘模糊效果         │
│       var opacityEffect: Double = 0.25 // 边缘淡出效果         │
│   }                                                            │
│                                                                 │
│   触发条件:                                                     │
│   - frame.minY < threshold → 顶部收缩                          │
│   - frame.maxY > screenHeight - threshold → 底部收缩           │
│   - 屏幕中间安全区域无变形                                      │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   【SwiftUI 集成】 LiquidCurvatureEffect                        │
│                                                                 │
│   .visualEffect { view, proxy in                               │
│       let frame = proxy.frame(in: .global)                     │
│       let params = LiquidBendParameters.shared                 │
│                                                                 │
│       // 只在滚动时计算变形                                     │
│       if params.isScrolling {                                  │
│           // 计算 strength 和 direction                        │
│       }                                                        │
│                                                                 │
│       return view.distortionEffect(                            │
│           ShaderLibrary.liquidBend(                            │
│               .float2(size.width, size.height),                │
│               .float(strength),                                │
│               .float(direction)                                │
│           ),                                                   │
│           maxSampleOffset: CGSize(width: 200, height: 100),    │
│           isEnabled: strength > 0.01                           │
│       )                                                        │
│       .scaleEffect(scale)                                      │
│       .blur(radius: blurAmount)                                │
│       .opacity(opacity)                                        │
│   }                                                            │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   【删除动画 - 内爆 + 粒子汇聚】 CleanupView                      │
│                                                                 │
│   1. 触发内爆 (依次执行，间隔 0.15s)                             │
│      photo.animationState = .dissolving                        │
│      scaleEffect(0) + opacity(0) + blur(20)                    │
│                                                                 │
│   2. 生成粒子 (每张照片 10-15 个)                                │
│      贝塞尔曲线路径飞向灵动岛                                    │
│      controlX = 随机偏移 (-50...50)                            │
│      controlY = min(start.y, target.y) - 100                   │
│                                                                 │
│   3. 粒子动画 (0.6s easeIn)                                     │
│      二次贝塞尔曲线: P = (1-t)²·start + 2(1-t)t·control + t²·target │
│                                                                 │
│   4. 灵动岛呼吸光晕 (粒子汇聚后)                                 │
│      奶油色 (1.0, 0.97, 0.90)                                  │
│      多层光晕: 外层 180×55 blur(35)                            │
│               中层 150×45 blur(25)                             │
│               核心 126×37 blur(15)                             │
│      呼吸动画: scale 1.0 → 1.5 → 1.2 → 1.6 → 2.0 (消散)        │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   【粒子模型】 CleanupParticle                                   │
│                                                                 │
│   struct CleanupParticle: Identifiable {                       │
│       let id: UUID                                             │
│       let startPosition: CGPoint      // 照片中心位置           │
│       let targetPosition: CGPoint     // 灵动岛中心 (x/2, 60)  │
│       let delay: Double               // 延迟启动 (i × 0.025)  │
│       let size: CGFloat               // 随机大小 (4-10)       │
│       let color: Color                // 白色/奶油色           │
│       let controlXOffset: CGFloat     // 曲线控制点偏移        │
│   }                                                            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 视觉效果状态表

| 状态 | 照片形状 | 辅助效果 |
|------|----------|----------|
| 🛑 **静止** | 完美矩形 (16px 圆角) | 无 |
| 🖐️ **拖动中** | 边缘梯形收缩 | 缩放 + 模糊 + 淡出 |
| 🌊 **惯性滚动** | 液态变形持续 | 平滑过渡 |
| 💥 **删除内爆** | scaleEffect(0) | 粒子飞向灵动岛 |
| ✨ **完成** | 保留照片稳定 | 灵动岛呼吸光晕 |

---

## 动画时间轴

### 删除动画时间轴

```
时间 ──────────────────────────────────────────────────────────────→

0ms         150ms       300ms       500ms       800ms      1300ms
 │           │           │           │           │           │
 ▼           ▼           ▼           ▼           ▼           ▼
╭─────╮   ╭─────╮    ╭─────╮    ╭─────╮    ╭─────╮    ╭─────╮
│照片1│──→│照片2│───→│照片3│───→│粒子 │───→│灵动岛│───→│完成 │
│内爆 │   │内爆 │    │内爆 │    │汇聚 │    │呼吸 │    │提示 │
╰─────╯   ╰─────╯    ╰─────╯    ╰─────╯    ╰─────╯    ╰─────╯

间隔0.15s  间隔0.15s   +0.2s生成   0.6s飞行    0.3s扩展   显示Toast
每张内爆   依次执行    粒子        贝塞尔曲线   呼吸收缩   ✓ 已清理

触觉: lightTap ──────────────────────────────────── success 💫
```

---

## 完整交互流程

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   【极简流程】                                                    │
│                                                                 │
│   打开 App → AI 默认选 1 张 → 可多选保留 → 点击确认 → 完成       │
│                                                                 │
│   ┌─────┐    ┌─────┐    ┌─────┐    ┌─────┐    ┌─────┐         │
│   │扫描 │──→ │AI选 │──→ │用户 │──→ │内爆 │──→ │完成 │         │
│   │照片 │    │最佳 │    │调整 │    │删除 │    │提示 │         │
│   └─────┘    └─────┘    └─────┘    └─────┘    └─────┘         │
│    自动       默认1张    点击/长按   粒子汇聚    灵动岛          │
│                         切换选择    灵动岛      呼吸光晕        │
│                                                                 │
│   用户决策点:                                                    │
│   - 点击照片切换选择状态                                         │
│   - 长按照片切换选择 + 触觉反馈                                  │
│   - 点击「保留 N / 删除 M」确认                                  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 配色方案

| 语义名称 | Light Mode | Dark Mode | 用途 |
|---------|------------|-----------|------|
| psBackground | #FAFAFA | #0A0A0A | 页面背景 |
| psSurface | #FFFFFF | #1C1C1E | 卡片/浮层 |
| psTextPrimary | #1A1A1A | #F5F5F5 | 标题/正文 |
| psTextSecondary | #6B6B6B | #8E8E93 | 说明/次要信息 |
| psAccent | #F5E6D3 | #F5E6D3 | 品牌色/选中边框 |
| psDestructive | #FF6B6B | #FF6B6B | 删除按钮 |
| creamColor | (1.0, 0.97, 0.90) | - | 灵动岛光晕 |

---

## 关键交互细节

| 环节 | 时长 | 触觉反馈 | 动画 |
|------|------|----------|------|
| 点击选择 | 即时 | 无 | ✓ 显现/消失 |
| 长按选择 | 即时 | mediumTap | ✓ 显现/消失 |
| 快速滚动 | 持续 | lightTap (delta>30) | 液态弯曲变形 |
| 滚动停止 | 200ms | 无 | 恢复正常矩形 |
| 照片内爆 | 0.5s | lightTap | scale(0) + blur(20) |
| 粒子飞行 | 0.6s | 无 | 贝塞尔曲线 |
| 灵动岛呼吸 | 1.5s | success | 多层光晕扩展 |

---

*PureShot - 让清理成为一种治愈*
