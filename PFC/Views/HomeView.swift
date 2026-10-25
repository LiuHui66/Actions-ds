import SwiftUI

/// 首页导航目的地
enum HomeRoute: Hashable {
    case difficulty(Difficulty)
    case endless
}

/// 首页：选择模式
///
/// 1.1.0 起移除了「检查更新 / 下载新版本」入口与整个更新提示模块。
/// 原因：跳转外部地址下载安装包属于绕过商店分发，上架审核不允许；
/// 且侧载场景下 App 无法自我替换，提示了也要回电脑重装，实际价值有限。
/// 现在首页只有四张模式卡片（三个难度 + 无限模式）。
struct HomeView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                PFCScreenBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        header

                        ForEach(Difficulty.allCases) { difficulty in
                            NavigationLink(value: HomeRoute.difficulty(difficulty)) {
                                DifficultyCard(difficulty: difficulty)
                            }
                            .buttonStyle(.plain)
                        }

                        NavigationLink(value: HomeRoute.endless) {
                            EndlessCard()
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case let .difficulty(difficulty):
                    TrainingView(difficulty: difficulty)
                case .endless:
                    EndlessTrainingView()
                }
            }
        }
        .tint(.mint)
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

/// 无限模式卡片（和三个难度卡区分开，用紫色 + 渐变边框）
private struct EndlessCard: View {
    @AppStorage(EndlessRecordStorage.defaultsKey) private var best: Int = 0

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.purple.opacity(0.18))
                Image(systemName: "infinity")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color.purple)
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("无限模式")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("NEW")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.purple.opacity(0.24)))
                        .foregroundStyle(Color.purple)
                }

                Text(EndlessRules.summary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if best > 0 {
                    Text("最高纪录 \(best) 个")
                        .font(.caption)
                        .foregroundStyle(Color.purple.opacity(0.95))
                } else {
                    Text("时间归零自动结算，看你能清空几轮")
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
                .fill(Color.purple.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.purple.opacity(0.30), lineWidth: 1)
        )
    }
}

#Preview {
    HomeView()
}
