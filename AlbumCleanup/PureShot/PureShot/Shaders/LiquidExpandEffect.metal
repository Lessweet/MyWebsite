//
//  LiquidExpandEffect.metal
//  PureShot
//
//  液态展开效果 Shader
//  - 双轴联动：X 轴弯曲 + Y 轴拉伸
//  - S 曲线分布：三次方曲线
//  - 过冲处理：progress > 1.0 时产生反向微弱膨胀
//  - 边缘高光：弯曲时边缘亮度提升
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// ═══════════════════════════════════════════════════════════════
//  liquidExpand - 液态展开形变效果
//  position: 当前像素位置
//  size: 视图尺寸
//  progress: 动画进度 (0 = 弯曲收缩, 1 = 平直展开, >1 = 过冲膨胀)
//  bendIntensity: 弯曲强度系数
// ═══════════════════════════════════════════════════════════════

[[ stitchable ]] float2 liquidExpand(
    float2 position,
    float2 size,
    float progress,
    float bendIntensity
) {
    // 归一化坐标 (0-1)
    float2 uv = position / size;
    float2 center = float2(0.5, 0.5);

    // 计算弯曲量：
    // - progress < 1.0: 正常弯曲 (1 - progress)
    // - progress > 1.0: 反向微弱膨胀，模拟物理惯性
    float bend;
    if (progress <= 1.0) {
        // 收缩状态：弯曲量随 progress 增加而减少
        bend = (1.0 - progress) * bendIntensity;
    } else {
        // 过冲状态：产生反向膨胀（负弯曲 = 向外凸）
        float overshoot = progress - 1.0;
        bend = -overshoot * bendIntensity * 0.3; // 过冲膨胀强度为正常弯曲的 30%
    }

    // ─────────────────────────────────────────────
    // S 曲线分布（三次方）
    // 中间弯曲最大，上下边缘为 0
    // ─────────────────────────────────────────────
    float yNorm = uv.y; // 0 到 1
    // 抛物线基础：中间为 1，两端为 0
    float yParabola = 4.0 * yNorm * (1.0 - yNorm);
    // 三次方强化：让弯曲更集中在中部
    float yCubic = yParabola * yParabola * yParabola;

    // ─────────────────────────────────────────────
    // X 轴弯曲：边缘向内收缩
    // ─────────────────────────────────────────────
    // 距离中心越远，弯曲越大
    float xDistFromCenter = (uv.x - 0.5) * 2.0; // -1 到 1
    float xBend = bend * yCubic * xDistFromCenter;

    // ─────────────────────────────────────────────
    // Y 轴拉伸：双轴联动
    // 当 X 轴收缩时，Y 轴轻微拉伸（体积守恒感）
    // ─────────────────────────────────────────────
    // X 轴越靠近中心，拉伸越强
    float xCenterFactor = 1.0 - abs(xDistFromCenter);
    // 使用二次曲线让拉伸更自然
    float stretchFactor = xCenterFactor * xCenterFactor;
    float yStretch = bend * stretchFactor * 0.15; // Y 轴拉伸强度为 X 弯曲的 15%

    // ─────────────────────────────────────────────
    // 计算最终位置偏移
    // ─────────────────────────────────────────────
    float2 newPos = position;

    // X 轴偏移：向中心收缩
    newPos.x -= xBend * size.x * 0.25;

    // Y 轴偏移：从中心向外拉伸
    float yOffsetFromCenter = uv.y - 0.5; // -0.5 到 0.5
    newPos.y += yOffsetFromCenter * yStretch * size.y;

    // ─────────────────────────────────────────────
    // 边界保护：防止采样越界
    // ─────────────────────────────────────────────
    newPos = clamp(newPos, float2(0.0), size);

    return newPos;
}

// ═══════════════════════════════════════════════════════════════
//  bendBrightness - 弯曲时的边缘高光效果
//  position: 当前像素位置
//  color: 原始颜色
//  size: 视图尺寸
//  progress: 动画进度
// ═══════════════════════════════════════════════════════════════

[[ stitchable ]] half4 bendBrightness(
    float2 position,
    half4 color,
    float2 size,
    float progress
) {
    // 归一化坐标
    float2 uv = position / size;

    // 计算弯曲程度（0-1）
    float bendAmount = abs(1.0 - progress);
    if (progress > 1.0) {
        bendAmount = (progress - 1.0) * 0.5; // 过冲时也有轻微高光
    }

    // ─────────────────────────────────────────────
    // 边缘高光计算
    // 越靠近左右边缘，高光越强
    // ─────────────────────────────────────────────
    float edgeDistance = abs(uv.x - 0.5) * 2.0; // 0（中心）到 1（边缘）
    // 使用平方让高光更集中在边缘
    float edgeFactor = edgeDistance * edgeDistance;

    // Y 轴分布：中间区域高光更明显
    float yFactor = 4.0 * uv.y * (1.0 - uv.y);

    // 组合高光强度
    float highlightIntensity = edgeFactor * yFactor * bendAmount;

    // 亮度提升（最大 +8%）
    float brightnessBoost = highlightIntensity * 0.08;

    // 应用高光
    half4 result = color;
    result.rgb += half3(brightnessBoost);

    // 确保不超过 1.0
    result.rgb = clamp(result.rgb, half3(0.0), half3(1.0));

    return result;
}

// ═══════════════════════════════════════════════════════════════
//  liquidExpandWithHighlight - 组合效果（可选）
//  同时应用形变和高光，减少 pass 数量
// ═══════════════════════════════════════════════════════════════

// 注：由于 distortionEffect 和 colorEffect 需要分开调用，
// 这里提供一个参考实现。如果需要更高性能，可以考虑
// 使用 layerEffect 将两者合并。
