import Foundation
import Combine

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
///
/// 注意：自签名安装的 App 不能自我替换，这里只负责「提示 + 给下载入口」。
/// 故意不加 @MainActor：@StateObject 的默认值在非隔离上下文里创建，
/// 加了 @MainActor 会报 "call to main actor-isolated initializer in a synchronous nonisolated context"。
/// 需要回主线程更新状态的地方，统一用 MainActor.run。
final class UpdateChecker: ObservableObject {

    enum Status: Equatable {
        case idle
        case checking
        case upToDate
        case available(UpdateInfo)
        case failed
    }

    /// 一次检查的结果（不持有 self，方便在后台算完再回主线程）
    private enum Outcome {
        case newer(UpdateInfo)
        case current
        case failure
    }

    @Published private(set) var status: Status = .idle
    @Published var isPresentingUpdate = false

    /// 自动检查的最小间隔：6 小时，避免每次回到首页都发请求
    private let autoCheckInterval: TimeInterval = 6 * 60 * 60
    private let lastCheckKey = "update.lastCheck"
    private let dismissedKey = "update.dismissedVersion"
    private let defaults = UserDefaults.standard

    // MARK: - 对外接口

    /// 启动 / 回到首页时调用：距上次检查超过间隔才真的请求
    func autoCheck() {
        guard status == .idle else { return }

        let last = defaults.double(forKey: lastCheckKey)
        if last > 0, Date().timeIntervalSince1970 - last < autoCheckInterval {
            return
        }
        startCheck(userInitiated: false)
    }

    /// 用户点「检查更新」：忽略间隔强制请求，失败时给出可见反馈
    func checkManually() {
        guard status != .checking else { return }
        startCheck(userInitiated: true)
    }

    /// 用户点了「稍后提醒」：记住这个版本，之后不再反复弹
    func dismiss() {
        if case let .available(info) = status {
            defaults.set(info.id, forKey: dismissedKey)
        }
        isPresentingUpdate = false
    }

    // MARK: - 内部实现

    private func startCheck(userInitiated: Bool) {
        status = .checking
        Task {
            let outcome = await UpdateChecker.fetchOutcome()
            await MainActor.run {
                self.apply(outcome, userInitiated: userInitiated)
            }
        }
    }

    /// 只在主线程调用
    private func apply(_ outcome: Outcome, userInitiated: Bool) {
        switch outcome {
        case let .newer(info):
            defaults.set(Date().timeIntervalSince1970, forKey: lastCheckKey)
            status = .available(info)

            // 主动点的要弹；自动检查时，该版本已被「稍后提醒」就不再打扰
            let dismissed = defaults.string(forKey: dismissedKey)
            if userInitiated || dismissed != info.id {
                isPresentingUpdate = true
            }

        case .current:
            defaults.set(Date().timeIntervalSince1970, forKey: lastCheckKey)
            status = .upToDate

        case .failure:
            status = .failed
        }
    }

    private static func fetchOutcome() async -> Outcome {
        do {
            let remote = try await fetchRemoteVersion()
            if remote.isNewer(thanMarketing: AppVersion.marketing, build: AppVersion.build) {
                return .newer(UpdateInfo(marketing: remote.marketing, build: remote.build))
            }
            return .current
        } catch {
            return .failure
        }
    }

    private static func fetchRemoteVersion() async throws -> RemoteVersion {
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
///
/// 全部用 String 处理：`split(separator:)` 返回的是 Substring，
/// 而 trimmingCharacters(in:) 只定义在 String 上，直接用会编译失败。
private struct RemoteVersion {
    let marketing: String
    let build: String

    init(text: String) throws {
        var marketingValue: String?
        var buildValue: String?

        let lines = text.components(separatedBy: CharacterSet.newlines)
        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: CharacterSet.whitespaces)
            if line.isEmpty || line.hasPrefix("#") { continue }
            guard let eq = line.firstIndex(of: "=") else { continue }

            let key = String(line[line.startIndex..<eq])
                .trimmingCharacters(in: CharacterSet.whitespaces)
            let value = String(line[line.index(after: eq)...])
                .trimmingCharacters(in: CharacterSet.whitespaces)

            if key == "MARKETING_VERSION" {
                marketingValue = value
            } else if key == "BUILD_NUMBER" {
                buildValue = value
            }
        }

        guard let m = marketingValue, let b = buildValue, !m.isEmpty, !b.isEmpty else {
            throw URLError(.cannotParseResponse)
        }
        marketing = m
        build = b
    }

    func isNewer(thanMarketing localMarketing: String, build localBuild: String) -> Bool {
        let remoteParts = Self.parts(marketing)
        let localParts = Self.parts(localMarketing)

        if remoteParts != localParts {
            return Self.isGreater(remoteParts, localParts)
        }
        return (Int(build) ?? 0) > (Int(localBuild) ?? 0)
    }

    /// 1.0.1 → [1, 0, 1, 0]，补齐位数，避免 1.0 与 1.0.0 比较出错
    private static func parts(_ value: String) -> [Int] {
        var result: [Int] = []
        for piece in value.components(separatedBy: ".") {
            let trimmed = piece.trimmingCharacters(in: CharacterSet.whitespaces)
            result.append(Int(trimmed) ?? 0)
        }
        while result.count < 4 { result.append(0) }
        return result
    }

    /// 逐位比较，避免依赖数组运算符的重载细节
    private static func isGreater(_ lhs: [Int], _ rhs: [Int]) -> Bool {
        let count = max(lhs.count, rhs.count)
        var index = 0
        while index < count {
            let left = index < lhs.count ? lhs[index] : 0
            let right = index < rhs.count ? rhs[index] : 0
            if left != right { return left > right }
            index += 1
        }
        return false
    }
}
