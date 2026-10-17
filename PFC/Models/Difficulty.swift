import Foundation
import SwiftUI

/// 训练难度：初级 / 中级 / 高级，依次对应 10 / 20 / 30 个数字
enum Difficulty: String, CaseIterable, Identifiable, Hashable {
    case beginner
    case intermediate
    case advanced

    var id: String { rawValue }

    var title: String {
        switch self {
        case .beginner: return "初级"
        case .intermediate: return "中级"
        case .advanced: return "高级"
        }
    }

    /// 需要找出的数字总个数
    var numberCount: Int {
        switch self {
        case .beginner: return 10
        case .intermediate: return 20
        case .advanced: return 30
        }
    }

    /// 网格列数（行数自动推导）
    var columns: Int {
        switch self {
        case .beginner: return 5
        case .intermediate: return 5
        case .advanced: return 6
        }
    }

    var rows: Int {
        Int(ceil(Double(numberCount) / Double(columns)))
    }

    var subtitle: String {
        "\(numberCount) 个数字 · \(columns) × \(rows) 网格"
    }

    var hint: String {
        switch self {
        case .beginner: return "熟悉规则，按 1 → 10 顺序点选"
        case .intermediate: return "扩大搜索范围，按 1 → 20 顺序点选"
        case .advanced: return "高强度注意力，按 1 → 30 顺序点选"
        }
    }

    var tint: Color {
        switch self {
        case .beginner: return .mint
        case .intermediate: return .cyan
        case .advanced: return .orange
        }
    }

    var symbolName: String {
        switch self {
        case .beginner: return "leaf.fill"
        case .intermediate: return "flame.fill"
        case .advanced: return "bolt.fill"
        }
    }
}
