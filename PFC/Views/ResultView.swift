import SwiftUI

/// 结果页（以 sheet 形式覆盖在训练页上）
struct ResultView: View {
    let result: SessionResult
    let onRetry: () -> Void
    let onExit: () -> Void

    var body: some View {
        ZStack {
            PFCScreenBackground()

            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("\(result.difficulty.title) · 本轮成绩")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(TimeFormat.clock(result.duration))
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                        Text("秒")
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }

                if result.isNewRecord {
                    Label("新纪录", systemImage: "sparkles")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(Color.mint.gradient))
                }

                HStack(spacing: 10) {
                    statCard(title: "评级", value: result.grade.title, tint: result.grade.color)
                    statCard(
                        title: "单个平均",
                        value: String(format: "%.2fs", result.averagePerNumber),
                        tint: .white
                    )
                    statCard(
                        title: "失误",
                        value: "\(result.mistakes)",
                        tint: result.mistakes == 0 ? .green : .orange
                    )
                }
                .padding(.horizontal, 20)

                Text(result.grade.comment)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer(minLength: 0)

                VStack(spacing: 10) {
                    Button(action: onRetry) {
                        Text("再来一次")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color.mint.gradient)
                            )
                            .foregroundStyle(.black.opacity(0.85))
                    }
                    .buttonStyle(.plain)

                    Button(action: onExit) {
                        Text("返回首页")
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color.white.opacity(0.08))
                            )
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
            }
            .padding(.top, 32)
            .padding(.bottom, 24)
        }
        .presentationDetents([.height(500)])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color(red: 0.04, green: 0.05, blue: 0.08))
    }

    private func statCard(title: String, value: String, tint: Color) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }
}

#Preview {
    ResultView(
        result: SessionResult(
            difficulty: .intermediate,
            duration: 23.48,
            mistakes: 2,
            isNewRecord: true
        ),
        onRetry: {},
        onExit: {}
    )
    .preferredColorScheme(.dark)
}
