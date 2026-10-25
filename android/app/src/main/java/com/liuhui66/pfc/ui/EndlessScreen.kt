package com.liuhui66.pfc.ui

import android.os.SystemClock
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
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.liuhui66.pfc.data.EndlessRecordStorage
import com.liuhui66.pfc.model.BoardCell
import com.liuhui66.pfc.model.BoardLayout
import com.liuhui66.pfc.model.EndlessResult
import com.liuhui66.pfc.model.EndlessRules
import com.liuhui66.pfc.ui.theme.PfcPurple
import com.liuhui66.pfc.ui.theme.PfcScreenBackground
import com.liuhui66.pfc.util.rememberHaptics
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.util.Locale
import kotlin.math.max
import kotlin.random.Random

/** 无限模式自己的阶段枚举（与 TrainingScreen 的 Phase 分开，避免重名） */
private enum class EndlessPhase { COUNTDOWN, RUNNING, STOPPED }

/**
 * 无限模式：每一轮都是独立的一关
 *
 * 规则：
 * - 第 1 轮 10 个数字（1 → 10），限时 100 秒，开局有 5 秒倒计时
 * - 清空这一轮 → 下一轮 15 个数字，数字从 1 重新开始、板面全部重置、倒计时重置回 100 秒
 * - 依次 10 → 15 → 20 → 25 …，直到某一轮时间归零
 * - 时间归零自动结算
 */
@Composable
fun EndlessScreen(onExit: () -> Unit) {
    val context = LocalContext.current
    val haptics = rememberHaptics()
    val scope = rememberCoroutineScope()

    var cells by remember { mutableStateOf<List<BoardCell>>(emptyList()) }
    var round by remember { mutableIntStateOf(1) }
    var boardTotal by remember { mutableIntStateOf(EndlessRules.INITIAL_COUNT) }
    var nextExpected by remember { mutableIntStateOf(1) }
    var clearedInRound by remember { mutableIntStateOf(0) }
    var clearedTotal by remember { mutableIntStateOf(0) }
    var roundsCompleted by remember { mutableIntStateOf(0) }
    var mistakes by remember { mutableIntStateOf(0) }
    var flashing by remember { mutableStateOf<Int?>(null) }

    var phase by remember { mutableStateOf(EndlessPhase.COUNTDOWN) }
    var countdown by remember { mutableIntStateOf(EndlessRules.COUNTDOWN_SECONDS) }

    var roundStartedAt by remember { mutableStateOf<Long?>(null) }
    var elapsedBefore by remember { mutableDoubleStateOf(0.0) }
    var roundRemaining by remember { mutableDoubleStateOf(EndlessRules.ROUND_DURATION) }

    var roundFlash by remember { mutableStateOf<String?>(null) }

    var result by remember { mutableStateOf<EndlessResult?>(null) }
    var bestRecord by remember { mutableIntStateOf(0) }
    var runId by remember { mutableIntStateOf(0) }

    val remainingOnBoard = (boardTotal - clearedInRound).coerceAtLeast(0)

    fun showRoundFlash(text: String) {
        roundFlash = text
        scope.launch {
            delay(1000)
            if (roundFlash == text) roundFlash = null
        }
    }

    /** 清空这一轮 → 进入下一轮：数字从 1 重置、板面重画、倒计时重置 */
    fun finishRound() {
        if (phase != EndlessPhase.RUNNING) return

        roundStartedAt?.let {
            elapsedBefore += (SystemClock.elapsedRealtime() - it) / 1000.0
        }
        roundsCompleted += 1
        round += 1

        val newTotal = EndlessRules.roundSize(round)
        haptics.success()

        boardTotal = newTotal
        nextExpected = 1
        clearedInRound = 0
        roundRemaining = EndlessRules.ROUND_DURATION
        cells = BoardLayout.make(newTotal, Random.nextLong(1L, Long.MAX_VALUE))

        // 新一轮从此刻重新计时
        roundStartedAt = SystemClock.elapsedRealtime()

        showRoundFlash("第 $round 轮 · $newTotal 个")
    }

    /** 时间耗尽 → 冻结成绩 → 弹出结算 */
    fun finish() {
        if (phase != EndlessPhase.RUNNING) return

        val finalCleared = clearedTotal
        val finalRounds = roundsCompleted
        val finalMistakes = mistakes
        val finalBoard = boardTotal
        val finalElapsed = elapsedBefore + max(EndlessRules.ROUND_DURATION - roundRemaining, 0.0)
        val capturedRunId = runId

        phase = EndlessPhase.STOPPED
        roundRemaining = 0.0
        haptics.medium()

        scope.launch {
            delay(360)
            if (runId != capturedRunId) return@launch

            val isNewRecord = EndlessRecordStorage.submit(context, finalCleared)
            bestRecord = EndlessRecordStorage.best(context)
            result = EndlessResult(
                clearedCount = finalCleared,
                roundsCompleted = finalRounds,
                mistakes = finalMistakes,
                boardTotal = finalBoard,
                elapsed = finalElapsed,
                isNewRecord = isNewRecord
            )
        }
    }

    fun handleTap(number: Int) {
        if (phase != EndlessPhase.RUNNING) return

        // 时间刚好走完的瞬间：直接结算，不再处理这次点击
        if (roundRemaining <= 0) {
            finish()
            return
        }

        when {
            number == nextExpected -> {
                clearedInRound += 1
                clearedTotal += 1
                nextExpected += 1
                haptics.light()

                if (clearedInRound >= boardTotal) finishRound()
            }

            number > nextExpected -> {
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
        phase = EndlessPhase.COUNTDOWN
        result = null
        runId += 1
    }

    LaunchedEffect(runId) {
        // 重置本局状态
        round = 1
        boardTotal = EndlessRules.INITIAL_COUNT
        nextExpected = 1
        clearedInRound = 0
        clearedTotal = 0
        roundsCompleted = 0
        mistakes = 0
        flashing = null
        roundFlash = null
        roundRemaining = EndlessRules.ROUND_DURATION
        elapsedBefore = 0.0
        roundStartedAt = null
        result = null
        countdown = EndlessRules.COUNTDOWN_SECONDS
        phase = EndlessPhase.COUNTDOWN
        cells = BoardLayout.make(boardTotal, Random.nextLong(1L, Long.MAX_VALUE))

        // 5 秒倒计时
        for (value in EndlessRules.COUNTDOWN_SECONDS downTo 1) {
            countdown = value
            delay(1000)
        }

        roundStartedAt = SystemClock.elapsedRealtime()
        roundRemaining = EndlessRules.ROUND_DURATION
        haptics.medium()
        phase = EndlessPhase.RUNNING

        // 倒计时刷新（约 20fps）；时间归零后 phase 变为 STOPPED，循环自动结束
        // 每清空一轮 roundStartedAt 会被重置，倒计时自然回到 100 秒
        while (phase == EndlessPhase.RUNNING) {
            roundStartedAt?.let {
                roundRemaining = max(
                    EndlessRules.ROUND_DURATION - (SystemClock.elapsedRealtime() - it) / 1000.0,
                    0.0
                )
            }
            if (roundRemaining <= 0) {
                finish()
                break
            }
            delay(50)
        }
    }

    Box(Modifier.fillMaxSize()) {
        PfcScreenBackground()

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(bottom = 20.dp)
        ) {
            EndlessTopBar(onExit = onExit, onRestart = { restart() })

            EndlessStatusPanel(
                round = round,
                boardTotal = boardTotal,
                roundRemaining = roundRemaining,
                clearedInRound = clearedInRound,
                clearedTotal = clearedTotal,
                roundsCompleted = roundsCompleted,
                mistakes = mistakes
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
                    tint = PfcPurple,
                    flashingNumber = flashing,
                    modifier = Modifier.fillMaxWidth(),
                    onTap = { handleTap(it) }
                )

                roundFlash?.let { text ->
                    Box(modifier = Modifier.align(Alignment.TopCenter)) {
                        Text(
                            text = text,
                            color = PfcPurple,
                            fontSize = 24.sp,
                            fontWeight = FontWeight.Bold,
                            modifier = Modifier
                                .padding(top = 6.dp)
                                .background(PfcPurple.copy(alpha = 0.16f), RoundedCornerShape(50))
                                .border(1.dp, PfcPurple.copy(alpha = 0.35f), RoundedCornerShape(50))
                                .padding(horizontal = 18.dp, vertical = 8.dp)
                        )
                    }
                }
            }

            EndlessFooter(
                isRunning = phase == EndlessPhase.RUNNING,
                boardTotal = boardTotal,
                remainingOnBoard = remainingOnBoard,
                modifier = Modifier.padding(horizontal = 20.dp)
            )
        }

        if (phase == EndlessPhase.COUNTDOWN) {
            CountdownOverlay(
                countdown = countdown,
                tint = PfcPurple,
                title = "准备好",
                detail = "第 1 轮 ${EndlessRules.INITIAL_COUNT} 个数字 · 限时 ${EndlessRules.ROUND_DURATION.toInt()} 秒",
                note = "清空一轮就 +${EndlessRules.INCREMENT} 个，数字与时间全部重置"
            )
        }
    }

    result?.let { value ->
        EndlessResultDialog(
            result = value,
            best = bestRecord,
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
private fun EndlessTopBar(onExit: () -> Unit, onRestart: () -> Unit) {
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
                text = "无限模式",
                color = Color.White,
                fontSize = 16.sp,
                fontWeight = FontWeight.SemiBold
            )
            Text(
                text = EndlessRules.summary,
                color = Color.White.copy(alpha = 0.55f),
                fontSize = 11.sp
            )
        }

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            EndlessIconButton(glyph = "✕", onClick = onExit)
            EndlessIconButton(glyph = "↻", onClick = onRestart)
        }
    }
}

@Composable
private fun EndlessIconButton(glyph: String, onClick: () -> Unit) {
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
private fun EndlessStatusPanel(
    round: Int,
    boardTotal: Int,
    roundRemaining: Double,
    clearedInRound: Int,
    clearedTotal: Int,
    roundsCompleted: Int,
    mistakes: Int
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = 10.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        Text(
            text = "第 $round 轮 · $boardTotal 个数字",
            color = PfcPurple,
            fontSize = 13.sp,
            fontWeight = FontWeight.SemiBold,
            modifier = Modifier
                .background(PfcPurple.copy(alpha = 0.16f), RoundedCornerShape(50))
                .padding(horizontal = 12.dp, vertical = 4.dp)
        )

        Row(verticalAlignment = Alignment.Bottom) {
            Text(
                text = String.format(Locale.US, "%.1f", max(roundRemaining, 0.0)),
                color = if (roundRemaining <= 20.0) Color(0xFFFF9F45) else Color.White,
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
                progress = {
                    if (boardTotal > 0) clearedInRound.toFloat() / boardTotal else 0f
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(5.dp),
                color = PfcPurple,
                trackColor = Color.White.copy(alpha = 0.10f)
            )

            Row(modifier = Modifier.fillMaxWidth()) {
                Text(
                    text = "本轮 $clearedInRound/$boardTotal",
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

            Row(modifier = Modifier.fillMaxWidth()) {
                Text(
                    text = "累计 $clearedTotal 个",
                    color = Color.White.copy(alpha = 0.5f),
                    fontSize = 11.sp
                )
                Spacer(Modifier.weight(1f))
                Text(
                    text = "已清空 $roundsCompleted 轮",
                    color = Color.White.copy(alpha = 0.5f),
                    fontSize = 11.sp
                )
            }
        }
    }
}

@Composable
private fun EndlessFooter(
    isRunning: Boolean,
    boardTotal: Int,
    remainingOnBoard: Int,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .height(56.dp)
            .background(
                color = if (isRunning) Color.White.copy(alpha = 0.06f)
                else Color(0xFFFF9F45).copy(alpha = 0.18f),
                shape = RoundedCornerShape(18.dp)
            ),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = if (isRunning) "⏳ 板面 $boardTotal 个 · 还剩 $remainingOnBoard 个"
            else "时间到 · 正在结算",
            color = if (isRunning) Color.White.copy(alpha = 0.55f) else Color(0xFFFF9F45),
            fontSize = 17.sp,
            fontWeight = FontWeight.SemiBold
        )
    }
}
