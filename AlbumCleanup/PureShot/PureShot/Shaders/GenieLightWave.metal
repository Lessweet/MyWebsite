#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// ═══════════════════════════════════════════════════════════════
//  GenieLightWave - Genie AI 风格光波扫描 Metal Shader
//  实现从灵动岛向下扩散的折射光波效果
// ═══════════════════════════════════════════════════════════════

// MARK: - Lens Distortion Effect (透镜折射效果)
// 用于照片气泡的液态折射感

[[ stitchable ]]
half4 lensDistortion(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float intensity
) {
    // 归一化坐标
    float2 uv = position / size;
    float2 center = float2(0.5, 0.5);

    // 到中心的距离
    float2 delta = uv - center;
    float dist = length(delta);

    // 透镜折射：边缘弯曲
    float distortion = 1.0 + intensity * dist * dist;
    float2 distortedUV = center + delta / distortion;

    // 采样位置
    float2 samplePos = distortedUV * size;

    return layer.sample(samplePos);
}

// MARK: - Ripple Distortion Effect (涟漪折射效果)
// 光波经过时产生轻微的折射扭曲，像水波纹穿过玻璃

[[ stitchable ]]
float2 genieRipple(
    float2 position,
    float4 bounds,
    float time,        // 动画时间 (0-1)
    float waveY,       // 波前沿Y位置 (像素)
    float intensity    // 扭曲强度
) {
    // 计算到波前沿的距离
    float distanceToWave = position.y - waveY;

    // 波的影响范围 (在波前沿附近产生扭曲)
    float waveWidth = 150.0;

    // 只在波前沿附近产生扭曲
    if (abs(distanceToWave) < waveWidth) {
        // 平滑的波形函数
        float normalizedDist = distanceToWave / waveWidth;
        float waveFactor = cos(normalizedDist * M_PI_F) * 0.5 + 0.5;

        // 水平方向的波纹扭曲
        float rippleX = sin(position.y * 0.05 + time * 10.0) * waveFactor * intensity * 3.0;

        // 垂直方向的轻微拉伸
        float rippleY = sin(position.x * 0.03 + time * 8.0) * waveFactor * intensity * 2.0;

        return float2(position.x + rippleX, position.y + rippleY);
    }

    return position;
}

// MARK: - Genie Glow Layer Effect (光晕图层效果)
// 在光波经过的区域添加柔和的光晕

[[ stitchable ]]
half4 genieGlow(
    float2 position,
    SwiftUI::Layer layer,
    float4 bounds,
    float waveY,       // 波前沿Y位置
    float intensity    // 光照强度
) {
    // 获取原始像素颜色
    half4 color = layer.sample(position);

    // 计算光照区域 (波前沿以上的区域)
    if (position.y < waveY) {
        // 从顶部向下衰减的光照
        float lightFalloff = 1.0 - (position.y / waveY);
        lightFalloff = pow(lightFalloff, 0.6); // 非线性衰减，更自然

        // 柔和的白色光晕叠加
        float glowAmount = lightFalloff * intensity * 0.2;
        color.rgb = mix(color.rgb, half3(1.0), half(glowAmount));
    }

    // 波前沿的高亮边缘
    float distanceToWave = abs(position.y - waveY);
    float edgeWidth = 80.0;
    if (distanceToWave < edgeWidth) {
        float edgeFactor = 1.0 - (distanceToWave / edgeWidth);
        edgeFactor = pow(edgeFactor, 2.0);
        float edgeGlow = edgeFactor * intensity * 0.15;
        color.rgb = mix(color.rgb, half3(1.0), half(edgeGlow));
    }

    return color;
}

// MARK: - Simple Wave Distortion (简化版波纹扭曲)
// 更柔和的扭曲效果

[[ stitchable ]]
float2 softRipple(
    float2 position,
    float time,
    float waveY,
    float amplitude
) {
    float distanceToWave = position.y - waveY;
    float waveRadius = 200.0;

    if (distanceToWave > -waveRadius && distanceToWave < waveRadius * 0.5) {
        // 平滑过渡
        float t = (distanceToWave + waveRadius) / (waveRadius * 1.5);
        float wave = sin(t * M_PI_F) * amplitude;

        // 水平波纹
        float offsetX = sin(position.y * 0.02 + time * 5.0) * wave;
        float offsetY = cos(position.x * 0.015 + time * 4.0) * wave * 0.5;

        return float2(position.x + offsetX, position.y + offsetY);
    }

    return position;
}

// ═══════════════════════════════════════════════════════════════
// MARK: - Liquid Edge Bend (液态边缘弯曲效果)
// 当视图靠近屏幕边缘时，产生向内收缩的弯曲效果
// 模拟透镜折射或被"吸入"灵动岛的视觉感
// ═══════════════════════════════════════════════════════════════

[[ stitchable ]]
float2 liquidEdgeBend(
    float2 position,
    float2 size,
    float topEdgeDistance,    // 视图顶部距屏幕顶部的距离 (0-1)
    float bottomEdgeDistance, // 视图底部距屏幕底部的距离 (0-1)
    float bendStrength        // 弯曲强度 (0-1)
) {
    float2 center = size / 2.0;
    float2 uv = position / size;

    // 计算水平方向的偏移
    float xOffset = 0.0;

    // 顶部边缘弯曲（当靠近屏幕顶部时）
    float topInfluence = 1.0 - smoothstep(0.0, 0.3, topEdgeDistance);
    if (topInfluence > 0.0) {
        // 距离顶部越近，弯曲越强
        float yFactor = 1.0 - uv.y; // 顶部 = 1, 底部 = 0
        float bendAmount = pow(yFactor, 2.0) * topInfluence * bendStrength;
        // 向中心收缩
        xOffset += (center.x - position.x) * bendAmount * 0.4;
    }

    // 底部边缘弯曲（当靠近屏幕底部时）
    float bottomInfluence = 1.0 - smoothstep(0.0, 0.3, bottomEdgeDistance);
    if (bottomInfluence > 0.0) {
        // 距离底部越近，弯曲越强
        float yFactor = uv.y; // 顶部 = 0, 底部 = 1
        float bendAmount = pow(yFactor, 2.0) * bottomInfluence * bendStrength;
        // 向中心收缩
        xOffset += (center.x - position.x) * bendAmount * 0.4;
    }

    return float2(position.x + xOffset, position.y);
}

// MARK: - Liquid Scroll Distortion (液态滚动扭曲)
// 完整的液态滚动效果，包含边缘弯曲和透镜效果

[[ stitchable ]]
float2 liquidScrollDistort(
    float2 position,
    float2 size,
    float scrollPosition,     // 当前视图在屏幕中的位置 (0-1, 0=顶部, 1=底部)
    float velocity,           // 滚动速度
    float screenHeight        // 屏幕高度
) {
    float2 center = size / 2.0;
    float2 uv = position / size;

    float2 offset = float2(0.0, 0.0);

    // 边缘区域定义 (上下 20%)
    float edgeZone = 0.2;

    // 顶部弯曲
    if (scrollPosition < edgeZone) {
        float edgeFactor = 1.0 - (scrollPosition / edgeZone);
        edgeFactor = pow(edgeFactor, 1.5); // 非线性增强

        // Y轴位置影响弯曲程度（顶部弯曲更强）
        float yInfluence = 1.0 - uv.y;
        float bendStrength = edgeFactor * yInfluence * 0.3;

        // X方向向中心收缩
        offset.x = (center.x - position.x) * bendStrength;

        // Y方向轻微压缩
        offset.y = (center.y - position.y) * bendStrength * 0.1;
    }

    // 底部弯曲
    if (scrollPosition > (1.0 - edgeZone)) {
        float edgeFactor = (scrollPosition - (1.0 - edgeZone)) / edgeZone;
        edgeFactor = pow(edgeFactor, 1.5);

        // Y轴位置影响（底部弯曲更强）
        float yInfluence = uv.y;
        float bendStrength = edgeFactor * yInfluence * 0.3;

        // X方向向中心收缩
        offset.x = (center.x - position.x) * bendStrength;

        // Y方向轻微压缩
        offset.y = (center.y - position.y) * bendStrength * 0.1;
    }

    // 速度影响：快速滚动时增加形变
    float velocityFactor = clamp(abs(velocity) * 0.001, 0.0, 0.2);
    offset *= (1.0 + velocityFactor);

    return position + offset;
}

// MARK: - Dynamic Island Pull Effect (灵动岛吸附效果)
// 当内容靠近灵动岛时，产生向上"溢出"的视觉效果

[[ stitchable ]]
float2 dynamicIslandPull(
    float2 position,
    float2 size,
    float distanceToIsland,   // 距离灵动岛的距离 (像素)
    float pullStrength        // 吸附强度 (0-1)
) {
    float2 center = size / 2.0;

    // 影响范围 (150像素内)
    float influenceRange = 150.0;

    if (distanceToIsland < influenceRange && distanceToIsland > 0.0) {
        float influence = 1.0 - (distanceToIsland / influenceRange);
        influence = pow(influence, 2.0) * pullStrength;

        // 计算到中心的距离
        float distToCenter = abs(position.x - center.x) / center.x;

        // 边缘向中心收缩更多，形成"收口"效果
        float xOffset = (center.x - position.x) * influence * 0.5 * (1.0 + distToCenter);

        // 顶部向上拉伸
        float yFactor = 1.0 - (position.y / size.y);
        float yOffset = -yFactor * influence * 30.0;

        return float2(position.x + xOffset, position.y + yOffset);
    }

    return position;
}

// ═══════════════════════════════════════════════════════════════
// MARK: - Liquid Curvature Effect (液态弧形弯曲效果)
// 广角镜头/吸入感弯曲效果
// 核心逻辑：越靠近边缘，像素的 X 轴就越往中心收缩
// 产生 Bezier 曲线边缘，而非直线倾斜
// ═══════════════════════════════════════════════════════════════

[[ stitchable ]]
float2 liquidCurvature(
    float2 position,
    float2 size,
    float strength       // 弯曲强度 (0-1)
) {
    // 安全检查：确保 size 有效
    if (size.x <= 0.0 || size.y <= 0.0 || strength <= 0.001) {
        return position;
    }

    float2 uv = position / size;

    // 确保 uv 在有效范围内
    uv = clamp(uv, float2(0.0), float2(1.0));

    // 计算距离上下边缘的程度 (0=边缘, 0.5=中心)
    float distToEdge = min(uv.y, 1.0 - uv.y);

    // 边缘影响区域 (30% 的区域产生弯曲)
    float edgeZone = 0.3;

    // 只在边缘区域产生影响
    if (distToEdge < edgeZone) {
        // 使用 pow 函数创建平滑的弧线过渡
        float t = 1.0 - (distToEdge / edgeZone);
        float factor = t * t;  // 平方函数，更平滑

        // 根据距离边缘的程度，将 X 坐标向中心拉动
        float offsetX = (0.5 - uv.x) * factor * strength;

        return float2(position.x + offsetX * size.x, position.y);
    }

    return position;
}
