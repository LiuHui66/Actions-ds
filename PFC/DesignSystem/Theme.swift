import Foundation
import SwiftUI

/// 统一的深色训练背景
struct PFCScreenBackground: View {
    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.05, blue: 0.08)
            RadialGradient(
                colors: [Color.mint.opacity(0.16), .clear],
                center: .topLeading,
                startRadius: 8,
                endRadius: 420
            )
            RadialGradient(
                colors: [Color.indigo.opacity(0.28), .clear],
                center: .bottomTrailing,
                startRadius: 8,
                endRadius: 460
            )
        }
        .ignoresSafeArea()
    }
}

enum TimeFormat {
    /// 12.34（不带单位）
    static func plain(_ value: TimeInterval) -> String {
        String(format: "%.2f", value)
    }

    /// 超过 1 分钟时显示 1:03.45，否则显示 12.34
    static func clock(_ value: TimeInterval) -> String {
        guard value >= 60 else { return String(format: "%.2f", value) }
        let minutes = Int(value) / 60
        let seconds = value.truncatingRemainder(dividingBy: 60)
        return String(format: "%d:%05.2f", minutes, seconds)
    }

    static func best(_ value: TimeInterval) -> String {
        clock(value) + " 秒"
    }
}
