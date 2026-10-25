import SwiftUI

/// 无限模式一局的结果
struct EndlessResult: Identifiable {
    let id = UUID()

    /// 一共找出多少个数字
    let clearedCount: Int
    /// 完整清空了多少轮
    let roundsCompleted: Int
    /// 失误次数
    let mistakes: Int
    /// 时间耗尽时板面上总共有多少个数字
    let boardTotal: Int
    let isNewRecord: Bool

    /// 评级：按 100 秒内找出的总个数换算
    /// S ≥ 45（平均 2.2 秒/个）、A ≥ 35、B ≥ 25、C ≥ 15、其它 D
    var grade: Grade {
        if clearedCount >= 45 { return .s }
        if clearedCount >= 35 { return .a }
        if clearedCount >= 25 { return .b }
        if clearedCount >= 15 { return .c }
        return .d
    }

    /// 平均每个数字耗时（一局固定 100 秒，所以等于 100 / 找出个数）
    var secondsPerNumber: TimeInterval {
        guard clearedCount > 0 else { return EndlessRules.totalDuration }
        return EndlessRules.totalDuration / Double(clearedCount)
    }
}
