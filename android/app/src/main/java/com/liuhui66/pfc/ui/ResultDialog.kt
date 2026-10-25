package com.liuhui66.pfc.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.liuhui66.pfc.model.EndlessResult
import com.liuhui66.pfc.model.SessionResult
import com.liuhui66.pfc.ui.theme.PfcBackground
import com.liuhui66.pfc.ui.theme.PfcMint
import com.liuhui66.pfc.ui.theme.PfcPurple
import com.liuhui66.pfc.util.TimeFormat
import java.util.Locale

/** 经典模式（初级 / 中级 / 高级）的成绩面板 */
@Composable
fun TrainingResultDialog(
    result: SessionResult,
    onRetry: () -> Unit,
    onExit: () -> Unit
) {
    ResultPanel {
        Text(
            text = "${result.difficulty.title} · 本轮成绩",
            color = Color.White.copy(alpha = 0.62f),
            fontSize = 14.sp
        )

        Row(verticalAlignment = Alignment.Bottom) {
            Text(
                text = TimeFormat.clock(result.duration),
                color = Color.White,
                fontSize = 56.sp,
                fontWeight = FontWeight.Bold
            )
            Text(
                text = "秒",
                color = Color.White.copy(alpha = 0.62f),
                fontSize = 17.sp,
                modifier = Modifier.padding(start = 6.dp, bottom = 8.dp)
            )
        }

        if (result.isNewRecord) {
            RecordChip(tint = PfcMint, text = "新纪录")
        }

        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            StatCard("评级", result.grade.title, result.grade.color, Modifier.weight(1f))
            StatCard(
                title = "单个平均",
                value = String.format(Locale.US, "%.2fs", result.averagePerNumber),
                tint = Color.White,
                modifier = Modifier.weight(1f)
            )
            StatCard(
                title = "失误",
                value = "${result.mistakes}",
                tint = if (result.mistakes == 0) Color(0xFF4CD964) else Color(0xFFFF9F45),
                modifier = Modifier.weight(1f)
            )
        }

        Text(
            text = result.grade.comment,
            color = Color.White.copy(alpha = 0.62f),
            fontSize = 13.sp,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth()
        )

        ActionButton(text = "再来一次", accent = true, tint = PfcMint, onClick = onRetry)
        ActionButton(text = "返回首页", accent = false, tint = Color.White, onClick = onExit)
    }
}

/** 无限模式的成绩面板 */
@Composable
fun EndlessResultDialog(
    result: EndlessResult,
    best: Int,
    onRetry: () -> Unit,
    onExit: () -> Unit
) {
    ResultPanel {
        Text(
            text = "无限模式 · 本局成绩",
            color = Color.White.copy(alpha = 0.62f),
            fontSize = 14.sp
        )

        Row(verticalAlignment = Alignment.Bottom) {
            Text(
                text = "${result.roundsCompleted}",
                color = Color.White,
                fontSize = 56.sp,
                fontWeight = FontWeight.Bold
            )
            Text(
                text = "轮",
                color = Color.White.copy(alpha = 0.62f),
                fontSize = 17.sp,
                modifier = Modifier.padding(start = 6.dp, bottom = 8.dp)
            )
        }

        Text(
            text = "共找出 ${result.clearedCount} 个数字",
            color = Color.White.copy(alpha = 0.62f),
            fontSize = 12.sp
        )

        if (result.isNewRecord) {
            RecordChip(tint = PfcPurple, text = "新纪录")
        }

        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            StatCard("评级", result.grade.title, result.grade.color, Modifier.weight(1f))
            StatCard(
                title = "总用时",
                value = String.format(Locale.US, "%.0f", result.elapsed),
                tint = PfcPurple,
                modifier = Modifier.weight(1f)
            )
            StatCard(
                title = "失误",
                value = "${result.mistakes}",
                tint = if (result.mistakes == 0) Color(0xFF4CD964) else Color(0xFFFF9F45),
                modifier = Modifier.weight(1f)
            )
        }

        Text(
            text = String.format(
                Locale.US,
                "平均 %.1f 秒/个 · 停在 %d 个的板面",
                result.secondsPerNumber,
                result.boardTotal
            ),
            color = Color.White.copy(alpha = 0.62f),
            fontSize = 12.sp,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth()
        )

        if (best > 0) {
            Text(
                text = "最高纪录 $best 个",
                color = PfcPurple.copy(alpha = 0.9f),
                fontSize = 12.sp,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth()
            )
        }

        Text(
            text = result.grade.comment,
            color = Color.White.copy(alpha = 0.62f),
            fontSize = 13.sp,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth()
        )

        ActionButton(text = "再来一次", accent = true, tint = PfcPurple, onClick = onRetry)
        ActionButton(text = "返回首页", accent = false, tint = Color.White, onClick = onExit)
    }
}

// MARK: - 组件

@Composable
private fun ResultPanel(content: @Composable () -> Unit) {
    Dialog(
        onDismissRequest = { /* 必须点按钮才能关闭，避免误触丢掉成绩 */ },
        properties = DialogProperties(usePlatformDefaultWidth = false)
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 20.dp),
            contentAlignment = Alignment.Center
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(PfcBackground, RoundedCornerShape(26.dp))
                    .border(1.dp, Color.White.copy(alpha = 0.10f), RoundedCornerShape(26.dp))
                    .padding(22.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(14.dp)
            ) {
                content()
            }
        }
    }
}

@Composable
private fun RecordChip(tint: Color, text: String) {
    Text(
        text = "✦ $text",
        color = Color.Black.copy(alpha = 0.85f),
        fontSize = 13.sp,
        fontWeight = FontWeight.SemiBold,
        modifier = Modifier
            .background(tint, RoundedCornerShape(50))
            .padding(horizontal = 14.dp, vertical = 7.dp)
    )
}

@Composable
private fun StatCard(
    title: String,
    value: String,
    tint: Color,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .background(Color.White.copy(alpha = 0.06f), RoundedCornerShape(16.dp))
            .padding(vertical = 14.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        Text(text = title, color = Color.White.copy(alpha = 0.62f), fontSize = 12.sp)
        Text(text = value, color = tint, fontSize = 20.sp, fontWeight = FontWeight.Bold)
    }
}

@Composable
private fun ActionButton(
    text: String,
    accent: Boolean,
    tint: Color,
    onClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(54.dp)
            .background(
                color = if (accent) tint else Color.White.copy(alpha = 0.08f),
                shape = RoundedCornerShape(18.dp)
            )
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = text,
            color = if (accent) Color.Black.copy(alpha = 0.85f) else Color.White,
            fontSize = 17.sp,
            fontWeight = FontWeight.SemiBold
        )
    }
}
