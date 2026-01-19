# iOS 26 Liquid Glass Demo

## 快速测试方法

### 方法1: Xcode新建项目
1. Xcode → File → New → Project → iOS App
2. 命名为 `LiquidGlassDemo`
3. 删除自动生成的 ContentView.swift
4. 将 `LiquidGlassDemo.swift` 拖入项目
5. 运行 (需要 iOS 26 Simulator 或真机)

### 方法2: Swift Playgrounds (iPad)
1. 创建新的 App 项目
2. 粘贴代码
3. 直接运行

## Demo 包含内容

### 1. Zoom Transition (iOS 18+)
- `matchedTransitionSource` + `navigationTransition(.zoom)`
- 卡片点击展开为全屏
- 这个在 iOS 18+ 就可以工作

### 2. Liquid Glass Morph (iOS 26+)
- `GlassEffectContainer` + `glassEffectID`
- 按钮之间的流体变形动画
- 需要 iOS 26 才能看到效果

## 关键代码说明

```swift
// 1. 创建命名空间
@Namespace private var namespace

// 2. 源视图标记
.matchedTransitionSource(id: card.id, in: namespace)

// 3. 目标视图使用zoom过渡
.navigationTransition(.zoom(sourceID: card.id, in: namespace))

// 4. iOS 26 Liquid Glass morph
GlassEffectContainer {
    Button { }
        .glassEffect()
        .glassEffectID("id", in: namespace)
}
```

## 预期效果

- 点击卡片 → 3D缩放展开为全屏
- 关闭时 → 反向收缩回卡片位置
- iOS 26: 玻璃材质 + 流体morph动画
