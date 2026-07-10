#include <metal_stdlib>
using namespace metal;

// ═══════════════════════════════════════════════════════════════
//  LiquidBend - 液态弯曲效果 Metal Shader
//  iOS 26 Liquid Glass 风格滚动弯曲
//  FluidMotion.swift 使用
// ═══════════════════════════════════════════════════════════════

/// 全局液态弯曲效果 - 中间凹进去的沙漏形
/// 多张照片作为一个整体，屏幕中心最窄，向上下边缘逐渐恢复正常宽度
/// 像一条被中间捏紧的液体带子
///
/// position: 当前像素在视图内的位置
/// size: 视图尺寸
/// strength: 弯曲强度 (0-1+)
/// screenPosY: 当前像素在屏幕上的绝对 Y 坐标
/// screenHeight: 屏幕总高度
/// screenCenterY: 屏幕中心 Y 坐标

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
