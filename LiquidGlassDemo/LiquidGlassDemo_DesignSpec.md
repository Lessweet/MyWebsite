# Liquid Glass Demo - 完整设计与开发规范

> 版本: 2.0
> 日期: 2025-01-21
> 用途: 100% 复刻卡片展开动效 Demo
> 使用 SwiftUI 编程语言和现代化方法
> 利用 iOS 26 Liquid Glass 的美观界面

## iOS 26 Liquid Glass API 使用

### 核心 API

| API | 用途 | 示例 |
|-----|------|------|
| `.glassEffect(.clear.interactive())` | 透明交互式玻璃按钮 | 搜索按钮、关闭按钮 |
| `.glassEffect(.regular, in: .rect(cornerRadius: 0))` | 背景模糊遮罩 | 模态背景 |
| `.scrollEdgeEffectStyle(.soft, for: .top)` | 滚动边缘柔和效果 | ScrollView 顶部淡出 |
| `.preferredColorScheme(.dark)` | 强制深色模式 | 全局 UI 适配 |

### 代码示例

```swift
// 1. 透明交互式玻璃按钮（搜索、关闭按钮）
Button {
    // action
} label: {
    Image(systemName: "magnifyingglass")
        .font(.system(size: 18, weight: .medium))
        .foregroundStyle(.white)
        .frame(width: 44, height: 44)
}
.glassEffect(.clear.interactive())

// 2. 背景模糊遮罩（展开时的背景）
Color.clear
    .glassEffect(.regular, in: .rect(cornerRadius: 0))
    .opacity(Double(animProgress))
    .ignoresSafeArea()

// 3. 滚动边缘柔和效果
ScrollView {
    // content
}
.scrollEdgeEffectStyle(.soft, for: .top)

// 4. 强制深色模式
.preferredColorScheme(.dark)
```

---

## 一、项目概述

这是一个 iOS SwiftUI 卡片展开动效 Demo，实现了：
- 8 张小卡片网格展示（使用 Unsplash 图片填充）
- 顶部导航栏（Gallery 标题 44pt + 搜索按钮）
- Gallery 标题水平压缩 0.8 倍，左间距 20pt
- 导航栏滚动时淡入淡出（上滑淡出，下滑淡入）
- 顶部渐变遮罩 100pt，底部渐变遮罩 80pt
- 隐藏滚动指示器，列间距 16pt，行间距 20pt
- 点击小卡片展开为模态页（同一张卡片 3D 变形）
- Metal Shader 液态扭曲动画效果
- 展开后陆续出现 4 张同主题卡片（仅第一张显示标题）
- 图片加载采用淡入动画效果
- 支持横屏/竖屏自适应布局
- iOS 26 Liquid Glass 风格
- 全英文界面

### 使用的原生效果

| 效果 | API | 用途 |
|------|-----|------|
| Liquid Glass 玻璃效果 | `.glassEffect(.clear.interactive())` | 搜索按钮、关闭按钮 |
| Liquid Glass 背景模糊 | `.glassEffect(.regular, in: .rect(cornerRadius: 0))` | 展开时的模态背景 |
| 深色模式 | `.preferredColorScheme(.dark)` | 全局 UI 强制深色 |
| 3D 旋转效果 | `.rotation3DEffect()` | 卡片展开时的透视扭曲 |
| 弹簧动画 | `.spring(response:dampingFraction:)` | 展开/收起的弹性动画 |
| Metal Shader | `distortionEffect()` | 液态曲面扭曲效果 |
| 异步图片加载 | `AsyncImage(transaction:)` | 图片淡入动画 |
| 线性渐变 | `LinearGradient` | 顶部/底部边缘遮罩 |
| 几何读取器 | `GeometryReader` | 获取屏幕尺寸、卡片位置 |
| 偏好键 | `PreferenceKey` | 追踪滚动偏移量 |
| 坐标空间 | `.coordinateSpace(name:)` | 滚动视图坐标系 |

---

## 二、布局规范

### 2.1 小卡片网格（首页）

| 属性 | 竖屏 | 横屏 |
|------|------|------|
| 列数 | 2 列 | 4 列 |
| 列间距 | 12pt | 12pt |
| 行间距 | 16pt | 16pt |
| 左右边距 | 20pt | 20pt |
| 顶部边距 | 76pt | 76pt |

```swift
let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: isLandscape ? 4 : 2)

ScrollView {
    LazyVGrid(columns: columns, spacing: 16) { ... }
        .padding(.horizontal, 20)
        .padding(.top, 76)  // 为导航栏和渐变遮罩留出空间
}
.scrollEdgeEffectStyle(.soft, for: .top)
```

### 2.2 展开后卡片网格（模态页）

| 属性 | 竖屏 | 横屏 |
|------|------|------|
| 列数 | 1 列 | 4 列 |
| 列间距 | 12pt | 12pt |
| 行间距 | 12pt | 12pt |
| 左右边距 | 20pt | 20pt |
| 顶部边距 | 76pt | 76pt |

```swift
let columns = isLandscape
    ? Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)
    : [GridItem(.flexible())]

ScrollView {
    LazyVGrid(columns: columns, spacing: 12) { ... }
        .padding(.horizontal, 20)
        .padding(.top, 76)
}
```

### 2.3 卡片比例

所有卡片统一使用 **3:4 宽高比**：

```swift
.aspectRatio(3.0/4.0, contentMode: .fit)
```

### 2.4 背景色

```swift
// 纯黑色背景
Color.black
    .ignoresSafeArea()

// 强制深色模式，UI 自动适配
.preferredColorScheme(.dark)
```

---

## 三、顶部导航栏

### 3.1 布局结构

```swift
// 顶部标题栏 - 浮动在内容上方
VStack {
    HStack {
        Text("Gallery")
            .font(.largeTitle.bold())
            .foregroundStyle(.primary)

        Spacer()

        Button {
            // 搜索操作
        } label: {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
        }
        .glassEffect(.clear.interactive())
    }
    .padding(.horizontal, 16)
    .padding(.top, 8)
    .padding(.bottom, 12)
    .opacity(navBarOpacity)  // 根据滚动淡入淡出

    Spacer()
}
```

### 3.2 滚动淡入淡出

```swift
@State private var scrollOffset: CGFloat = 0

// 导航栏透明度计算
private var navBarOpacity: Double {
    let fadeDistance: CGFloat = 40  // 完全淡出需要的滚动距离
    // scrollOffset 初始为 0，上滑时变成负值
    if scrollOffset >= 0 {
        return 1.0  // 未滚动或下滑，完全显示
    } else if scrollOffset <= -fadeDistance {
        return 0.0  // 完全淡出
    } else {
        return 1.0 + Double(scrollOffset / fadeDistance)
    }
}
```

### 3.3 滚动偏移追踪

```swift
// PreferenceKey 定义
struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// ScrollView 中追踪偏移
ScrollView {
    LazyVGrid(columns: columns, spacing: 16) { ... }
        .background(
            GeometryReader { geo in
                Color.clear
                    .preference(key: ScrollOffsetKey.self, value: geo.frame(in: .named("scroll")).minY)
            }
        )
}
.coordinateSpace(name: "scroll")
.onPreferenceChange(ScrollOffsetKey.self) { value in
    scrollOffset = value
}
```

---

## 四、顶部渐变遮罩

实现 iOS 26 风格的柔和边缘淡出效果：

```swift
// 顶部渐变遮罩 - 实现柔和的边缘淡出效果
VStack {
    LinearGradient(
        colors: [
            Color.black,
            Color.black.opacity(0.8),
            Color.black.opacity(0.4),
            Color.black.opacity(0)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    .frame(height: 100)
    .allowsHitTesting(false)  // 不阻挡点击

    Spacer()
}
.ignoresSafeArea()
```

### 顶部渐变遮罩

| 属性 | 值 |
|------|-----|
| 高度 | 100pt |
| 渐变 | 黑色 → 80% → 40% → 透明 |
| 交互 | `.allowsHitTesting(false)` |

### 底部渐变遮罩

| 属性 | 值 |
|------|-----|
| 高度 | 80pt |
| 渐变 | 透明 → 20% → 40% → 60% |
| 交互 | `.allowsHitTesting(false)` |

```swift
// 底部渐变遮罩
LinearGradient(
    colors: [
        Color.black.opacity(0),
        Color.black.opacity(0.2),
        Color.black.opacity(0.4),
        Color.black.opacity(0.6)
    ],
    startPoint: .top,
    endPoint: .bottom
)
.frame(height: 80)
.allowsHitTesting(false)
```

---

## 五、图片填充规范

### 5.1 Unsplash 图片源

使用 Unsplash 提供的免费图片 API，无需 API Key：

```
https://images.unsplash.com/photo-{ID}?w=400&h=533&fit=crop
```

| 参数 | 说明 |
|------|------|
| `w` | 图片宽度 |
| `h` | 图片高度 |
| `fit=crop` | 裁剪模式 |

### 5.2 AsyncImage 加载图片

使用 SwiftUI 的 `AsyncImage` 异步加载网络图片，支持淡入效果：

```swift
AsyncImage(url: URL(string: imageURL), transaction: Transaction(animation: .easeIn(duration: 0.3))) { phase in
    switch phase {
    case .empty:
        // 加载中 - 显示灰色占位
        RoundedRectangle(cornerRadius: 24)
            .fill(Color.gray.opacity(0.3))
    case .success(let image):
        // 加载成功 - 淡入显示图片
        image
            .resizable()
            .aspectRatio(contentMode: .fill)
            .transition(.opacity)
    case .failure:
        // 加载失败 - 显示灰色回退
        RoundedRectangle(cornerRadius: 24)
            .fill(Color.gray.opacity(0.3))
    @unknown default:
        RoundedRectangle(cornerRadius: 24)
            .fill(Color.gray.opacity(0.3))
    }
}
```

| 属性 | 值 |
|------|-----|
| 淡入动画 | `.easeIn(duration: 0.3)` |
| 过渡效果 | `.transition(.opacity)` |
| 占位色 | `Color.gray.opacity(0.3)` |

---

## 六、组件规范

### 6.1 数据模型

```swift
struct CardItem: Identifiable, Hashable {
    let id: Int
    let title: String
    let icon: String           // SF Symbol 名称
    let color: Color           // 主题色（回退用）
    let imageURLs: [String]    // 同主题的多张图片 URL
}

let cards: [CardItem] = [
    CardItem(id: 1, title: "Photos", icon: "photo.fill", color: .blue, imageURLs: [
        "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400&h=533&fit=crop",
        "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=400&h=533&fit=crop",
        "https://images.unsplash.com/photo-1519681393784-d120267933ba?w=400&h=533&fit=crop",
        "https://images.unsplash.com/photo-1454496522488-7a8e488e8606?w=400&h=533&fit=crop"
    ]),
    CardItem(id: 2, title: "Videos", icon: "video.fill", color: .purple, imageURLs: [...]),
    CardItem(id: 3, title: "Documents", icon: "doc.fill", color: .orange, imageURLs: [...]),
    CardItem(id: 4, title: "Music", icon: "music.note", color: .pink, imageURLs: [...]),
    CardItem(id: 5, title: "Albums", icon: "photo.on.rectangle", color: .cyan, imageURLs: [...]),
    CardItem(id: 6, title: "Downloads", icon: "arrow.down.circle.fill", color: .green, imageURLs: [...]),
    CardItem(id: 7, title: "Favorites", icon: "heart.fill", color: .red, imageURLs: [...]),
    CardItem(id: 8, title: "Recents", icon: "clock.fill", color: .indigo, imageURLs: [...]),
]
```

### 6.2 小卡片组件 (SmallCard)

```swift
struct SmallCard: View {
    let card: CardItem

    var body: some View {
        AsyncImage(url: URL(string: card.imageURLs[0]), transaction: Transaction(animation: .easeIn(duration: 0.3))) { phase in
            switch phase {
            case .empty:
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.gray.opacity(0.3))
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .transition(.opacity)
            case .failure:
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.gray.opacity(0.3))
            @unknown default:
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.gray.opacity(0.3))
            }
        }
        .aspectRatio(3.0/4.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay {
            // 底部渐变遮罩
            VStack {
                Spacer()
                LinearGradient(
                    colors: [Color.black.opacity(0), Color.black.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 80)
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
        .overlay(alignment: .bottom) {
            Text(card.title)
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.bottom, 16)
        }
    }
}
```

### 6.3 展开后卡片组件 (ExpandedCardItem)

```swift
struct ExpandedCardItem: View {
    let title: String
    let imageURL: String
    var showTitle: Bool = true  // 是否显示标题

    var body: some View {
        AsyncImage(url: URL(string: imageURL), transaction: Transaction(animation: .easeIn(duration: 0.3))) { phase in
            switch phase {
            case .empty:
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.gray.opacity(0.3))
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .transition(.opacity)
            case .failure:
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.gray.opacity(0.3))
            @unknown default:
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.gray.opacity(0.3))
            }
        }
        .aspectRatio(3.0/4.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay {
            if showTitle {
                VStack {
                    Spacer()
                    LinearGradient(
                        colors: [Color.black.opacity(0), Color.black.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 80)
                }
                .clipShape(RoundedRectangle(cornerRadius: 24))
            }
        }
        .overlay(alignment: .bottom) {
            if showTitle {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.bottom, 16)
            }
        }
    }
}
```

### 6.4 展开后图片使用规则

| 卡片位置 | 图片索引 | 显示标题 |
|---------|---------|---------|
| 第一张（主卡片） | `imageURLs[0]` | 是 |
| 第二张 | `imageURLs[1]` | 否 |
| 第三张 | `imageURLs[2]` | 否 |
| 第四张 | `imageURLs[3]` | 否 |

```swift
// 主卡片 - 显示标题
ExpandedCardItem(title: card.title, imageURL: card.imageURLs[0], showTitle: true)

// 其他卡片 - 不显示标题
ExpandedCardItem(title: "", imageURL: card.imageURLs[1], showTitle: false)
ExpandedCardItem(title: "", imageURL: card.imageURLs[2], showTitle: false)
ExpandedCardItem(title: "", imageURL: card.imageURLs[3], showTitle: false)
```

### 6.5 关闭按钮（iOS 26 Liquid Glass）

```swift
Button {
    onClose()
} label: {
    Image(systemName: "xmark")
        .font(.system(size: 16, weight: .bold))
        .foregroundStyle(.white)
        .frame(width: 44, height: 44)
}
.glassEffect(.clear.interactive())
.padding(.trailing, 20)
.padding(.top, 16)
```

---

## 七、样式规范

### 6.1 圆角

| 元素 | 圆角值 |
|------|--------|
| 卡片 | 24pt |
| 按钮 | 圆形 (通过 .glassEffect 自动处理) |

### 6.2 字体

| 元素 | 字体 |
|------|------|
| 导航栏标题 | `.largeTitle.bold()` |
| 卡片标题 | `.headline` |
| 卡片图标 | `.system(size: 40)` |
| 按钮图标 | `.system(size: 16-18, weight: .bold/.medium)` |

### 6.3 间距

| 元素 | 间距 |
|------|------|
| 卡片内图标与文字 | 12pt |
| 导航栏左右边距 | 16pt |
| 内容左右边距 | 20pt |
| 关闭按钮右边距 | 20pt |
| 关闭按钮顶部边距 | 16pt |

### 6.4 按钮尺寸

| 按钮 | 尺寸 |
|------|------|
| 搜索按钮 | 44 x 44 pt |
| 关闭按钮 | 44 x 44 pt |

---

## 八、色彩规范

### 7.1 背景色

```swift
// 主背景：纯黑色
Color.black

// 模态背景遮罩：Liquid Glass
Color.clear
    .glassEffect(.regular, in: .rect(cornerRadius: 0))
```

### 7.2 文字/图标颜色

- 导航栏标题：`.primary`（自动适配深色模式）
- 卡片内文字/图标：`.white`
- 按钮图标：`.white`

---

## 九、动画规范

### 8.1 状态变量

```swift
@State private var expandedCardId: Int? = nil      // 当前展开的卡片 ID
@State private var animProgress: CGFloat = 0       // 主卡片动画进度 (0-1)
@State private var showSmallCard: Bool = true      // 小卡片是否显示
@State private var showSecondCard: CGFloat = 0     // 第二张卡片动画进度
@State private var showThirdCard: CGFloat = 0      // 第三张卡片动画进度
@State private var showFourthCard: CGFloat = 0     // 第四张卡片动画进度
@State private var scrollOffset: CGFloat = 0       // 滚动偏移量
```

### 8.2 展开动画时序

| 时间点 | 动作 |
|--------|------|
| 0ms | 主卡片开始展开，小卡片立即隐藏 |
| 350ms | 第二张卡片从下方滑入 |
| 550ms | 第三张卡片从下方滑入 |
| 750ms | 第四张卡片从下方滑入 |

### 8.3 关闭动画

- 所有卡片同时收起
- 小卡片延迟 0.05 秒后开始淡入（0.25 秒完成）
- 0.6 秒后移除展开状态

### 8.4 Spring 动画参数

```swift
// 主卡片展开
.spring(response: 0.55, dampingFraction: 0.8)

// 其他卡片滑入/收起
.spring(response: 0.5, dampingFraction: 0.8)

// 小卡片淡入
.easeIn(duration: 0.25)
```

### 8.5 3D 旋转效果

```swift
.rotation3DEffect(
    .degrees(Double(1 - progress) * 35.0),
    axis: (x: 1.0, y: -1.0, z: 0.0),
    perspective: 0.3
)
```

### 8.6 卡片滑入偏移

```swift
// 从下方滑入 100pt
.offset(y: (1 - cardProgress) * 100)
```

---

## 十、Metal Shader - 液态扭曲效果

### 9.1 文件: LiquidCurvature.metal

```metal
#include <metal_stdlib>
using namespace metal;

[[ stitchable ]] float2 liquidCurvature(
    float2 position,
    float4 bounds,
    float progress
) {
    if (progress >= 0.99) {
        return position;
    }

    float2 size = bounds.zw;
    float2 center = size * 0.5;
    float2 uv = (position - center) / center;

    float intensity = (1.0 - progress) * 0.2;
    float dist = length(uv);
    float distortion = 1.0 + intensity * dist * dist;

    float skewX = uv.y * intensity * 0.4;
    float skewY = -uv.x * intensity * 0.25;

    float2 distorted = uv * distortion;
    distorted.x += skewX;
    distorted.y += skewY;

    float2 result = distorted * center + center;
    result = clamp(result, float2(0.0), size);

    return result;
}
```

### 9.2 SwiftUI 调用

```swift
struct LiquidEffect: ViewModifier {
    let progress: CGFloat

    func body(content: Content) -> some View {
        if progress > 0.05 && progress < 0.95 {
            content
                .distortionEffect(
                    ShaderLibrary.liquidCurvature(
                        .boundingRect,
                        .float(progress)
                    ),
                    maxSampleOffset: CGSize(width: 100, height: 100)
                )
        } else {
            content
        }
    }
}
```

---

## 十一、SwiftUI API 清单

### 10.1 iOS 26 Liquid Glass

| API | 用途 |
|-----|------|
| `.glassEffect(.clear.interactive())` | 透明交互式玻璃效果 |
| `.glassEffect(.regular, in: .rect(cornerRadius:))` | 带形状的玻璃效果 |
| `.scrollEdgeEffectStyle(.soft, for: .top)` | 滚动边缘柔和效果 |

### 10.2 布局

- `GeometryReader` - 获取屏幕尺寸
- `LazyVGrid` - 网格布局
- `GridItem(.flexible(), spacing:)` - 弹性列配置
- `ScrollView` - 可滚动容器
- `ZStack` - 层叠布局
- `VStack` / `HStack` - 垂直/水平布局
- `.coordinateSpace(name:)` - 命名坐标空间
- `PreferenceKey` - 子视图向父视图传递数据

### 10.3 形状与样式

- `RoundedRectangle(cornerRadius:)` - 圆角矩形
- `.fill(color.gradient)` - 渐变填充
- `LinearGradient` - 线性渐变
- `.aspectRatio(3.0/4.0, contentMode: .fit)` - 宽高比
- `.overlay { }` - 叠加内容

### 10.4 动画

- `withAnimation(.spring(response:dampingFraction:))` - Spring 动画
- `withAnimation(.easeIn(duration:))` - 缓入动画
- `.scaleEffect(x:y:anchor:)` - 缩放效果
- `.offset(x:y:)` - 位置偏移
- `.opacity()` - 透明度
- `.rotation3DEffect()` - 3D 旋转

### 10.5 交互

- `.onTapGesture { }` - 点击手势
- `.allowsHitTesting(false)` - 禁用点击
- `@State` - 状态管理
- `DispatchQueue.main.asyncAfter()` - 延迟执行

### 10.6 特效

- `.distortionEffect()` - Metal Shader 扭曲效果
- `ShaderLibrary` - 访问 Metal Shader
- `.ignoresSafeArea()` - 忽略安全区域
- `.preferredColorScheme(.dark)` - 强制深色模式

---

## 十二、文件结构

```
LiquidGlassDemo/
├── LiquidGlassDemo/
│   ├── LiquidGlassDemoApp.swift    // App 入口
│   ├── ContentView.swift            // 主视图（包含所有组件）
│   └── LiquidCurvature.metal        // Metal Shader
└── LiquidGlassDemo.xcodeproj/
```

---

## 十三、关键实现要点

1. **ZStack 布局**：ScrollView 全屏，导航栏和渐变遮罩浮动在上层
2. **滚动追踪**：使用 `PreferenceKey` + `coordinateSpace` 追踪滚动偏移
3. **导航栏淡入淡出**：根据 `scrollOffset` 计算 `navBarOpacity`
4. **渐变遮罩**：使用 `LinearGradient` 实现柔和边缘效果
5. **小卡片位置追踪**：使用 `GeometryReader` 记录每个小卡片的 frame
6. **Liquid Glass**：使用 `.glassEffect()` API 实现玻璃效果
7. **横屏适配**：通过 `screenSize.width > screenSize.height` 判断
8. **深色模式**：使用 `.preferredColorScheme(.dark)` 强制深色

---

*文档版本 2.0 - 2025-01-21 更新*
