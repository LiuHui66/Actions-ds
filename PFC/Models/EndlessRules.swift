import Foundation

/// 无限模式的规则常量（改规则只需要动这里）
enum EndlessRules {
    /// 一局的总时长（秒）
    static let totalDuration: TimeInterval = 100

    /// 开局板面数字个数
    static let initialCount = 10

    /// 每完成一轮追加的个数
    static let increment = 5

    /// 开局倒计时（秒）
    static let countdownSeconds = 5

    /// 一句话规则，用于首页卡片与倒计时提示
    static let summary = "\(Int(totalDuration)) 秒 · \(initialCount) 个起 · 每轮 +\(increment)"
}
