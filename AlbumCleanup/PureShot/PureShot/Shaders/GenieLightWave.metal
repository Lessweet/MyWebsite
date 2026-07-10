#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// ═══════════════════════════════════════════════════════════════
//  GenieLightWave - Metal Shader
//  保留实际使用的 shader 函数
// ═══════════════════════════════════════════════════════════════

// MARK: - Lens Distortion Effect (透镜折射效果)
// 用于照片气泡的液态折射感 - PureShotPreview.swift 使用

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

// MARK: - Simple Wave Distortion (简化版波纹扭曲)
// 更柔和的扭曲效果 - LightWaveScanEffect.swift 使用

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
