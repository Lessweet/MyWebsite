//
//  LiquidCurvature.metal
//  LiquidGlassDemo
//

#include <metal_stdlib>
using namespace metal;

[[ stitchable ]] float2 liquidCurvature(
    float2 position,
    float4 bounds,
    float progress
) {
    // progress = 1 时完全不扭曲
    if (progress >= 0.99) {
        return position;
    }

    float2 size = bounds.zw;
    float2 center = size * 0.5;

    // 归一化坐标 (-1 到 1)
    float2 uv = (position - center) / center;

    // 扭曲强度
    float intensity = (1.0 - progress) * 0.2;

    // 桶形畸变
    float dist = length(uv);
    float distortion = 1.0 + intensity * dist * dist;

    // 非对称扭曲
    float skewX = uv.y * intensity * 0.4;
    float skewY = -uv.x * intensity * 0.25;

    // 应用扭曲
    float2 distorted = uv * distortion;
    distorted.x += skewX;
    distorted.y += skewY;

    // 转回像素坐标
    float2 result = distorted * center + center;

    // 限制在边界内，防止白色条纹
    result = clamp(result, float2(0.0), size);

    return result;
}
