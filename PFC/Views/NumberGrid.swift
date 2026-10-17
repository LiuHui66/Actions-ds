import SwiftUI

/// 数字方格
struct NumberGrid: View {
    let numbers: [Int]
    let columns: Int
    /// 下一个应该被点到的数字
    let nextExpected: Int
    let tint: Color
    /// 点错时闪烁的数字
    let flashingNumber: Int?
    let onTap: (Int) -> Void

    private var gridItems: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 10), count: columns)
    }

    private var fontSize: CGFloat {
        columns >= 6 ? 20 : 24
    }

    var body: some View {
        LazyVGrid(columns: gridItems, spacing: 10) {
            ForEach(numbers, id: \.self) { number in
                NumberCell(
                    number: number,
                    fontSize: fontSize,
                    isFound: number < nextExpected,
                    isFlashing: flashingNumber == number,
                    tint: tint,
                    action: { onTap(number) }
                )
            }
        }
    }
}

private struct NumberCell: View {
    let number: Int
    let fontSize: CGFloat
    let isFound: Bool
    let isFlashing: Bool
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(fill)

                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: isFlashing ? 2 : 1)

                Text("\(number)")
                    .font(.system(size: fontSize, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(textColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(4)
            }
            .aspectRatio(1, contentMode: .fit)
            .scaleEffect(isFound ? 0.92 : (isFlashing ? 0.95 : 1))
        }
        .buttonStyle(.plain)
        .disabled(isFound)
        .animation(.snappy(duration: 0.2), value: isFound)
        .animation(.easeOut(duration: 0.15), value: isFlashing)
        .accessibilityLabel("数字 \(number)")
    }

    private var fill: Color {
        if isFlashing { return Color.red.opacity(0.28) }
        if isFound { return tint.opacity(0.14) }
        return Color.white.opacity(0.07)
    }

    private var borderColor: Color {
        if isFlashing { return .red }
        if isFound { return tint.opacity(0.45) }
        return Color.white.opacity(0.10)
    }

    private var textColor: Color {
        if isFlashing { return .white }
        if isFound { return tint.opacity(0.55) }
        return .white
    }
}
