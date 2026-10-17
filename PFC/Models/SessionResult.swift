import SwiftUI

/// 一轮训练的结果
struct SessionResult: Identifiable {
    let id = UUID()
    let difficulty: Difficulty
    let duration: TimeInterval
    let mistakes: Int
    let isNewRecord: Bool

    /// 平均每个数字耗时（秒）
    var averagePerNumber: TimeInterval {
        guard difficulty.numberCount > 0 else { return duration }
        return duration / Double(difficulty.numberCount)
    }

    var grade: Grade {
        switch averagePerNumber {
        case ..<1.0: return .s
        case ..<1.5: return .a
        case ..<2.2: return .b
        case ..<3.0: return .c
        default: return .d
        }
    }
}

enum Grade {
    case s, a, b, c, d

    var title: String {
        switch self {
        case .s: return "S"
        case .a: return "A"
        case .b: return "B"
        case .c: return "C"
        case .d: return "D"
        }
    }

    var color: Color {
        switch self {
        case .s: return .mint
        case .a: return .cyan
        case .b: return .yellow
        case .c: return .orange
        case .d: return .pink
        }
    }

    var comment: String {
        switch self {
        case .s: return "前额叶满负荷运转，非常出色。"
        case .a: return "专注度很高，继续保持这个节奏。"
        case .b: return "表现稳定，可以再压缩一点搜索时间。"
        case .c: return "注意力有波动，先保证准确再提速。"
        case .d: return "别急，稳定找出比快更重要。"
        }
    }
}
