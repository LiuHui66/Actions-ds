import Foundation

/// 应用版本信息（来自 Info.plist，由构建脚本按 VERSION 文件注入）
enum AppVersion {
    static var marketing: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
    }

    /// 例如 "v1.0.0 (1)"
    static var display: String {
        "v\(marketing) (\(build))"
    }
}
