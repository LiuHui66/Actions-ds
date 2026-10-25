package com.liuhui66.pfc.model

import androidx.compose.ui.graphics.Color

/** 一轮训练的结果 */
data class SessionResult(
    val difficulty: Difficulty,
    val duration: Double,
    val mistakes: Int,
    val isNewRecord: Boolean
) {
    /** 平均每个数字耗时（秒） */
    val averagePerNumber: Double
        get() = if (difficulty.numberCount > 0) duration / difficulty.numberCount else duration

    val grade: Grade
        get() = when {
            averagePerNumber < 1.0 -> Grade.S
            averagePerNumber < 1.5 -> Grade.A
            averagePerNumber < 2.2 -> Grade.B
            averagePerNumber < 3.0 -> Grade.C
            else -> Grade.D
        }
}

/** 与 iOS 的 Grade 一一对应（阈值、评语、配色都一致） */
enum class Grade(val title: String, val color: Color, val comment: String) {
    S("S", Color(0xFF3DDC97), "前额叶满负荷运转，非常出色。"),
    A("A", Color(0xFF35D6E8), "专注度很高，继续保持这个节奏。"),
    B("B", Color(0xFFFFD54F), "表现稳定，可以再压缩一点搜索时间。"),
    C("C", Color(0xFFFF9F45), "注意力有波动，先保证准确再提速。"),
    D("D", Color(0xFFFF7AA2), "别急，稳定找出比快更重要。")
}
