package com.liuhui66.pfc.ui

import android.os.SystemClock
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableDoubleStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.liuhui66.pfc.data.BestTimeStorage
import com.liuhui66.pfc.model.BoardCell
import com.liuhui66.pfc.model.BoardLayout
import com.liuhui66.pfc.model.Difficulty
import com.liuhui66.pfc.model.SessionResult
import com.liuhui66.pfc.ui.theme.PfcScreenBackground
import com.liuhui66.pfc.util.TimeFormat
import com.liuhui66.pfc.util.rememberHaptics
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.random.Random

private enum class Phase { COUNTDOWN, RUNNING, STOPPED }

/**
 * 训练页：5 秒倒计时 → 开始计时 → 顺序点完不规则拼块上的数字 → 自动停止计时并结算
 *
 * 与 iOS 版行为一致：点中最后一个数字的瞬间冻结用时，
 * 约 0.42 秒后自动弹出成绩面板，不需要用户再点「停止」。
 */
@Composable
fun TrainingScreen(difficulty: Difficulty, onExit: () -> Unit) {
    val context = LocalContext.current
    val haptics = rememberHaptics()
    val scope = rememberCoroutineScope()
    val total = difficulty.numberCount

    var cells by remember { mutableStateOf<List<BoardCell>>(emptyList()) }
    var nextExpected by remember { mutableIntStateOf(1) }
    var runId by remember { mutableIntStateOf(0) }
    var phase by remember { mutableStateOf(Phase.COUNTDOWN) }
    var countdown by remember { mutableIntStateOf(5) }
    var startedAt by remember { mutableStateOf<Long?>(null) }
    var elapsed by remember { mutableDoubleStateOf(0.0) }
    var mistakes by remember { mutableIntStateOf(0) }
    var flashing by remember { mutableStateOf<Int?>(null) }
    var isFinishing by remember { mutableStateOf(false) }
    var result by remember { mutableStateOf<SessionResult?>(null) }

    val foundCount = (nextExpected - 1).coerceIn(0, total)
    val remaining = (total - foundCount).coerceAtLeast(0)

    // 全部找到 → 立刻冻结用时 → 短暂过渡后弹出成绩
    fun finishAutomatically() {
        if (phase != Phase.RUNNING) return

        startedAt?.let { elapsed = (SystemClock.elapsedRealtime() - it) / 1000.0 }
        val finalDuration = elapsed
        val capturedRunId = runId

        phase = Phase.STOPPED
        isFinishing = true
        haptics.success()

        scope.launch {
            delay(420)
            // 期间可能点了「重新开始」或退出，用 runId 判断是否仍是同一轮
            if (runId != capturedRunId || !isFinishing) return@launch

            val isNewRecord = BestTimeStorage.submit(context, finalDuration, difficulty)
            result = SessionResult(
                difficulty = difficulty,
                duration = finalDuration,
                mistakes = mistakes,
                isNewRecord = isNewRecord
            )
        }
    }

    fun handleTap(number: Int) {
        if (phase != Phase.RUNNING || isFinishing) return

        when {
            number == nextExpected -> {
                nextExpected += 1
                if (nextExpected > total) {
                    finishAutomatically()
                } else {
                    haptics.light()
                }
            }

            number > nextExpected -> {
                // 点错了：记一次失误并闪红提示
                mistakes += 1
                haptics.error()
                flashing = number
                scope.launch {
                    delay(320)
                    if (flashing == number) flashing = null
                }
            }
            // number < nextExpected：已经找过，忽略
        }
    }

    fun restart() {
        phase = Phase.COUNTDOWN
        result = null
        runId += 1
    }

    LaunchedEffect(runId) {
        // 重置本轮状态
        cells = BoardLayout.make(total, Random.nextLong(1L, Long.MAX_VALUE))
        nextExpected = 1
        mistakes = 0
        flashing = null
        elapsed = 0.0
        startedAt = null
        isFinishing = false
        result = null
        countdown = 5
        phase = Phase.COUNTDOWN

        // 5 秒倒计时：5 → 4 → 3 → 2 → 1
        for (value in 5 downTo 1) {
            countdown = value
            delay(1000)
        }

        // 开始计时
        startedAt = SystemClock.elapsedRealtime()
        elapsed = 0.0
        haptics.medium()
        phase = Phase.RUNNING

        // 计时刷新（约 30fps）；全部找到后 phase 变为 STOPPED，循环自动结束
        while (phase == Phase.RUNNING) {
            startedAt?.let { elapsed = (SystemClock.elapsedRealtime() - it) / 1000.0 }
            delay(33)
        }
    }

    Box(Modifier.fillMaxSize()) {
        PfcScreenBackground()

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(bottom = 20.dp)
        ) {
            TopBar(
                title = difficulty.title,
                subtitle = difficulty.subtitle,
                onExit = onExit,
                onRestart = { restart() }
            )

            StatusPanel(
                elapsed = elapsed,
                foundCount = foundCount,
                total = total,
                mistakes = mistakes,
                tint = difficulty.tint,
                isRunning = phase == Phase.RUNNING
            )

            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f)
                    .padding(horizontal = 12.dp),
                contentAlignment = Alignment.Center
            ) {
                NumberBoard(
                    cells = cells,
                    nextExpected = nextExpected,
                    tint = difficulty.tint,
                    flashingNumber = flashing,
                    modifier = Modifier.fillMaxWidth(),
                    onTap = { handleTap(it) }
                )
            }

            FooterStatus(
                isFinishing = isFinishing,
                remaining = remaining,
                modifier = Modifier.padding(horizontal = 20.dp)
            )
        }

        if (phase == Phase.COUNTDOWN) {
            CountdownOverlay(
                countdown = countdown,
                tint = difficulty.tint,
                title = "准备好",
                detail = "按 1 → $total 的顺序点选数字",
                note = "全部找到后自动停止计时"
            )
        }
    }

    result?.let { value ->
        TrainingResultDialog(
            result = value,
            onRetry = {
                result = null
                restart()
            },
            onExit = {
                result = null
                onExit()
            }
        )
    }
}

// MARK: - 子视图

@Composable
private fun TopBar(
    title: String,
    subtitle: String,
    onExit: () -> Unit,
    onRestart: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp)
            .padding(top = 8.dp)
    ) {
        Column(
            modifier = Modifier.align(Alignment.Center),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = title,
                color = Color.White,
                fontSize = 16.sp,
                fontWeight = FontWeight.SemiBold
            )
            Text(
                text = subtitle,
                color = Color.White.copy(alpha = 0.55f),
                fontSize = 11.sp
            )
        }

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            CircleIconButton(glyph = "✕", onClick = onExit)
            CircleIconButton(glyph = "↻", onClick = onRestart)
        }
    }
}

@Composable
private fun CircleIconButton(glyph: String, onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .size(36.dp)
            .background(Color.White.copy(alpha = 0.08f), CircleShape)
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        Text(text = glyph, color = Color.White.copy(alpha = 0.7f), fontSize = 15.sp)
    }
}

@Composable
private fun StatusPanel(
    elapsed: Double,
    foundCount: Int,
    total: Int,
    mistakes: Int,
    tint: Color,
    isRunning: Boolean
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = 14.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Row(verticalAlignment = Alignment.Bottom) {
            Text(
                text = TimeFormat.plain(elapsed),
                color = if (isRunning) Color.White else Color.White.copy(alpha = 0.85f),
                fontSize = 52.sp,
                fontWeight = FontWeight.Bold
            )
            Text(
                text = "秒",
                color = Color.White.copy(alpha = 0.62f),
                fontSize = 17.sp,
                modifier = Modifier.padding(start = 6.dp, bottom = 8.dp)
            )
        }

        Column(
            modifier = Modifier.padding(horizontal = 40.dp),
            verticalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            LinearProgressIndicator(
                progress = { if (total > 0) foundCount.toFloat() / total else 0f },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(5.dp),
                color = tint,
                trackColor = Color.White.copy(alpha = 0.10f)
            )

            Row(modifier = Modifier.fillMaxWidth()) {
                Text(
                    text = "已找 $foundCount/$total",
                    color = Color.White.copy(alpha = 0.62f),
                    fontSize = 12.sp
                )
                Spacer(Modifier.weight(1f))
                Text(
                    text = if (mistakes > 0) "失误 $mistakes" else "零失误",
                    color = if (mistakes > 0) Color(0xFFFF9F45) else Color.White.copy(alpha = 0.62f),
                    fontSize = 12.sp
                )
            }
        }
    }
}

/** 底部状态条（只展示，不可点击）：全部找到后自动停表，无需手动操作 */
@Composable
private fun FooterStatus(isFinishing: Boolean, remaining: Int, modifier: Modifier = Modifier) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .height(56.dp)
            .background(
                color = if (isFinishing) Color(0xFF3DDC97).copy(alpha = 0.20f)
                else Color.White.copy(alpha = 0.06f),
                shape = RoundedCornerShape(18.dp)
            ),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = if (isFinishing) "✓ 全部找到 · 正在结算" else "⏳ 还剩 $remaining 个数字",
            color = if (isFinishing) Color(0xFF3DDC97) else Color.White.copy(alpha = 0.55f),
            fontSize = 17.sp,
            fontWeight = FontWeight.SemiBold
        )
    }
}

/** 倒计时遮罩（经典模式与无限模式共用） */
@Composable
internal fun CountdownOverlay(
    countdown: Int,
    tint: Color,
    title: String,
    detail: String,
    note: String
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF0A0D14).copy(alpha = 0.90f)),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(
                text = title,
                color = Color.White.copy(alpha = 0.62f),
                fontSize = 17.sp
            )
            Text(
                text = "$countdown",
                color = tint,
                fontSize = 128.sp,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center
            )
            Text(
                text = detail,
                color = Color.White.copy(alpha = 0.62f),
                fontSize = 13.sp
            )
            Text(
                text = note,
                color = Color.White.copy(alpha = 0.45f),
                fontSize = 11.sp
            )
        }
    }
}
