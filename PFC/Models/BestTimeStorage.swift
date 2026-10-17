import Foundation

/// 各难度的最佳成绩（UserDefaults，key -> 秒）
enum BestTimeStorage {
    /// 供 @AppStorage 监听同一条数据，写入后首页卡片会自动刷新
    static let defaultsKey = "pfc.bestTimes"

    static func all() -> [String: Double] {
        guard
            let data = UserDefaults.standard.data(forKey: defaultsKey),
            let dict = try? JSONDecoder().decode([String: Double].self, from: data)
        else { return [:] }
        return dict
    }

    static func best(for difficulty: Difficulty) -> Double? {
        all()[difficulty.rawValue]
    }

    /// 提交成绩，返回是否刷新了最佳纪录
    @discardableResult
    static func submit(_ duration: TimeInterval, for difficulty: Difficulty) -> Bool {
        var dict = all()
        let key = difficulty.rawValue
        if let old = dict[key], old <= duration { return false }
        dict[key] = duration
        if let data = try? JSONEncoder().encode(dict) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
        return true
    }
}
