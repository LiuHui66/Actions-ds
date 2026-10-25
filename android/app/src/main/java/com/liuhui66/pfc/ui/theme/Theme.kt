package com.liuhui66.pfc.ui.theme

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color

/** 与 iOS 版一致的配色（Theme.swift） */
val PfcBackground = Color(0xFF0A0D14)
val PfcMint = Color(0xFF3DDC97)
val PfcCyan = Color(0xFF35D6E8)
val PfcOrange = Color(0xFFFF9F45)
val PfcPurple = Color(0xFFB388FF)
val PfcIndigo = Color(0xFF5C6BC0)

private val PfcColorScheme = darkColorScheme(
    primary = PfcMint,
    secondary = PfcCyan,
    background = PfcBackground,
    surface = PfcBackground,
    onPrimary = Color.Black,
    onBackground = Color.White,
    onSurface = Color.White
)

@Composable
fun PfcTheme(content: @Composable () -> Unit) {
    MaterialTheme(colorScheme = PfcColorScheme, content = content)
}

/**
 * 统一的深色训练背景（对应 iOS 的 PFCScreenBackground）
 * 左上薄荷色光晕 + 右下靛蓝光晕，用两个径向渐变叠在深色底上。
 */
@Composable
fun PfcScreenBackground(modifier: Modifier = Modifier) {
    Box(
        modifier
            .fillMaxSize()
            .background(PfcBackground)
            .drawBehind {
                val maxSide = maxOf(size.width, size.height)
                drawCircle(
                    brush = Brush.radialGradient(
                        colors = listOf(PfcMint.copy(alpha = 0.16f), Color.Transparent),
                        center = Offset.Zero,
                        radius = maxSide * 0.62f
                    ),
                    radius = maxSide * 0.62f,
                    center = Offset.Zero
                )
                drawCircle(
                    brush = Brush.radialGradient(
                        colors = listOf(PfcIndigo.copy(alpha = 0.30f), Color.Transparent),
                        center = Offset(size.width, size.height),
                        radius = maxSide * 0.72f
                    ),
                    radius = maxSide * 0.72f,
                    center = Offset(size.width, size.height)
                )
            }
    )
}
