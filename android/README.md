# PFC Trainer · Android

前额叶训练的安卓版，功能与 iOS 版一一对应。Kotlin + Jetpack Compose，单 Activity。

## 构建

### 交给 CI（推荐，不用装 Android Studio）

push 到 main 后，`.github/workflows/android-apk.yml` 会自动：

1. 装 JDK 17 + Android SDK + Gradle 8.7
2. `gradle assembleDebug`
3. 把 APK 发布到 Release：`PFC-android-<版本>-<构建号>.apk`

### 本地构建

```bat
cd android
gradle assembleDebug
```

产物：`app\build\outputs\apk\debug\app-debug.apk`

或者用 Android Studio 直接打开 `android/` 目录 → Run。

> 仓库没有入库 `gradle-wrapper.jar`（二进制不便管理），
> 本地需要 Gradle 8.7+，或用 Android Studio 自带的。

## 安装

APK 传到手机 → 点击安装 → 允许「安装未知来源应用」。
debug 签名自用足够，**没有 iOS 那种 7 天有效期**。

## 技术要点

| 项 | 值 |
|---|---|
| applicationId | `com.liuhui66.pfc`（与 iOS Bundle ID 相同） |
| minSdk / targetSdk / compileSdk | 24 / 34 / 34 |
| AGP / Kotlin / Gradle | 8.5.2 / 2.0.20 / 8.7 |
| Compose BOM | 2024.09.02 |
| 版本号 | 读仓库根目录 `VERSION`，映射成 versionName / versionCode |

## 结构

```
app/src/main/java/com/liuhui66/pfc/
├── MainActivity.kt          # NavHost：home → train/{difficulty} → endless
├── model/
│   ├── BoardLayout.kt       # 不规则拼块生成（与 iOS BoardLayout.swift 同一套算法）
│   ├── BoardCell.kt
│   ├── Difficulty.kt        # 10 / 20 / 30
│   ├── SessionResult.kt     # 成绩 + S~D 评级
│   ├── EndlessRules.kt      # 100 秒 / 10 个起 / 每轮 +5
│   └── EndlessResult.kt
├── data/
│   ├── BestTimeStorage.kt   # SharedPreferences
│   └── EndlessRecordStorage.kt
├── ui/
│   ├── HomeScreen.kt
│   ├── TrainingScreen.kt
│   ├── EndlessScreen.kt
│   ├── NumberBoard.kt       # Canvas 绘制多边形 + 射线法命中
│   ├── ResultDialog.kt
│   └── theme/Theme.kt
└── util/
    ├── TimeFormat.kt
    └── Haptics.kt
```

## 注意事项

- **没有 INTERNET 权限**：本 App 纯本地，无检查更新、无下载、无统计上报
- 拼块算法与 iOS 完全一致（撒点 → 3 轮 Lloyd 松弛 → Voronoi 半平面裁剪 → 圆形裁剪），
  改算法时请同步改 iOS 的 `PFC/Support/BoardLayout.swift`
- 数值精度：Kotlin 侧用 `Float`（对应 iOS 的 `CGFloat`），阈值做了相应调整
