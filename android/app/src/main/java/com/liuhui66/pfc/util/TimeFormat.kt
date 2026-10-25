package com.liuhui66.pfc.util

import java.util.Locale

/** 与 iOS 的 TimeFormat 行为一致 */
object TimeFormat {

    /** 12.34（不带单位） */
    fun plain(value: Double): String = String.format(Locale.US, "%.2f", value)

    /** 超过 1 分钟时显示 1:03.45，否则显示 12.34 */
    fun clock(value: Double): String {
        if (value < 60.0) return String.format(Locale.US, "%.2f", value)
        val minutes = (value / 60.0).toInt()
        val seconds = value % 60.0
        return String.format(Locale.US, "%d:%05.2f", minutes, seconds)
    }

    fun best(value: Double): String = clock(value) + " 秒"
}
