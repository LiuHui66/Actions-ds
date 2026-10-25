# 前额叶训练 · PFC Trainer

按顺序找数字的注意力训练 App（舒尔特方格式，数字排在不规则拼块上）。
**iOS（SwiftUI）与 Android（Kotlin + Jetpack Compose）双端，功能与规则完全一致。**

- 不联网、不收集数据、没有账号体系
- 两端共用同一份 `VERSION` 文件作为版本号唯一来源
- 所有构建都由 GitHub Actions 完成（iOS 用 macOS runner，Android 用 ubuntu runner）

---

## 一、功能与规则

### 经典模式

| 难度 | 数字个数 | 说明 |
|---|---|---|
| 初级 | 10 | 1 → 10 |
| 中级 | 20 | 1 → 20 |
| 高级 | 30 | 1 → 30 |

流程：选难度 → 生成一套**不规则拼块**（Voronoi + Lloyd 松弛，每轮形状不同）→
**5 秒倒计时**（遮罩期间不可点）→ 自动开始计时 → 按 1 → N 顺序点选。

- 点对：拼块变淡缩小、轻震动
- 点错（点了更大的数字）：闪红 + 错误震动 + 失误 +1
- **点中最后一个数字的瞬间冻结用时，约 0.42 秒后自动弹出成绩**（无需点「停止」）
- 成绩：用时、单个平均、失误、S / A / B / C / D 评级、是否新纪录、历史最佳（本地保存）

评级按「平均每个数字耗时」：**S < 1.0s，A < 1.5s，B < 2.2s，C < 3.0s，其余 D**。

### 无限模式

**每一轮都是独立的一关：**

```
第 1 轮：10 个数字（1 → 10），限时 100 秒
   ↓ 清空
第 2 轮：15 个数字（1 → 15），数字重新从 1 开始、板面重画、计时重置回 100 秒
   ↓ 清空
第 3 轮：20 个数字 … 依次 +5
   ↓ 某一轮时间归零
本局结束 → 结算（完成轮数 / 累计个数 / 评级 / 总用时 / 失误）
```

评级按清空轮数：**S ≥ 4 轮，A ≥ 3 轮，B ≥ 2 轮，C ≥ 1 轮，其余 D**。
最高纪录（累计找出多少个数字）单独保存，与三档最佳用时互不影响。

---

## 二、目录结构

```
pfc-trainer/
├── VERSION                       # ★ 唯一的版本号来源（两端共用）
├── CHANGELOG.md                  # 每个版本的改动记录
├── project.yml                   # iOS 工程定义（xcodegen 生成 PFC.xcodeproj）
├── PFC/                          # iOS 源码（SwiftUI）
│   ├── PFCApp.swift
│   ├── DesignSystem/Theme.swift
│   ├── Models/                   # Difficulty / SessionResult / BestTimeStorage / Endless*
│   ├── Support/                  # BoardLayout（拼块算法）/ Haptics
│   └── Views/                    # HomeView / TrainingView / NumberBoard / ResultView / Endless*
├── android/                      # Android 源码（Kotlin + Compose）
│   ├── app/src/main/java/com/liuhui66/pfc/
│   │   ├── MainActivity.kt       # 导航
│   │   ├── model/                # BoardLayout（同一套算法）/ Difficulty / SessionResult / Endless*
│   │   ├── data/                 # SharedPreferences：最佳成绩、无限模式纪录
│   │   ├── ui/                   # HomeScreen / TrainingScreen / EndlessScreen / NumberBoard / ResultDialog
│   │   └── util/                 # TimeFormat / Haptics
│   └── app/build.gradle.kts      # versionName/versionCode 从根目录 VERSION 读取
├── scripts/
│   ├── build-unsigned-ipa.sh     # macOS 上编无签名 IPA
│   └── push-all.bat / .ps1       # 提交 + 推送 + 校验远端 SHA
└── .github/workflows/
    ├── ios-ipa.yml               # push 后自动出 IPA 并发布 Release
    └── android-apk.yml           # push 后自动出 debug APK 并发布 Release
```

---

## 三、版本号管理（重要）

**只改 `VERSION` 一个文件：**

```
MARKETING_VERSION=1.1.0     # 对外版本号
BUILD_NUMBER=8              # 内部构建号，每出一次包 +1
```

- iOS：`build-unsigned-ipa.sh` 把它写进 `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION`，
  产物名 `PFC-<版本>-<构建号>.ipa`
- Android：`app/build.gradle.kts` 读同一个文件，映射成 `versionName` / `versionCode`

> 规则：**只要没真正产出安装包，就不要跳构建号**；成功出包后下次再 +1。
> 每次改完记得在 `CHANGELOG.md` 记一行。

---

## 四、iOS：怎么出包、怎么装

### 出包（Windows 上操作即可）

iOS 编译必须有 Xcode，Xcode 只能跑在 macOS 上 —— 所以**本地 Windows 不产出 IPA**，
由 GitHub Actions 的 macOS runner 编：

```bat
D:\项目路径\pfc-trainer\scripts\push-all.bat "v1.1.0 说明"
```

push 后自动触发 `Build iOS IPA`：
`https://github.com/LiuHui66/Actions-ds/actions` → 约 1 分钟 → Release 里出现
`PFC-1.1.0-8.ipa`（同时 Artifacts 也有一份）。

产物是**无签名 IPA**，安装时由 Sideloadly 用你的 Apple ID 现场签名。

### 安装（Windows + Sideloadly）

前置条件（缺一样都会失败）：

1. **iTunes 必须是 apple.com 的网页版**，不是 Microsoft Store 版
   → <https://www.apple.com/itunes/download/win64>
2. **iCloud 网页版**也要装 → <https://support.apple.com/zh-cn/114050>
3. 装完重启电脑，确认服务在跑：
   ```bat
   sc query "Apple Mobile Device Service"
   ```
   必须看到 `STATE : 4 RUNNING`
4. iPhone 连线 → 解锁 → 点「信任此电脑」

安装步骤：

1. Sideloadly（<https://sideloadly.io>）拖入 `.ipa`
2. Apple ID 填账号，**密码建议填「App 专用密码」**
   （<https://appleid.apple.com> → 登录与安全 → App 专用密码），可跳过 6 位验证码环节
3. 点**一次** Start，全程别重复点（重复点会触发 Apple 限流）
4. 装完：设置 → 隐私与安全性 → **开发者模式** → 开启 → 重启
5. 设置 → 通用 → **VPN 与设备管理** → 信任你的 Apple ID

### ⚠️ 两个绕不开的限制

- **免费 Apple ID 签出的 App 只有 7 天有效期**，到期打不开，需要重新用 Sideloadly 覆盖安装
  （同 Bundle ID 覆盖安装**不丢成绩**，千万别先删图标）
- **App 无法自我升级**：iOS 不允许侧载 App 替换自身。想彻底解决只有两条路：
  SideStore/AltStore 自动续签，或 $99 开发者账号（1 年有效、可走 TestFlight）

### 常见报错速查

| 报错 | 原因 | 处理 |
|---|---|---|
| `GSA returned a non-plist response (HTTP 503)` | ① Apple Mobile Device Service 没启动 ② Apple 对该账号/IP 临时限流 | 先确认服务 RUNNING；再等 30~60 分钟、换手机热点、改用 App 专用密码 |
| `Apple Mobile Device Service` 1053 | 服务启动超时（组件缺失/权限/杀软拦截） | 卸掉所有苹果组件 → 重启 → 装网页版 iTunes + iCloud → 重启 |
| `SEC_E_UNTRUSTED_ROOT` / `self signed certificate` | 系统缺 Apple 根证书 | 从 <https://www.apple.com/certificateauthority/> 下 `AppleRootCA-G3.cer`，装到「本地计算机 → 受信任的根证书颁发机构」 |
| `Could not find device` | 驱动没起来 | `services.msc` 启动 Apple Mobile Device Service |

---

## 五、Android：怎么出包、怎么装

### 出包（同样交给 CI）

```bat
scripts\push-all.bat "v1.1.0 说明"
```

`Build Android APK` 会自动跑：JDK 17 + Android SDK + Gradle 8.7 → `assembleDebug`
→ Release 里出现 `PFC-android-1.1.0-8.apk`。

### 安装

把 APK 传到手机（微信文件传输、数据线、网盘都行）→ 点击安装 →
首次会提示「允许安装未知来源应用」→ 允许即可。

**安卓侧载没有 iOS 那种 7 天限制，装上就一直能用。**

### 本地构建（可选，需要装 Android Studio）

```bat
cd android
gradle assembleDebug
:: 产物：app\build\outputs\apk\debug\app-debug.apk
```

或者直接在 Android Studio 里打开 `android/` 目录，点 Run。

> 仓库里没有放 Gradle Wrapper 的二进制（`gradle-wrapper.jar` 不便入库），
> 所以本地要先装 Gradle 8.7+，或者用 Android Studio 自带的。

---

## 六、常见问题

**Q：能不能上架？**
iOS 需要 $99/年开发者账号 + 审核；中国区还需 APP 备案。Android 国内商店需要软著 + 备案 + 一般要求企业主体。
注意：App 名带「前额叶训练」，上架描述里**不要写「提升智力 / 改善注意力缺陷」这类功效宣称**，
容易按健康类 App 被拒（Lumosity 当年因此被 FTC 罚 200 万美元）。写成「数字搜索注意力练习」最稳。

**Q：为什么 App 里没有「检查更新」？**
1.1.0 起已删除。原因：跳外部下载页属于绕过商店分发，上架审核不允许；
且侧载 App 无法自我替换，提示了也要回电脑重装。

**Q：成绩存在哪？**
iOS：`UserDefaults`（`pfc.bestTimes` / `pfc.endlessBestCleared`）；
Android：`SharedPreferences`（同名 key）。key 两端一致，方便以后做互通。

**Q：桌面端和手机端规则为什么不一致？**
一致。两端共用同一套算法与常量，改规则时记得**两个平台同时改**：
`PFC/Support/BoardLayout.swift` ↔ `model/BoardLayout.kt`，
`PFC/Models/EndlessRules.swift` ↔ `model/EndlessRules.kt`。
