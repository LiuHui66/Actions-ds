import SwiftUI

/// 首页：选择难度
struct HomeView: View {
    @StateObject private var updateChecker = UpdateChecker()

    var body: some View {
        NavigationStack {
            ZStack {
                PFCScreenBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        header

                        ForEach(Difficulty.allCases) { difficulty in
                            NavigationLink(value: difficulty) {
                                DifficultyCard(difficulty: difficulty)
                            }
                            .buttonStyle(.plain)
                        }

                        footer
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Difficulty.self) { difficulty in
                TrainingView(difficulty: difficulty)
            }
            // 回到首页时按「6 小时间隔」检查一次是否有新版本
            .task { updateChecker.autoCheck() }
        }
        .tint(.mint)
        .sheet(isPresented: $updateChecker.isPresentingUpdate) {
            if case let .available(info) = updateChecker.status {
                UpdateSheet(info: info) {
                    updateChecker.dismiss()
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("前额叶训练")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("按顺序找数字，训练注意力、视觉搜索与工作记忆。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 4)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("规则：倒计时 5 秒结束后开始计时，按 1 → N 的顺序依次点选数字；全部找完后点击「停止」结束本轮。")
                .font(.footnote)
                .foregroundStyle(.secondary)

            // 手机上直接能看到装的是哪个包，方便按版本号区分
            HStack(spacing: 10) {
                Text("版本 \(AppVersion.display)")
                    .font(.caption2)
                    .foregroundStyle(.secondary.opacity(0.6))

                Spacer(minLength: 0)

                Button {
                    updateChecker.checkManually()
                } label: {
                    HStack(spacing: 5) {
                        if updateChecker.status == .checking {
                            ProgressView()
                                .controlSize(.mini)
                                .tint(.mint)
                        }
                        Text(updateChecker.status == .checking ? "检查中…" : "检查更新")
                            .font(.caption2)
                    }
                    .foregroundStyle(.mint.opacity(0.85))
                }
                .buttonStyle(.plain)
                .disabled(updateChecker.status == .checking)
            }

            updateStatusLine
        }
        .padding(.top, 6)
    }

    @ViewBuilder
    private var updateStatusLine: some View {
        switch updateChecker.status {
        case .upToDate:
            Text("已是最新版本")
                .font(.caption2)
                .foregroundStyle(.mint.opacity(0.65))

        case .failed:
            Text("检查更新失败，请确认网络后重试")
                .font(.caption2)
                .foregroundStyle(.orange.opacity(0.85))

        case let .available(info):
            Button {
                updateChecker.isPresentingUpdate = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.caption2)
                    Text("有新版本 \(info.display)，点击查看")
                        .font(.caption2)
                }
                .foregroundStyle(.mint)
            }
            .buttonStyle(.plain)

        default:
            EmptyView()
        }
    }
}

private struct DifficultyCard: View {
    let difficulty: Difficulty

    // 监听同一份数据，训练结束后返回首页会自动刷新最佳成绩
    @AppStorage(BestTimeStorage.defaultsKey) private var bestTimesData: Data = Data()

    private var best: TimeInterval? {
        guard let dict = try? JSONDecoder().decode([String: Double].self, from: bestTimesData) else {
            return nil
        }
        return dict[difficulty.rawValue]
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(difficulty.tint.opacity(0.16))
                Image(systemName: difficulty.symbolName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(difficulty.tint)
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(difficulty.title)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("\(difficulty.numberCount)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(difficulty.tint.opacity(0.16)))
                        .foregroundStyle(difficulty.tint)
                }

                Text(difficulty.subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if let best {
                    Text("最佳成绩 \(TimeFormat.best(best))")
                        .font(.caption)
                        .foregroundStyle(difficulty.tint.opacity(0.9))
                } else {
                    Text(difficulty.hint)
                        .font(.caption)
                        .foregroundStyle(.secondary.opacity(0.8))
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.35))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.white.opacity(0.09), lineWidth: 1)
        )
    }
}

#Preview {
    HomeView()
}
