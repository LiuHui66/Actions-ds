package com.liuhui66.pfc.data

import android.content.Context

/** 无限模式的最高纪录（跨轮累计找出多少个数字） */
object EndlessRecordStorage {

    private const val PREFS_NAME = "pfc"
    private const val KEY = "pfc.endlessBestCleared"

    fun best(context: Context): Int = prefs(context).getInt(KEY, 0)

    /** 提交成绩，返回是否刷新了纪录 */
    fun submit(context: Context, clearedCount: Int): Boolean {
        if (clearedCount <= 0) return false
        if (clearedCount <= best(context)) return false
        prefs(context).edit().putInt(KEY, clearedCount).apply()
        return true
    }

    private fun prefs(context: Context) =
        context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
}
