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

/// ═══════════════════════════════════════════════════════════════
/// liquidExpand - 液态展开形变效果
/// 点击卡片展开时的弯曲动画
/// - 双轴联动：X 轴弯曲 + Y 轴拉伸
/// - S 曲线分布：三次方曲线
/// - 过冲处理：progress > 1.0 时产生反向微弱膨胀
/// ═══════════════════════════════════════════════════════════════
///
/// position: 当前像素位置
/// size: 视图尺寸
/// progress: 动画进度 (0 = 弯曲收缩, 1 = 平直展开, >1 = 过冲膨胀)
/// bendIntensity: 弯曲强度系数
///
[[ stitchable ]]
float2 liquidExpand(float2 position, float2 size, float progress, float bendIntensity) {
    // 归一化坐标 (0-1)
    float2 uv = position / size;

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

/// ═══════════════════════════════════════════════════════════════
/// bendBrightness - 弯曲时的边缘高光效果
/// 让弯曲的边缘区域有轻微的亮度提升
/// ═══════════════════════════════════════════════════════════════
///
/// position: 当前像素位置
/// color: 原始颜色
/// size: 视图尺寸
/// progress: 动画进度
///
[[ stitchable ]]
half4 bendBrightness(float2 position, half4 color, float2 size, float progress) {
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
