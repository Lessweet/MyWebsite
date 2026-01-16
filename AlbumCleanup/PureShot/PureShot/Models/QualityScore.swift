import Foundation

// ═══════════════════════════════════════════════════════════════
//  QualityScore - 照片质量评分模型
//  结合清晰度、曝光、构图、人脸属性等多维度评分
// ═══════════════════════════════════════════════════════════════

struct QualityScore: Codable {
    // 清晰度评分 (0-1)，越高越清晰
    let sharpness: Float

    // 曝光评分 (0-1)，0.5 为最佳曝光
    let exposure: Float

    // 噪点评分 (0-1)，越高噪点越少
    let noise: Float

    // 构图评分 (0-1)，基于规则/美学
    let composition: Float

    // 人脸质量 (可选)
    let faceQuality: FaceQuality?

    // 综合评分 (0-100)
    var overallScore: Float {
        var score: Float = 0
        var weights: Float = 0

        // 清晰度权重最高
        score += sharpness * 40
        weights += 40

        // 曝光评分 (偏离 0.5 越远越差)
        let exposureScore = 1 - abs(exposure - 0.5) * 2
        score += exposureScore * 25
        weights += 25

        // 噪点评分
        score += noise * 20
        weights += 20

        // 构图评分
        score += composition * 15
        weights += 15

        // 人脸加分
        if let face = faceQuality {
            let faceBonus = face.averageScore * 10
            score += faceBonus
            weights += 10
        }

        return (score / weights) * 100
    }

    // 评分等级描述
    var gradeDescription: String {
        switch overallScore {
        case 90...100: return "极佳"
        case 80..<90: return "优秀"
        case 70..<80: return "良好"
        case 60..<70: return "一般"
        default: return "较差"
        }
    }
}

// MARK: - Face Quality

struct FaceQuality: Codable {
    let faceCount: Int
    let eyesOpen: Float       // 睁眼程度 (0-1)
    let smile: Float          // 微笑程度 (0-1)
    let faceFocus: Float      // 人脸清晰度 (0-1)

    var averageScore: Float {
        (eyesOpen + smile + faceFocus) / 3
    }
}

// MARK: - Default Score

extension QualityScore {
    static let placeholder = QualityScore(
        sharpness: 0.5,
        exposure: 0.5,
        noise: 0.5,
        composition: 0.5,
        faceQuality: nil
    )
}
