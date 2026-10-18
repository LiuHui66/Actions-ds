import Foundation

/// 云端版本检查的配置。
/// 仓库改名 / 换账号时，只改这一个文件即可。
enum AppConfig {
    static let repoOwner = "LiuHui66"
    static let repoName = "Actions-ds"
    static let branch = "main"

    /// 直接读取仓库里的 VERSION 文件，它本来就是唯一版本号来源，不需要再维护第二份配置
    static var versionFileURL: URL {
        URL(string: "https://raw.githubusercontent.com/\(repoOwner)/\(repoName)/\(branch)/VERSION")!
    }

    /// Releases 页面（每次构建会自动发布一个 Release）
    static var releasePageURL: URL {
        URL(string: "https://github.com/\(repoOwner)/\(repoName)/releases/latest")!
    }

    /// 直链下载某个版本的 IPA（Release 里的资产文件名）
    static func ipaDownloadURL(marketing: String, build: String) -> URL {
        URL(string: "https://github.com/\(repoOwner)/\(repoName)/releases/latest/download/PFC-\(marketing)-\(build).ipa")!
    }
}
