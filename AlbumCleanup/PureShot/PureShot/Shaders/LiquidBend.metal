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

/// ═══════════════════════════════════════════════════════════════
/// 全局液态弯曲效果 - 中间凹进去的沙漏形
/// 多张照片作为一个整体，屏幕中心最窄，向上下边缘逐渐恢复正常宽度
/// 像一条被中间捏紧的液体带子
/// ═══════════════════════════════════════════════════════════════
///
/// position: 当前像素在视图内的位置
/// size: 视图尺寸
/// strength: 弯曲强度 (0-1+)
/// screenPosY: 当前像素在屏幕上的绝对 Y 坐标
/// screenHeight: 屏幕总高度
/// screenCenterY: 屏幕中心 Y 坐标
///
[[ stitchable ]]
float2 liquidBendGlobal(float2 position, float2 size, float strength,
                        float screenPosY, float screenHeight, float screenCenterY) {
    // 归一化坐标 (0-1)
    float2 uv = position / size;

    // X轴中心点
    float centerX = 0.5;

    // 计算到中心的水平距离 (带符号, -0.5 到 0.5)
    float distFromCenterX = uv.x - centerX;

    // ═══════════════════════════════════════════════════════════════
    // 全局弯曲场：中间凹进去的沙漏形
    // 屏幕中心收缩最强，向边缘逐渐恢复正常
    // ═══════════════════════════════════════════════════════════════

    // 当前像素在屏幕上的 Y 位置
    float pixelScreenY = screenPosY + position.y;

    // 计算像素到屏幕中心的距离（归一化到 -1 ~ 1）
    float distFromCenter = (pixelScreenY - screenCenterY) / (screenHeight * 0.5);
    float absDistFromCenter = abs(distFromCenter);

    // 反转弯曲逻辑：中心最强，边缘最弱
    // 使用 cos 曲线：中心为1，边缘为0
    float bendProgress = 1.0 - absDistFromCenter;
    bendProgress = max(0.0, bendProgress);

    // 使用平滑的曲线让收缩更自然（像液体被捏紧）
    float liquidCurve = sin(bendProgress * 3.14159 * 0.5);

    // ═══════════════════════════════════════════════════════════════
    // X轴收缩 - 中间凹进去
    // 屏幕中心收缩最强，形成沙漏腰部
    // 注意：distortionEffect 返回的是采样位置，要收缩需要向外采样
    // ═══════════════════════════════════════════════════════════════

    float shrinkAmount = liquidCurve * strength * 1.0;  // 收缩系数
    float shrinkX = distFromCenterX * shrinkAmount;
    float newX = position.x + shrinkX * size.x;  // 加号：向外采样产生收缩效果

    // ═══════════════════════════════════════════════════════════════
    // Y轴：无拉伸，保持自然
    // ═══════════════════════════════════════════════════════════════

    float newY = position.y;

    // ═══════════════════════════════════════════════════════════════
    // 边缘圆润处理 - 让收缩后的边缘更加圆润
    // ═══════════════════════════════════════════════════════════════

    float cornerRadius = 0.15;
    float cornerSoftness = strength * liquidCurve * 0.25;

    // 边缘区域检测
    float edgeFactorX = smoothstep(0.35, 0.5, abs(distFromCenterX));

    // 中心区域的圆角（上下都处理）
    float centerZone = smoothstep(0.3, 0.0, absDistFromCenter);

    float cornerPull = edgeFactorX * centerZone * cornerSoftness;
    newX = newX + (distFromCenterX > 0 ? 1 : -1) * cornerPull * size.x * 0.15;

    return float2(newX, newY);
}
