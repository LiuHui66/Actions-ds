# 前额叶训练 PFC Trainer（iOS / SwiftUI）

第一版只做一个核心训练功能：**按顺序找数字**（舒尔特方格式视觉搜索）。

## 玩法

1. 首页选择难度 → 初级 10 个 / 中级 20 个 / 高级 30 个
2. 进入训练页，数字随机打乱铺在网格里
3. **5 秒倒计时**（5 → 4 → 3 → 2 → 1），倒计时期间网格被遮罩
4. 倒计时结束自动开始计时，按 **1 → N** 的顺序依次点选数字
5. 点错会闪红 + 震动 + 记一次失误，已找过的数字变暗
6. **全部找完后**，底部按钮从「还剩 N 个数字」变成绿色的「全部找到 · 点击停止」
7. 点击停止 → 结果页：用时、单个平均、失误、S/A/B/C/D 评级、新纪录；数据按难度存本地

注意：计时器在点完最后一个数字后**不会自动停**，必须手动点「停止」。

## 环境

- Xcode 16+ / iOS 17.0+
- SwiftUI，无第三方依赖
- Bundle ID：`com.liuhui66.pfc`（1.0.1 起，之前是 `com.example.pfc`）

## 运行方式 A：新建工程（在 Mac 上）

1. Xcode → `File > New > Project` → **iOS App**
2. Product Name 填 `PFC`，Interface 选 **SwiftUI**，Language 选 **Swift**，取消勾选 Core Data / Tests
3. 删除模板自带的 `ContentView.swift` 和 `PFCApp.swift`
4. 把本目录下的 `PFC/` 文件夹整体拖进工程（勾选 *Copy items if needed* + *Create groups*）
5. ⌘R 运行

## 运行方式 B：用 XcodeGen 生成工程

```bash
brew install xcodegen
xcodegen generate
open PFC.xcodeproj
```

> CI 走的就是这条路：`xcodegen generate` → `xcodebuild` → 打 IPA，所以 `project.yml` 是唯一的工程定义，**不要手改 `PFC.xcodeproj`**（它被 `.gitignore` 排除，每次都是重新生成的）。

## 文件结构

```
.
├── VERSION                       # 唯一版本号来源（App 内「检查更新」也读它）
├── CHANGELOG.md
├── project.yml                   # XcodeGen 工程定义（Bundle ID / 显示名 / 版本在这里）
├── .github/workflows/ios-ipa.yml # 云端 macOS 编译流水线 + 自动发布 Release
├── scripts/
│   ├── build-unsigned-ipa.sh     # macOS 上构建未签名 IPA
│   └── push-all.bat              # Windows 一键提交+推送
└── PFC/
    ├── PFCApp.swift                  # 入口，锁定深色模式
    ├── DesignSystem/Theme.swift      # 背景、时间格式化
    ├── Models/
    │   ├── Difficulty.swift          # 初级/中级/高级 → 10/20/30，网格列数
    │   ├── SessionResult.swift       # 本轮成绩 + S~D 评级
    │   └── BestTimeStorage.swift     # 最佳成绩读写（UserDefaults）
    ├── Support/
    │   ├── Haptics.swift             # 触感反馈
    │   ├── AppVersion.swift          # 从 Info.plist 读版本号显示在首页
    │   ├── AppConfig.swift           # 仓库地址配置（更新检查用，换仓库只改这里）
    │   └── UpdateChecker.swift       # 读远程 VERSION、比对版本、暴露状态
    └── Views/
        ├── HomeView.swift            # 难度选择 + 版本号 + 检查更新入口
        ├── TrainingView.swift        # 倒计时 / 计时 / 点选 / 停止
        ├── NumberGrid.swift          # 数字方格与单元格状态
        ├── ResultView.swift          # 结果页
        └── UpdateSheet.swift         # 「发现新版本」面板
```

## 关键实现点

- 计时精度：记录 `startedAt`，界面用 30fps 刷新的 `Date.now - startedAt` 显示，点「停止」时再取一次真实差值，避免累加误差
- 整个「倒计时 → 计时」流程放在一个 `async` 循环里，用 `.task(id: runID)` 驱动；`再来一次` 只需换 `runID`，旧流程自动取消
- 网格列数随难度变化（5 / 5 / 6），单元格用 `aspectRatio(1)` 保持正方，字号自适应
- 难度卡片用 `@AppStorage` 监听同一份最佳成绩数据，训练完返回首页会自动刷新

---

# 用户升级提示（App 内「检查更新」）

## 先说清楚能做到什么、做不到什么

| | 能不能 | 原因 |
|---|---|---|
| App 内**提示**有新版本、显示版本对比、给出下载入口 | ✅ 已实现 | 自己拉一个版本文件比对即可 |
| App **自己静默升级**、点一下就装好 | ❌ 做不到 | 免费 Apple ID 自签名安装的 App，iOS 不允许它替换自身 |
| App Store 那种原生更新弹窗 | ❌ 做不到 | 同上，需要 App Store 或 TestFlight |

> 想要「点一下就升级」的原生体验，唯一途径是 **$99/年 开发者账号 + TestFlight**：把 IPA 传到 TestFlight，苹果会自动给测试用户推送更新。当前免费自签名模式下，升级必须回到电脑用 Sideloadly 覆盖安装。

## 实现原理

```
App 启动 → 请求 https://raw.githubusercontent.com/LiuHui66/Actions-ds/main/VERSION
   → 解析 MARKETING_VERSION / BUILD_NUMBER
   → 与本机 Info.plist 里的版本比较
   → 远程更新 → 弹「发现新版本」面板
```

- **复用 `VERSION` 文件**，不新增第二份配置，避免两边版本号写不一致
- 请求带时间戳参数绕开 `raw.githubusercontent.com` 的缓存
- **6 小时内不重复自动请求**（`update.lastCheck`）
- 点「稍后提醒」会记住该版本号（`update.dismissedVersion`），同一版本不再自动弹
- 首页底部有「检查更新」按钮；自动检查失败时静默，手动检查失败会显示「检查更新失败，请确认网络后重试」
- 版本比较按 `MARKETING_VERSION` 逐段数字比较，相同再比 `BUILD_NUMBER`

## 首页长什么样

```
版本 v1.0.1 (2)                    检查更新
```

有新版本时，下面多一行可点击的绿色提示：

```
⬇ 有新版本 v1.0.2 (3)，点击查看
```

点开 → 面板显示「当前 v1.0.1 (2) → 最新 v1.0.2 (3)」+ 三步升级说明 + 「打开下载页」/「直接下载 IPA 文件」/「稍后提醒」。

## 下载地址为什么不会是死链

流水线多了一步：每次构建成功后**自动发布一个 GitHub Release**，并把 IPA 作为附件挂上去。

| 地址 | 用途 |
|---|---|
| `https://github.com/LiuHui66/Actions-ds/releases/latest` | App 内「打开下载页」 |
| `.../releases/latest/download/PFC-<版本>-<构建号>.ipa` | App 内「直接下载 IPA 文件」 |

Release 长期有效（Artifacts 只有 90 天且需要登录），所以 App 里的链接不会过期。

## 需要改仓库地址时

只改 `PFC/Support/AppConfig.swift` 里的三行：

```swift
static let repoOwner = "LiuHui66"
static let repoName = "Actions-ds"
static let branch = "main"
```

## 怎么第一次验证这个功能

1. 出包安装 **1.0.1 (2)**，打开 App，底部显示 `版本 v1.0.1 (2)`，点「检查更新」→ 应显示「已是最新版本」
2. 把 `VERSION` 改成 `1.0.2 / 3`，push（不需要改任何代码）
3. 手机上把 App **杀掉重开**，几秒后会弹出「发现新版本 v1.0.2 (3)」

> 第 3 步注意：如果之前点过「稍后提醒」，自动检查不会再弹，此时点首页的「检查更新」手动触发即可。
> 如果第 1 步显示「检查更新失败」：多半是国内直连 `raw.githubusercontent.com` 不通，手机挂代理再试（这个失败不会影响训练功能）。

---

# 出包流程（Windows 环境）

## 硬限制先说清楚

iOS 安装包（IPA）**不能在 Windows 上生成**，这跟工具选择无关：

1. 编译 iOS App 必须用 Apple 的 **Xcode**，Xcode 只跑在 **macOS** 上；
2. 装到真机 iPhone 上必须有 **Apple 签名**（免费 Apple ID 或付费开发者账号）。

所以本项目走的是：**Windows 改代码 → 推到 GitHub → GitHub 的 macOS 机器编译 → 下载 IPA → Windows 上用 Sideloadly 签名安装**。

## 仓库信息

| 项 | 值 |
|---|---|
| GitHub 仓库 | https://github.com/LiuHui66/Actions-ds （Public） |
| 仓库根目录 | **就是本目录**（`pfc-trainer/` 的内容直接作为仓库根） |
| 本地路径 | `D:\Project\spring-ai-agent\pfc-trainer` |

> Public 仓库的 GitHub Actions **完全免费、不限分钟数**；私有仓库走 macOS runner 会按 10 倍计费（每月约 200 分钟 macOS 额度）。

## 日常迭代流程（全部在 Windows 上完成）

```
① 改代码
② 打开 VERSION，BUILD_NUMBER +1（改了功能再把 MARKETING_VERSION 升一位）
③ CHANGELOG.md 记一行
④ 双击 scripts\push-all.bat "修改说明"
⑤ GitHub Actions 自动编译（5~8 分钟）
⑥ 下载方式二选一：
   - Release 页（推荐，长期有效）：https://github.com/LiuHui66/Actions-ds/releases
   - Actions → 这次运行 → 底部 Artifacts（保留 90 天）
⑦ 解压得到 .ipa → Sideloadly 装到 iPhone
```

产物命名固定为 `PFC-<MARKETING_VERSION>-<BUILD_NUMBER>.ipa`，App 首页底部也会显示 `版本 v1.0.1 (2)`，装到手机上就能确认是哪一版。

## 版本号规则

只有一个版本来源：`VERSION`

```
MARKETING_VERSION=1.0.1   # 对外版本号，功能变化才升
BUILD_NUMBER=2            # 内部构建号，每次出包 +1
```

当前版本：**1.0.1 (2)**

| 版本 | 变更 |
|---|---|
| 1.0.0 (1) | 首版，Bundle ID `com.example.pfc` |
| 1.0.1 (2) | Bundle ID 改为 `com.liuhui66.pfc` + 新增 App 内「检查更新」+ 自动发布 Release |

> ⚠️ 1.0.1 改过 Bundle ID，所以它和 1.0.0 是**两个 App**，会并存安装。确认新版正常后删掉旧的那个（免费账号同时最多 3 个自签 App，别占坑）。

## 装到 iPhone（Windows + Sideloadly）

### 一次性准备（**顺序别搞反**）

1. **iTunes 官网版**：https://www.apple.com/itunes/download/win64
   ⚠️ **绝对不要用微软商店版 iTunes，也不要用商店的「Apple 设备 / Apple Devices」**——它们缺 `Apple Mobile Device Support` 组件，会导致签名认证直接失败（本项目实际踩过，见下方踩坑记录）
2. **iCloud 官网版**：https://support.apple.com/zh-cn/114050
3. 装完 **重启电脑**，确认服务在跑：
   `Win+R` → `services.msc` → **Apple Mobile Device Service** → 状态「正在运行」
4. **Sideloadly**：https://sideloadly.io （商店里搜不到，必须官网下）
5. 如果以前装过商店版苹果组件，**先全部卸载**再装官网版，否则服务会冲突

### 每次装包

```
① iPhone 连线、解锁、手机点「信任此电脑」
② Sideloadly 拖入 .ipa → Apple ID 填账号 → Start
③ 双重认证弹出时输入手机收到的 6 位验证码（或改用 App 专用密码）
④ 手机：设置 → 隐私与安全性 → 开发者模式 → 打开 → 重启 → 确认
⑤ 手机：设置 → 通用 → VPN与设备管理 → 信任你的 Apple ID
⑥ 打开 App，首页底部确认版本号对得上
```

- 免费 Apple ID 签名的 App **只有 7 天有效期**，到期重装
- 免费账号同时最多 3 个自签 App
- 想免手动续签：装 **AltStore**（https://altstore.io），每 7 天自动重签

---

# 实战踩坑记录（1.0.0 首次安装全过程）

按发生顺序记录，以后再遇到同样报错可直接对照。

## 坑 1：`git push` 报 `Password authentication is not supported`

GitHub 已彻底禁用账号密码。解决：

```bat
cmdkey /list | findstr /i github        REM 先看有没有缓存
cmdkey /delete:git:https://github.com   REM 删掉坏凭据
git config --global credential.helper manager
git config --global credential.https://github.com.username LiuHui66
```

之后 push 会弹浏览器登录窗口。若始终不弹窗，可用 Personal Access Token 临时写进 remote 地址（推完记得改回来，否则 token 明文留在 `.git/config`）。

## 坑 2：Sideloadly 报 `GSA returned a non-plist response (HTTP 503)`

这个报错其实是**下游症状**，根因可能完全不同，按下面顺序排查：

### 2.1 先确认 TLS 是否正常

```bat
curl -v --max-time 20 https://gsa.apple.com/
```

- `SSL/TLS handshake complete` + 任意 HTTP 状态码 → TLS 正常，问题在别处
- `SEC_E_UNTRUSTED_ROOT (0x80090325)` → **本机缺 Apple 根证书**（见 2.2）
- 一直超时 / 无响应 → 网络或代理问题，换手机热点

### 2.2 缺 Apple 根证书（GHOST/精简版 Windows 常见）

确认到底是不是证书本身有问题（看签发者）：

```bat
echo | "E:\Git\usr\bin\openssl.exe" s_client -connect gsa.apple.com:443 -servername gsa.apple.com -brief
```

- `Peer certificate: CN = gsa.apple.com, O = Apple Inc.` → **证书是真的**，只是本地不信任 → 导入 `Apple Root CA`
- issuer 出现代理/杀软名字（Fiddler、Clash、Kaspersky、360…）→ 被中间人解密，关掉对应软件的 HTTPS 扫描

导入根证书（管理员 PowerShell，直接握手取证书，无需下载）：

```powershell
$h='gsa.apple.com'
$tcp=New-Object Net.Sockets.TcpClient($h,443)
$ssl=New-Object Net.Security.SslStream($tcp.GetStream(),$false,{param($a,$b,$c,$d) $true})
$ssl.AuthenticateAsClient($h)
$leaf=New-Object Security.Cryptography.X509Certificates.X509Certificate2($ssl.RemoteCertificate)
$chain=New-Object Security.Cryptography.X509Certificates.X509Chain
$chain.ChainPolicy.RevocationMode='NoCheck'
$null=$chain.Build($leaf)
$root=$chain.ChainElements[$chain.ChainElements.Count-1].Certificate
[IO.File]::WriteAllBytes("$env:TEMP\AppleRootCA.cer",$root.RawData)
Import-Certificate -FilePath "$env:TEMP\AppleRootCA.cer" -CertStoreLocation Cert:\LocalMachine\Root
$ssl.Close();$tcp.Close()
```

验证：重开 CMD 再跑 `curl -v https://gsa.apple.com/`，出现 `handshake complete` 即修好。

> 之后单独测认证接口（返回 **401/400 都是好消息**，说明网络和证书都通，只剩 `503` 才代表被限流）：
> ```bat
> curl -sI https://gsa.apple.com/grandslam/GsService2 | findstr HTTP
> ```

### 2.3 `Apple Mobile Device Service` 启动报 **1053**

这是本次的**真正元凶**：AMDS 起不来 → Anisette(Local) 拿不到设备认证数据 → Apple 回 503。

排查：

```bat
sc qc "Apple Mobile Device Service"      REM 看 BINARY_PATH_NAME 是否指向 WindowsApps（商店版）
dir "C:\Program Files\Common Files\Apple\Mobile Device Support\"
dir "C:\Program Files\Common Files\Apple\Apple Application Support\"   REM 缺 CoreFoundation.dll 会起不来
```

修复要点：

- 商店版「Apple 设备 / Apple Devices」与官网版 iTunes 混装 → 全部卸载后只装官网版
- 卸载顺序：Apple Devices → iTunes → Apple Software Update → **Apple Mobile Device Support** → Bonjour → Apple Application Support (32/64) → iCloud
- 删残留目录后重装，再重启
- 杀毒软件（360/火绒/卡巴/ESET）临时退出后重试

正常后：

```bat
sc query "Apple Mobile Device Service"   REM 需要看到 STATE : 4 RUNNING
```

并在 **iTunes 里确认能看到 iPhone**——看得到才说明 Anisette 有数据来源。

### 2.4 等一切就绪还 503：是 Apple 的限流

错误里出现 `Guru Meditation ... Please wait at least 10 minutes` 就是 Apple 对「账号 + IP」的短时封禁，原因是反复点 Start 累积了异常登录。

⚠️ **每点一次 Start 都会重置计时**。正确做法：

1. 立刻停手，等 1~2 小时
2. **生成 App 专用密码**（关键）：https://appleid.apple.com → 登录与安全 → **App 专用密码** → 生成
   → 填进 Sideloadly 密码框，可**完全跳过 6 位验证码环节**，少一个触发限流的点
3. **换出口 IP**：手机开热点给电脑
4. **清缓存**：`Win+R` → `%APPDATA%\Sideloadly` → 整个文件夹改名备份 → 重开
5. Apple ID / 密码**手输**，不要粘贴（粘贴易带隐藏空格）
6. 只点**一次** Start，然后耐心等，别重复点

都无效时的备选：换一个 Apple ID（新注册的干净账号额度相同）、换一台 Windows、或改用 AltStore（另一套 Anisette 实现，且带自动续签）。

> 记住失败次数是**会累积**的：每次改动后只试一次，失败就换维度，不要连点。

---

## 其它备选方案

| 方案 | 适用场景 | 成本 |
|---|---|---|
| GitHub Actions（当前方案） | 日常出包 | 免费（Public 仓库不限时长） |
| 租云端 Mac（MacinCloud / MacStadium） | 需要看真实报错、连真机调试 | 按小时几美元 |
| $99/年 Apple Developer Program | 长期自用，签名 1 年有效，**可走 TestFlight 实现真正的推送更新** | $99/年，CI 需配证书 + 描述文件 |

## 能不能放到 Gitee 上 Build？

**不能。** Gitee 只能当代码仓库，不能当 iOS 编译机：Gitee Go 提供的构建环境是 Linux / Windows / 自有主机，**没有 macOS 构建机**，`xcodebuild` 跑不起来。

推荐做法是双远端（一套代码推两处）：

```
你的 Windows 本地仓库
   ├─ push → GitHub   ← 负责编译 IPA
   └─ push → Gitee    ← 国内访问快 / 备份
```

```bat
git remote add origin https://github.com/LiuHui66/Actions-ds.git
git remote add gitee  https://gitee.com/<用户名>/<仓库名>.git
```

## 后续可以加

- 数字改为随机目标（如只找偶数、只找质数）增加工作记忆负荷
- 训练历史曲线、每日打卡、n-back
- 音效、暂停、横屏布局
