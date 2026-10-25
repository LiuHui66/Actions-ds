import SwiftUI

/// 无限模式一局的结果
struct EndlessResult: Identifiable {
    let id = UUID()

    /// 跨轮累计找出多少个数字（含最后一轮没清完的部分）
    let clearedCount: Int
    /// 完整清空了多少轮
    let roundsCompleted: Int
    /// 失误次数
    let mistakes: Int
    /// 时间耗尽时那一轮的数字个数
    let boardTotal: Int
    /// 本局实际总用时（各轮已用时间之和，不是固定 100 秒）
    let elapsed: TimeInterval
    let isNewRecord: Bool

    /// 评级：看完整清空了几轮（每轮数字更多、时间不变，难度是递增的）
    /// S ≥ 4 轮（清空到 25 个）、A ≥ 3 轮、B ≥ 2 轮、C ≥ 1 轮、其它 D
    var grade: Grade {
        switch roundsCompleted {
        case 4...: return .s
        case 3: return .a
        case 2: return .b
        case 1: return .c
        default: return .d
        }
    }

    /// 平均每个数字耗时
    var secondsPerNumber: TimeInterval {
        guard clearedCount > 0 else { return elapsed }
        return elapsed / Double(clearedCount)
    }
}
