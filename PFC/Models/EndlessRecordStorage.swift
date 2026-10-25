import Foundation

/// 无限模式的最高纪录（一次找出多少个数字）
enum EndlessRecordStorage {
    /// 供 @AppStorage 直接读写，写入后首页卡片会自动刷新
    static let defaultsKey = "pfc.endlessBestCleared"

    static func best() -> Int {
        UserDefaults.standard.integer(forKey: defaultsKey)
    }

    /// 提交成绩，返回是否刷新了纪录
    @discardableResult
    static func submit(_ clearedCount: Int) -> Bool {
        guard clearedCount > 0 else { return false }
        let current = best()
        guard clearedCount > current else { return false }
        UserDefaults.standard.set(clearedCount, forKey: defaultsKey)
        return true
    }
}
