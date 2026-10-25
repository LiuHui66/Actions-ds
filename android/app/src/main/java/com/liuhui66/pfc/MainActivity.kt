package com.liuhui66.pfc

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.systemBarsPadding
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.liuhui66.pfc.model.Difficulty
import com.liuhui66.pfc.ui.EndlessScreen
import com.liuhui66.pfc.ui.HomeScreen
import com.liuhui66.pfc.ui.TrainingScreen
import com.liuhui66.pfc.ui.theme.PfcTheme

/**
 * 安卓版入口：与 iOS 版一一对应
 *
 * home → 三个难度（初级 10 / 中级 20 / 高级 30）
 *      → 无限模式（每轮 100 秒，10 个起，清空一轮 +5 且数字与时间全部重置）
 *
 * 本 App 不联网：Manifest 里没有 INTERNET 权限，也没有任何检查更新 / 下载逻辑。
 */
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            PfcTheme {
                AppNav()
            }
        }
    }
}

@Composable
private fun AppNav() {
    val navController = rememberNavController()

    Box(
        modifier = Modifier
            .fillMaxSize()
            .systemBarsPadding()
    ) {
        NavHost(navController = navController, startDestination = "home") {
            composable("home") {
                HomeScreen(
                    onOpenDifficulty = { difficulty ->
                        navController.navigate("train/${difficulty.id}")
                    },
                    onOpenEndless = { navController.navigate("endless") }
                )
            }

            composable("train/{difficulty}") { entry ->
                val id = entry.arguments?.getString("difficulty")
                val difficulty = Difficulty.entries.firstOrNull { it.id == id }
                    ?: Difficulty.BEGINNER
                TrainingScreen(
                    difficulty = difficulty,
                    onExit = { navController.popBackStack() }
                )
            }

            composable("endless") {
                EndlessScreen(onExit = { navController.popBackStack() })
            }
        }
    }
}
