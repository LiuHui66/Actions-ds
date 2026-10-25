import SwiftUI

/// 无限模式的结算页（sheet 覆盖在训练页上）
struct EndlessResultView: View {
    let result: EndlessResult
    let onRetry: () -> Void
    let onExit: () -> Void

    // 提交成绩后会自动刷新这里，显示最新纪录
    @AppStorage(EndlessRecordStorage.defaultsKey) private var best: Int = 0

    var body: some View {
        ZStack {
            PFCScreenBackground()

            VStack(spacing: 18) {
                VStack(spacing: 6) {
                    Text("无限模式 · 本局成绩")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(result.roundsCompleted)")
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                        Text("轮")
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }

                    Text("共找出 \(result.clearedCount) 个数字")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if result.isNewRecord {
                    Label("新纪录", systemImage: "sparkles")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(Color.purple.gradient))
                }

                HStack(spacing: 10) {
                    statCard(title: "评级", value: result.grade.title, tint: result.grade.color)
                    statCard(title: "总用时", value: String(format: "%.0f", result.elapsed), tint: .purple)
                    statCard(
                        title: "失误",
                        value: "\(result.mistakes)",
                        tint: result.mistakes == 0 ? .green : .orange
                    )
                }
                .padding(.horizontal, 20)

                VStack(spacing: 6) {
                    Text("平均 \(String(format: "%.1f", result.secondsPerNumber)) 秒/个 · 停在 \(result.boardTotal) 个的板面")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if best > 0 {
                        Text("最高纪录 \(best) 个")
                            .font(.caption)
                            .foregroundStyle(.purple.opacity(0.9))
                    }

                    Text(result.grade.comment)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 2)
                }
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
                                    .fill(Color.purple.gradient)
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
            .padding(.top, 28)
            .padding(.bottom, 24)
        }
        .presentationDetents([.height(540)])
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
    EndlessResultView(
        result: EndlessResult(
            clearedCount: 38,
            roundsCompleted: 2,
            mistakes: 1,
            boardTotal: 20,
            elapsed: 168,
            isNewRecord: true
        ),
        onRetry: {},
        onExit: {}
    )
    .preferredColorScheme(.dark)
}
