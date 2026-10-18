import Foundation
import SwiftUI

/// 云端发现的新版本
struct UpdateInfo: Identifiable, Equatable {
    let marketing: String
    let build: String

    var id: String { "\(marketing)-\(build)" }
    var display: String { "v\(marketing) (\(build))" }

    var releasePageURL: URL { AppConfig.releasePageURL }
    var ipaURL: URL { AppConfig.ipaDownloadURL(marketing: marketing, build: build) }
}

/// 版本更新检查：读取仓库里的 VERSION 文件，与本地版本比较。
/// 注意：自签名安装的 App 不能自我替换，这里只负责「提示 + 给下载入口」。
@MainActor
final class UpdateChecker: ObservableObject {
    enum Status: Equatable {
        case idle
        case checking
        case upToDate
        case available(UpdateInfo)
        case failed
    }

    @Published private(set) var status: Status = .idle
    @Published var isPresentingUpdate = false

    /// 自动检查的最小间隔：6 小时，避免每次回到首页都发请求
    private let autoCheckInterval: TimeInterval = 6 * 60 * 60
    private let lastCheckKey = "update.lastCheck"
    private let dismissedKey = "update.dismissedVersion"

    private let defaults = UserDefaults.standard

    /// 启动时调用：距上次检查超过间隔才真的请求
    func autoCheck() {
        guard status == .idle else { return }

        let last = defaults.double(forKey: lastCheckKey)
        if last > 0, Date().timeIntervalSince1970 - last < autoCheckInterval {
            return
        }
        Task { await check(userInitiated: false) }
    }

    /// 用户点「检查更新」：忽略间隔强制请求，失败时给出可见反馈
    func checkManually() {
        guard status != .checking else { return }
        Task { await check(userInitiated: true) }
    }

    /// 用户点了「稍后提醒」：记住这个版本，之后不再反复弹
    func dismiss() {
        if case let .available(info) = status {
            defaults.set(info.id, forKey: dismissedKey)
        }
        isPresentingUpdate = false
    }

    private func check(userInitiated: Bool) async {
        status = .checking

        do {
            let remote = try await fetchRemoteVersion()
            defaults.set(Date().timeIntervalSince1970, forKey: lastCheckKey)

            if remote.isNewer(thanMarketing: AppVersion.marketing, build: AppVersion.build) {
                let info = UpdateInfo(marketing: remote.marketing, build: remote.build)
                status = .available(info)

                // 主动点的要弹；自动检查时，该版本已被「稍后提醒」就不再打扰
                let dismissed = defaults.string(forKey: dismissedKey)
                if userInitiated || dismissed != info.id {
                    isPresentingUpdate = true
                }
            } else {
                status = .upToDate
            }
        } catch {
            status = .failed
        }
    }

    private func fetchRemoteVersion() async throws -> RemoteVersion {
        // 加时间戳绕开 raw.githubusercontent.com 的缓存
        var comps = URLComponents(url: AppConfig.versionFileURL, resolvingAgainstBaseURL: false)
        comps?.queryItems = [URLQueryItem(name: "t", value: String(Int(Date().timeIntervalSince1970)))]
        guard let url = comps?.url else { throw URLError(.badURL) }

        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 12)
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try RemoteVersion(text: String(decoding: data, as: UTF8.self))
    }
}

/// 解析 VERSION 文件内容
private struct RemoteVersion {
    let marketing: String
    let build: String

    init(text: String) throws {
        var marketing: String?
        var build: String?

        for rawLine in text.split(separator: "\n") {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty, !line.hasPrefix("#"), let eq = line.firstIndex(of: "=") else { continue }

            let key = line[..<eq].trimmingCharacters(in: .whitespaces)
            let value = line[line.index(after: eq)...].trimmingCharacters(in: .whitespaces)

            switch key {
            case "MARKETING_VERSION": marketing = value
            case "BUILD_NUMBER": build = value
            default: break
            }
        }

        guard let m = marketing, let b = build, !m.isEmpty, !b.isEmpty else {
            throw URLError(.cannotParseResponse)
        }
        self.marketing = m
        self.build = b
    }

    func isNewer(thanMarketing localMarketing: String, build localBuild: String) -> Bool {
        let remoteParts = Self.parts(marketing)
        let localParts = Self.parts(localMarketing)
        if remoteParts != localParts {
            return remoteParts > localParts
        }
        return (Int(build) ?? 0) > (Int(localBuild) ?? 0)
    }

    /// 1.0.1 → [1, 0, 1, 0]，补齐位数，避免 1.0 与 1.0.0 比较出错
    private static func parts(_ value: String) -> [Int] {
        var result = value.split(separator: ".").map { Int($0.trimmingCharacters(in: .whitespaces)) ?? 0 }
        while result.count < 4 { result.append(0) }
        return result
    }
}
