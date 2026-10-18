import SwiftUI

/// 发现新版本时的提示面板
struct UpdateSheet: View {
    let info: UpdateInfo
    var onDismiss: () -> Void

    @Environment(\.openURL) private var openURL

    private var upgradeSteps: [String] {
        [
            "电脑上打开下载页，下载 PFC-\(info.marketing)-\(info.build).ipa（也可以直接在 Artifacts 里取）。",
            "用 Sideloadly 把 IPA 拖进去，填 Apple ID，点一次 Start 覆盖安装。",
            "装好后打开 App，首页底部版本号会变成 \(info.display)。"
        ]
    }

    var body: some View {
        ZStack {
            PFCScreenBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    versionCompare
                    steps
                    actions
                }
                .padding(22)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.mint.opacity(0.16))
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.mint)
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 3) {
                Text("发现新版本")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(info.display)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.mint)
            }

            Spacer(minLength: 0)
        }
    }

    private var versionCompare: some View {
        HStack(spacing: 10) {
            versionChip(title: "当前", value: AppVersion.display, tint: Color.secondary)
            Image(systemName: "arrow.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            versionChip(title: "最新", value: info.display, tint: .mint)
            Spacer(minLength: 0)
        }
    }

    private func versionChip(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }

    private var steps: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("怎么升级")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white)

            Text("这个 App 是用免费 Apple ID 自签名安装的，iOS 不允许它自己替换自己，所以需要在电脑上重装一次：")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(Array(upgradeSteps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 8) {
                    Text("\(index + 1).")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.mint)
                        .frame(width: 16, alignment: .leading)
                    Text(step)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var actions: some View {
        VStack(spacing: 10) {
            Button {
                openURL(info.releasePageURL)
            } label: {
                Text("打开下载页")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.mint)
                    )
                    .foregroundStyle(.black)
            }
            .buttonStyle(.plain)

            Button {
                openURL(info.ipaURL)
            } label: {
                Text("直接下载 IPA 文件")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.mint)
            }
            .buttonStyle(.plain)

            Button {
                onDismiss()
            } label: {
                Text("稍后提醒")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 2)
    }
}

#Preview {
    UpdateSheet(
        info: UpdateInfo(marketing: "1.0.2", build: "3"),
        onDismiss: {}
    )
}
