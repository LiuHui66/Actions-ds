package com.liuhui66.pfc.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.liuhui66.pfc.data.BestTimeStorage
import com.liuhui66.pfc.data.EndlessRecordStorage
import com.liuhui66.pfc.model.Difficulty
import com.liuhui66.pfc.model.EndlessRules
import com.liuhui66.pfc.ui.theme.PfcPurple
import com.liuhui66.pfc.ui.theme.PfcScreenBackground
import com.liuhui66.pfc.util.TimeFormat

/** 首页：选择模式（三个难度 + 无限模式） */
@Composable
fun HomeScreen(
    onOpenDifficulty: (Difficulty) -> Unit,
    onOpenEndless: () -> Unit
) {
    Box(Modifier.fillMaxSize()) {
        PfcScreenBackground()

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp)
                .padding(top = 8.dp, bottom = 40.dp),
            verticalArrangement = Arrangement.spacedBy(22.dp)
        ) {
            Header()

            Difficulty.entries.forEach { difficulty ->
                DifficultyCard(
                    difficulty = difficulty,
                    onClick = { onOpenDifficulty(difficulty) }
                )
            }

            EndlessCard(onClick = onOpenEndless)
        }
    }
}

@Composable
private fun Header() {
    Column(
        modifier = Modifier.padding(bottom = 4.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Text(
            text = "前额叶训练",
            color = Color.White,
            fontSize = 34.sp,
            fontWeight = FontWeight.Bold
        )
        Text(
            text = "按顺序找数字，训练注意力、视觉搜索与工作记忆。",
            color = Color.White.copy(alpha = 0.62f),
            fontSize = 14.sp
        )
    }
}

@Composable
private fun DifficultyCard(difficulty: Difficulty, onClick: () -> Unit) {
    val context = LocalContext.current
    // 每次回到首页都会重新读一遍，训练结束后最佳成绩会自动更新
    val best = remember(difficulty) { BestTimeStorage.best(context, difficulty) }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(Color.White.copy(alpha = 0.06f), RoundedCornerShape(22.dp))
            .border(1.dp, Color.White.copy(alpha = 0.09f), RoundedCornerShape(22.dp))
            .clickable(onClick = onClick)
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        IconBadge(text = emojiFor(difficulty), tint = difficulty.tint)

        Spacer(Modifier.width(16.dp))

        Column(
            modifier = Modifier.weight(1f),
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = difficulty.title,
                    color = Color.White,
                    fontSize = 20.sp,
                    fontWeight = FontWeight.SemiBold
                )
                Spacer(Modifier.width(8.dp))
                CountBadge(text = difficulty.numberCount.toString(), tint = difficulty.tint)
            }

            Text(
                text = difficulty.subtitle,
                color = Color.White.copy(alpha = 0.62f),
                fontSize = 13.sp
            )

            if (best != null) {
                Text(
                    text = "最佳成绩 ${TimeFormat.best(best)}",
                    color = difficulty.tint.copy(alpha = 0.9f),
                    fontSize = 12.sp
                )
            } else {
                Text(
                    text = difficulty.hint,
                    color = Color.White.copy(alpha = 0.5f),
                    fontSize = 12.sp
                )
            }
        }

        Text(
            text = "›",
            color = Color.White.copy(alpha = 0.35f),
            fontSize = 20.sp,
            fontWeight = FontWeight.SemiBold
        )
    }
}

@Composable
private fun EndlessCard(onClick: () -> Unit) {
    val context = LocalContext.current
    val best = remember { EndlessRecordStorage.best(context) }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(PfcPurple.copy(alpha = 0.10f), RoundedCornerShape(22.dp))
            .border(1.dp, PfcPurple.copy(alpha = 0.30f), RoundedCornerShape(22.dp))
            .clickable(onClick = onClick)
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        IconBadge(text = "∞", tint = PfcPurple)

        Spacer(Modifier.width(16.dp))

        Column(
            modifier = Modifier.weight(1f),
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = "无限模式",
                    color = Color.White,
                    fontSize = 20.sp,
                    fontWeight = FontWeight.SemiBold
                )
                Spacer(Modifier.width(8.dp))
                CountBadge(text = "NEW", tint = PfcPurple)
            }

            Text(
                text = EndlessRules.summary,
                color = Color.White.copy(alpha = 0.62f),
                fontSize = 13.sp
            )

            if (best > 0) {
                Text(
                    text = "最高纪录 $best 个",
                    color = PfcPurple.copy(alpha = 0.95f),
                    fontSize = 12.sp
                )
            } else {
                Text(
                    text = "时间归零自动结算，看你能清空几轮",
                    color = Color.White.copy(alpha = 0.5f),
                    fontSize = 12.sp
                )
            }
        }

        Text(
            text = "›",
            color = Color.White.copy(alpha = 0.35f),
            fontSize = 20.sp,
            fontWeight = FontWeight.SemiBold
        )
    }
}

@Composable
private fun IconBadge(text: String, tint: Color) {
    Box(
        modifier = Modifier
            .size(56.dp)
            .background(tint.copy(alpha = 0.16f), RoundedCornerShape(16.dp)),
        contentAlignment = Alignment.Center
    ) {
        Text(text = text, color = tint, fontSize = 24.sp, fontWeight = FontWeight.Bold)
    }
}

@Composable
private fun CountBadge(text: String, tint: Color) {
    Text(
        text = text,
        color = tint,
        fontSize = 11.sp,
        fontWeight = FontWeight.Bold,
        modifier = Modifier
            .background(tint.copy(alpha = 0.16f), RoundedCornerShape(50))
            .padding(horizontal = 8.dp, vertical = 3.dp)
    )
}

private fun emojiFor(difficulty: Difficulty): String = when (difficulty) {
    Difficulty.BEGINNER -> "🌱"
    Difficulty.INTERMEDIATE -> "🔥"
    Difficulty.ADVANCED -> "⚡"
}
