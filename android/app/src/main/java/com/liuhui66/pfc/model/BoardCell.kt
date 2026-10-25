package com.liuhui66.pfc.model

import androidx.compose.ui.geometry.Offset

/**
 * 板上的一块不规则拼块（一个 Voronoi 单元）
 *
 * 坐标全部是「单位坐标」：圆心 (0, 0)，外接圆半径 1。
 * 渲染时再按实际边长放大，因此与屏幕尺寸、密度无关。
 */
data class BoardCell(
    val id: Int,
    /** 这一块里显示的数字 */
    val value: Int,
    /** 多边形顶点 */
    val polygon: List<Offset>,
    /** 数字落点（多边形面积重心） */
    val center: Offset,
    /** 重心到最近边的距离，用来换算字号 */
    val inradius: Float
)
