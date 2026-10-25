package com.liuhui66.pfc.model

/** 无限模式一局的结果 */
data class EndlessResult(
    /** 跨轮累计找出多少个数字（含最后一轮没清完的部分） */
    val clearedCount: Int,
    /** 完整清空了多少轮 */
    val roundsCompleted: Int,
    val mistakes: Int,
    /** 时间耗尽时那一轮的数字个数 */
    val boardTotal: Int,
    /** 本局实际总用时（各轮已用时间之和，不是固定 100 秒） */
    val elapsed: Double,
    val isNewRecord: Boolean
) {
    /**
     * 评级：看完整清空了几轮（每轮数字更多、时间不变，难度是递增的）
     * S ≥ 4 轮（清空到 25 个）、A ≥ 3 轮、B ≥ 2 轮、C ≥ 1 轮、其它 D
     */
    val grade: Grade
        get() = when {
            roundsCompleted >= 4 -> Grade.S
            roundsCompleted == 3 -> Grade.A
            roundsCompleted == 2 -> Grade.B
            roundsCompleted == 1 -> Grade.C
            else -> Grade.D
        }

    /** 平均每个数字耗时 */
    val secondsPerNumber: Double
        get() = if (clearedCount > 0) elapsed / clearedCount else elapsed
}
