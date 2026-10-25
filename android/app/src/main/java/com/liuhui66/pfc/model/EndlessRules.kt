package com.liuhui66.pfc.model

/**
 * 无限模式的规则常量（改规则只需要动这里）
 *
 * 规则：每一轮都是独立的一关
 * - 第 1 轮 10 个数字，限时 100 秒
 * - 清空这一轮 → 下一轮 15 个数字，数字从 1 重新开始、板面全部重置、倒计时也重置回 100 秒
 * - 依次 10 → 15 → 20 → 25 …
 * - 任何一轮时间归零 → 本局结束，结算
 */
object EndlessRules {
    /** 每一轮的时限（秒）：每进入新的一轮，倒计时重置回这个值 */
    const val ROUND_DURATION: Double = 100.0

    /** 第 1 轮的数字个数 */
    const val INITIAL_COUNT: Int = 10

    /** 每完成一轮，下一轮增加的个数 */
    const val INCREMENT: Int = 5

    /** 开局倒计时（秒） */
    const val COUNTDOWN_SECONDS: Int = 5

    /** 第 [round] 轮（从 1 开始）的数字个数：10、15、20、25 … */
    fun roundSize(round: Int): Int = INITIAL_COUNT + maxOf(round - 1, 0) * INCREMENT

    /** 一句话规则，用于首页卡片与倒计时提示 */
    val summary: String
        get() = "每轮 ${ROUND_DURATION.toInt()} 秒 · $INITIAL_COUNT 个起 · 每轮 +$INCREMENT"
}
