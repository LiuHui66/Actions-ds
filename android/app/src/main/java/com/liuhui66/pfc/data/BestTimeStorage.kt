package com.liuhui66.pfc.data

import android.content.Context
import com.liuhui66.pfc.model.Difficulty

/**
 * 各难度的最佳成绩（SharedPreferences，key 与 iOS 的 UserDefaults key 同名）
 *
 * 说明：用 Float 存秒数，精度对训练成绩足够；读取时 -1 视为「还没有成绩」。
 */
object BestTimeStorage {

    private const val PREFS_NAME = "pfc"
    private const val KEY_PREFIX = "pfc.bestTimes."

    fun best(context: Context, difficulty: Difficulty): Double? {
        val value = prefs(context).getFloat(KEY_PREFIX + difficulty.id, -1f)
        return if (value > 0f) value.toDouble() else null
    }

    /** 提交成绩，返回是否刷新了最佳纪录 */
    fun submit(context: Context, duration: Double, difficulty: Difficulty): Boolean {
        val current = best(context, difficulty)
        if (current != null && current <= duration) return false
        prefs(context).edit().putFloat(KEY_PREFIX + difficulty.id, duration.toFloat()).apply()
        return true
    }

    private fun prefs(context: Context) =
        context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
}
