#include <metal_stdlib>
using namespace metal;

/// ═══════════════════════════════════════════════════════════════
/// 液态弯曲效果 - iOS 26 Liquid Glass 风格
/// 通过像素级变形实现流体般的视觉效果
/// ═══════════════════════════════════════════════════════════════
///
/// position: 当前像素位置
/// size: 视图尺寸
/// strength: 弯曲强度 (0-1+)
/// direction: 弯曲方向 (1.0 = 底部收缩, -1.0 = 顶部收缩)
///
[[ stitchable ]]
float2 liquidBend(float2 position, float2 size, float strength, float direction) {
    // 归一化坐标 (0-1)
    float2 uv = position / size;

    // X轴中心点
    float centerX = 0.5;

    // 计算到中心的水平距离 (带符号, -0.5 到 0.5)
    float distFromCenterX = uv.x - centerX;

    // ═══════════════════════════════════════════════════════════════
    // 1. 非线性压缩 (Quadratic Ease)
    // 使用 pow() 让边缘弯曲从平滑过渡到剧烈，产生液体张力感
    // ═══════════════════════════════════════════════════════════════

    float edgeProgress;
    if (direction > 0) {
        // 底部收缩：uv.y 越大（越靠近底部），收缩越强
        edgeProgress = uv.y;
    } else {
        // 顶部收缩：uv.y 越小（越靠近顶部），收缩越强
        edgeProgress = 1.0 - uv.y;
    }

    // 二次方曲线 - 创造非线性的液态张力感
    // 边缘收缩从平滑开始，越靠近边缘越剧烈
    float taper = pow(edgeProgress, 2.0);

    // X轴收缩量
    float shrinkX = distFromCenterX * taper * strength * 0.85;
    float newX = position.x - shrinkX * size.x;

    // ═══════════════════════════════════════════════════════════════
    // 2. 灵动岛协同 - Y轴拉伸效果
    // 当照片接近屏幕边缘时，产生轻微的拉伸感
    // 模拟被边缘"引力"拉长的效果
    // ═══════════════════════════════════════════════════════════════

    float newY = position.y;

    // Y轴拉伸强度（比X轴收缩弱很多，只是辅助效果）
    float stretchIntensity = strength * 0.08;

    if (direction < 0) {
        // 顶部收缩时：顶部像素向上拉伸
        // 越靠近顶部，拉伸越明显
        float stretchFactor = (1.0 - uv.y) * stretchIntensity;
        newY = position.y - stretchFactor * size.y;
    } else {
        // 底部收缩时：底部像素向下拉伸
        // 越靠近底部，拉伸越明显
        float stretchFactor = uv.y * stretchIntensity;
        newY = position.y + stretchFactor * size.y;
    }

    // ═══════════════════════════════════════════════════════════════
    // 3. 动态圆角补偿
    // 在变形的同时，让角落区域的像素额外向内收缩
    // 使收缩后的梯形边缘更加圆润
    // ═══════════════════════════════════════════════════════════════

    // 计算到四个角的距离因子
    float cornerRadius = 0.15; // 圆角影响范围
    float cornerSoftness = strength * 0.3; // 圆角柔化强度

    // 检测是否在角落区域
    float cornerFactorX = 1.0 - smoothstep(0.0, cornerRadius, abs(distFromCenterX) > (0.5 - cornerRadius) ? (0.5 - abs(distFromCenterX)) : 1.0);
    float cornerFactorY;

    if (direction < 0) {
        // 顶部收缩：只处理顶部两个角
        cornerFactorY = 1.0 - smoothstep(0.0, cornerRadius, uv.y);
    } else {
        // 底部收缩：只处理底部两个角
        cornerFactorY = 1.0 - smoothstep(0.0, cornerRadius, 1.0 - uv.y);
    }

    // 角落区域额外收缩，使边缘更圆润
    float cornerPull = cornerFactorX * cornerFactorY * cornerSoftness;
    newX = newX - (distFromCenterX > 0 ? 1 : -1) * cornerPull * size.x * 0.1;

    return float2(newX, newY);
}
