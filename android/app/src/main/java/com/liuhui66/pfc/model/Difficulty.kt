package com.liuhui66.pfc.model

import androidx.compose.ui.graphics.Color

/**
 * 训练难度：初级 / 中级 / 高级，依次对应 10 / 20 / 30 个数字
 *
 * id 与 iOS 的 rawValue 完全一致（beginner / intermediate / advanced），
 * 这样两端存成绩用的 key 也一致，方便以后做跨端导入。
 */
enum class Difficulty(
    val id: String,
    val title: String,
    val numberCount: Int,
    val tint: Color
) {
    BEGINNER("beginner", "初级", 10, Color(0xFF3DDC97)),
    INTERMEDIATE("intermediate", "中级", 20, Color(0xFF35D6E8)),
    ADVANCED("advanced", "高级", 30, Color(0xFFFF9F45));

    /** 副标题：N 个数字 · 不规则拼块 */
    val subtitle: String get() = "$numberCount 个数字 · 不规则拼块"

    val hint: String get() = when (this) {
        BEGINNER -> "熟悉规则，按 1 → 10 顺序点选"
        INTERMEDIATE -> "扩大搜索范围，按 1 → 20 顺序点选"
        ADVANCED -> "高强度注意力，按 1 → 30 顺序点选"
    }
}
