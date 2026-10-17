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

注意：计时器在点完最后一个数字后**不会自动停**，必须手动点「停止」——这样多一个反应环节，也更符合你的描述。

## 环境

- Xcode 16+ / iOS 17.0+
- SwiftUI，无第三方依赖

## 运行方式 A：新建工程（推荐）

1. Xcode → `File > New > Project` → **iOS App**
2. Product Name 填 `PFC`，Interface 选 **SwiftUI**，Language 选 **Swift**，取消勾选 Core Data / Tests
3. 删除模板自带的 `ContentView.swift` 和 `PFCApp.swift`
4. 把本目录下的 `PFC/` 文件夹整体拖进工程（勾选 *Copy items if needed* + *Create groups*）
5. `PFC/Info.plist` 不需要手改；若需要锁定竖屏，在 Target → General → Device Orientation 只留 Portrait
6. ⌘R 运行

## 运行方式 B：用 XcodeGen 生成工程

```bash
brew install xcodegen
xcodegen generate
open PFC.xcodeproj
```

## 文件结构

```
.
├── VERSION                       # 唯一版本号来源
├── CHANGELOG.md
├── project.yml                   # XcodeGen 工程定义
├── .github/workflows/ios-ipa.yml # 云端 macOS 编译流水线（GitHub Actions）
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
    │   └── AppVersion.swift          # 从 Info.plist 读版本号显示在首页
    └── Views/
        ├── HomeView.swift            # 难度选择
        ├── TrainingView.swift        # 倒计时 / 计时 / 点选 / 停止
        ├── NumberGrid.swift          # 数字方格与单元格状态
        └── ResultView.swift          # 结果页
```

## 关键实现点

- 计时精度：记录 `startedAt`，界面用 30fps 刷新的 `Date.now - startedAt` 显示，点「停止」时再取一次真实差值，避免累加误差
- 整个「倒计时 → 计时」流程放在一个 `async` 循环里，用 `.task(id: runID)` 驱动；`再来一次` 只需换 `runID`，旧流程自动取消
- 网格列数随难度变化（5 / 5 / 6），单元格用 `aspectRatio(1)` 保持正方，字号自适应
- 难度卡片用 `@AppStorage` 监听同一份最佳成绩数据，训练完返回首页会自动刷新

## 后续可以加

- 数字改为随机目标（如只找偶数、只找质数）增加工作记忆负荷
- 训练历史曲线、每日打卡、n-back
- 音效、暂停、横屏布局

---

# 仓库与出包流程（Windows 环境）

## 仓库信息

| 项 | 值 |
|---|---|
| GitHub 仓库 | https://github.com/LiuHui66/Actions-ds （Public） |
| 仓库根目录 | **就是本目录**（`pfc-trainer/` 的内容直接作为仓库根） |
| 本地路径 | `D:\Project\spring-ai-agent\pfc-trainer` |

> 仓库根目录和本目录是同一个，所以 `.github/workflows/ios-ipa.yml` 正好落在 GitHub 要求的位置上，不需要额外调整路径。
> Public 仓库的 GitHub Actions **完全免费、不限分钟数**。

## 首次推送到 GitHub

在 `D:\Project\spring-ai-agent\pfc-trainer` 目录下打开 PowerShell 或 CMD，按顺序执行：

```bat
cd /d D:\Project\spring-ai-agent\pfc-trainer

git init
git branch -M main
git add -A
git commit -m "v1.0.0 首个版本：难度选择 + 5 秒倒计时 + 顺序找数字 + 结果页"
git remote add origin https://github.com/LiuHui66/Actions-ds.git
git push -u origin main
```

第一次 `push` 会弹出浏览器登录 GitHub（推荐），或在命令行输入 **Personal Access Token** 当密码（GitHub 已经不接受账号密码）。
Token 生成地址：https://github.com/settings/tokens → Generate new token (classic) → 勾选 `repo`。

推送成功后，`.github/workflows/ios-ipa.yml` 会自动触发一次编译；也可以到
https://github.com/LiuHui66/Actions-ds/actions 手动点 **Run workflow**。

## 日常迭代流程（全部在 Windows 上完成）

1. 改 `PFC/` 里的代码
2. 打开 `VERSION`，把 `BUILD_NUMBER` +1（改了功能就把 `MARKETING_VERSION` 也升一位）
3. `CHANGELOG.md` 里记一行
4. 双击 `scripts\push-all.bat "修改说明"`（或手动 `git add -A && git commit -m "..." && git push`）
5. GitHub Actions 自动编译 → Actions 页面 → 这次运行 → 底部 **Artifacts** 下载 `PFC-1.0.1-2.zip`
6. 解开得到 `PFC-1.0.1-2.ipa` → Sideloadly 装到 iPhone

产物命名固定为 `PFC-<MARKETING_VERSION>-<BUILD_NUMBER>.ipa`，App 首页底部也会显示 `版本 v1.0.1 (2)`，装到手机上就能确认是哪一版。

## 版本号规则

只有一个版本来源：`VERSION`

```
MARKETING_VERSION=1.0.0   # 对外版本号
BUILD_NUMBER=1            # 内部构建号，每次出包 +1
```

---

## 先说明：iOS 安装包无法在 Windows 上生成

这是 Apple 的硬限制，不是工具链选择问题：

1. 编译 iOS App 必须用 Apple 的 **Xcode**，Xcode 只运行在 **macOS** 上；
2. 装到真机 iPhone 上还必须有 **Apple 签名**（免费 Apple ID 或付费开发者账号）。

所以"改完代码 → 直接吐一个 ipa"这一步必须在 **macOS 机器上**完成。下面三条路都不需要你自己买 Mac。

---

## 方案 1：GitHub Actions 云端 macOS 编译（免费，已配置好）

`.github/workflows/ios-ipa.yml`（**必须在仓库根目录的 `.github/workflows/` 下**，本仓库已符合）会在 GitHub 的 macOS 机器上跑 `scripts/build-unsigned-ipa.sh`，产出一个**未签名 IPA**。

### 一次性准备
1. 按上面「首次推送到 GitHub」把代码推上去
2. 打开仓库 → **Actions** 标签 → 左侧选 **Build iOS IPA** → 右侧 **Run workflow**
3. 等 5~10 分钟，进入这次运行 → 页面底部 **Artifacts** → 下载 `PFC-1.0.0-1`
4. 解压 → 里面是 `PFC-1.0.0-1.ipa`

### 把 IPA 装到 iPhone（Windows 上完成）
1. Windows 装 **iTunes**（或微软商店的「Apple 设备」App）和 **iCloud**，登录同一个 Apple ID
2. 数据线连 iPhone，手机上点「信任此电脑」
3. Windows 装 **[Sideloadly](https://sideloadly.io/)**（免费）
4. 打开 Sideloadly：IPA 拖进去 → 填你的 Apple ID → 点 **Start**，按提示输入密码/双重认证
5. 手机 → 设置 → 通用 → **VPN与设备管理** → 信任你的开发者证书
6. 回到桌面，App 已安装

### 必须知道的限制
- 免费 Apple ID 签名的 App **只有 7 天有效期**，过期打不开，需要重新用 Sideloadly 装一次（改代码后本来也要重装，所以影响不大）
- 免费账号最多同时装 3 个自签 App
- 用 **[AltStore](https://altstore.io/)** 或 **[SideStore](https://sidestore.io/)** 可以每周自动续签，免手动重装

---

## 方案 2：租一台云端 Mac（要调试就用这个）

- [MacinCloud](https://www.macincloud.com/) / [MacStadium](https://www.macstadium.com/) / AWS EC2 Mac 实例
- 按小时计费，几美元起步，Windows 用远程桌面连上去
- 优点：能真正用 Xcode 跑模拟器、看报错、连真机调试，比 CI 盲改效率高得多

## 方案 3：$99/年 Apple Developer Program（长期正式用）

- 签名有效期 1 年，可上 TestFlight 分发给别人测试，不需要每周重装
- 出包方式仍是方案 1 或 2，只是在 CI 里配置证书 + 描述文件（或者直接在云端 Mac 的 Xcode 里 Archive → Export）
- 需要的话告我，我把签名版流水线也加上

---

## 能不能把代码放到 Gitee 上 Build？

**不能。Gitee 只能当代码仓库，不能当 iOS 编译机。**

原因：iOS 编译必须有 Xcode，而 Xcode 只跑在 macOS 上。Gitee Go 流水线提供的构建环境是

- Linux 构建机（Ubuntu / Debian / CentOS 等 Docker 环境）
- Windows 构建机
- 自有主机（把你自己的一台机器接入当执行器）

**没有 macOS 构建机**，所以 `xcodebuild` 在 Gitee 上根本跑不起来。换成 Gitee 不是"省钱"，是"编译这一步消失"。

### 推荐做法：双远端（一套代码，推两处）

```
你的 Windows 本地仓库（D:\Project\spring-ai-agent\pfc-trainer）
   ├─ push → GitHub   ← 负责编译 IPA（macOS runner）
   └─ push → Gitee    ← 国内访问快 / 备份 / 防 GitHub 抽风
```

一套代码，两边内容完全一致，不需要维护两份。

一次性配置：

```bat
git remote add origin https://github.com/LiuHui66/Actions-ds.git
git remote add gitee  https://gitee.com/<用户名>/<仓库名>.git
```

之后每次改完代码：

```bat
scripts\push-all.bat "v1.0.1 调整点错反馈"          REM 只推 GitHub
git push gitee main                                REM 需要备份时再推 Gitee
```

### 其它几条路（了解即可，别急着走）

| 方案 | 现实成本 |
|---|---|
| Gitee 主仓 + GitHub 仅编译 | 需要 Gitee Go 用 webhook 调 GitHub `repository_dispatch` 接口，能通但要自己维护 `repo` + `PAT` 两个密钥，性价比低 |
| Gitee Go 接入「自有主机」跑 macOS | 前提是你确实有一台 Mac 并保持开机 —— 那不如直接用这台 Mac 编译 |
| 国内云厂商的 macOS CI（阿里云效 / 腾讯 CODING 等） | 部分产品提供按需 macOS 构建节点，但通常要企业认证 + 按量付费，个人练习场景不划算，具体以各家当前文档为准 |
| 直接用 MacinCloud 之类云 Mac 租用 | 按小时计费，适合偶发构建，长期不如 GitHub Actions 免费额度 |
