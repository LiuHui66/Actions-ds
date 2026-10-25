package com.liuhui66.pfc.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.drawText
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.unit.toSize
import com.liuhui66.pfc.model.BoardCell
import kotlin.math.max
import kotlin.math.min

/**
 * 不规则拼块数字板（对应 iOS 的 NumberBoard）
 *
 * 拼块形状由 BoardLayout 在单位圆里算好后传进来，这里只负责：
 * 按实际尺寸放大、上色、放数字、并把点击落在正确的块上。
 */
@Composable
fun NumberBoard(
    cells: List<BoardCell>,
    nextExpected: Int,
    tint: Color,
    flashingNumber: Int?,
    modifier: Modifier = Modifier,
    onTap: (Int) -> Unit
) {
    val textMeasurer = rememberTextMeasurer()
    // 保证 pointerInput 里拿到的是最新的回调，避免闭包捕获旧状态
    val currentOnTap by rememberUpdatedState(onTap)
    val currentCells by rememberUpdatedState(cells)

    Canvas(
        modifier = modifier
            .aspectRatio(1f)
            .pointerInput(Unit) {
                detectTapGestures { position ->
                    val hit = hitTest(currentCells, position, size.toSize())
                    if (hit != null) currentOnTap(hit)
                }
            }
    ) {
        val side = min(size.width, size.height)
        val radius = max(side / 2f - 2f, 1f)
        val origin = Offset(size.width / 2f, size.height / 2f)
        val strokeWidth = 1.4.dp.toPx()

        // 1. 拼块底色与描边
        cells.forEach { cell ->
            val path = buildPath(cell, origin, radius)
            drawPath(path, fillColor(cell, nextExpected, tint, flashingNumber))
            drawPath(
                path = path,
                color = borderColor(cell, nextExpected, tint, flashingNumber),
                style = Stroke(width = strokeWidth)
            )
        }

        // 2. 数字（落在每块的重心）
        cells.forEach { cell ->
            val inradiusDp = (cell.inradius * radius).toDp().value
            val digitsScale = if (cell.value >= 10) 0.92f else 1f
            val fontSize = (inradiusDp * 1.25f * digitsScale).coerceIn(11f, 40f)

            val layout = textMeasurer.measure(
                text = cell.value.toString(),
                style = TextStyle(
                    fontSize = fontSize.sp,
                    fontWeight = FontWeight.SemiBold
                )
            )
            drawText(
                textLayoutResult = layout,
                topLeft = Offset(
                    origin.x + cell.center.x * radius - layout.size.width / 2f,
                    origin.y + cell.center.y * radius - layout.size.height / 2f
                ),
                color = textColor(cell, nextExpected, tint, flashingNumber)
            )
        }
    }
}

// MARK: - 坐标与命中

private fun buildPath(cell: BoardCell, origin: Offset, radius: Float): Path {
    val path = Path()
    cell.polygon.forEachIndexed { index, point ->
        val x = origin.x + point.x * radius
        val y = origin.y + point.y * radius
        if (index == 0) path.moveTo(x, y) else path.lineTo(x, y)
    }
    path.close()
    return path
}

/** 把点击位置换算成单位坐标，找到落在哪个拼块里（射线法） */
private fun hitTest(cells: List<BoardCell>, position: Offset, containerSize: Size): Int? {
    val side = min(containerSize.width, containerSize.height)
    val radius = max(side / 2f - 2f, 1f)
    val origin = Offset(containerSize.width / 2f, containerSize.height / 2f)
    val unit = Offset(
        (position.x - origin.x) / radius,
        (position.y - origin.y) / radius
    )
    for (cell in cells) {
        if (polygonContains(cell.polygon, unit)) return cell.value
    }
    return null
}

private fun polygonContains(polygon: List<Offset>, point: Offset): Boolean {
    if (polygon.size < 3) return false

    var inside = false
    var previousIndex = polygon.size - 1

    for (index in polygon.indices) {
        val a = polygon[index]
        val b = polygon[previousIndex]

        if ((a.y > point.y) != (b.y > point.y)) {
            val crossingX = (b.x - a.x) * (point.y - a.y) / (b.y - a.y) + a.x
            if (point.x < crossingX) inside = !inside
        }
        previousIndex = index
    }
    return inside
}

// MARK: - 外观

private fun isFound(value: Int, nextExpected: Int): Boolean = value < nextExpected

private fun fillColor(
    cell: BoardCell,
    nextExpected: Int,
    tint: Color,
    flashingNumber: Int?
): Color = when {
    flashingNumber == cell.value -> Color.Red.copy(alpha = 0.30f)
    isFound(cell.value, nextExpected) -> tint.copy(alpha = 0.16f)
    // 相邻块深浅交替，让拼块边界更清楚
    cell.id % 2 == 0 -> Color.White.copy(alpha = 0.10f)
    else -> Color.White.copy(alpha = 0.065f)
}

private fun borderColor(
    cell: BoardCell,
    nextExpected: Int,
    tint: Color,
    flashingNumber: Int?
): Color = when {
    flashingNumber == cell.value -> Color.Red
    isFound(cell.value, nextExpected) -> tint.copy(alpha = 0.40f)
    else -> Color.White.copy(alpha = 0.13f)
}

private fun textColor(
    cell: BoardCell,
    nextExpected: Int,
    tint: Color,
    flashingNumber: Int?
): Color = when {
    flashingNumber == cell.value -> Color.White
    isFound(cell.value, nextExpected) -> tint.copy(alpha = 0.55f)
    else -> Color.White
}
