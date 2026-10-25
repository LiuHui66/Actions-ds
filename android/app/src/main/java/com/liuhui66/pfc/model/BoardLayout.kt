package com.liuhui66.pfc.model

import androidx.compose.ui.geometry.Offset
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin
import kotlin.math.sqrt
import kotlin.random.Random

/**
 * 不规则拼块布局生成器（与 iOS 端 BoardLayout.swift 算法完全一致）
 *
 * 思路：
 * 1. 在圆形区域内撒 count 个点（最佳候选采样，避免扎堆）
 * 2. Lloyd 松弛若干轮：把每个点推向自己单元的重心，让拼块大小趋于均匀
 * 3. 对每个点求 Voronoi 单元（用其余点的中垂线反复裁剪半平面）
 * 4. 用圆形外框再裁一次，得到一块圆形的「蜂巢」
 *
 * 结果：每块面积接近、形状各不相同 —— 是拼块，不是网格。
 */
object BoardLayout {

    /** 生成 count 块拼块，并把 1..count 随机分配到其中 */
    fun make(count: Int, seed: Long): List<BoardCell> {
        if (count <= 0) return emptyList()

        var attemptSeed = seed
        for (round in 0 until 6) {
            val cells = build(count, attemptSeed)
            if (cells.size == count) return cells
            // 极端情况下个别单元退化，换一组随机数重来
            attemptSeed = attemptSeed * 6364136223846793005L +
                (round + 1).toLong() * 1442695040888963407L
        }
        return build(count, seed)
    }

    // MARK: - 构建

    private fun build(count: Int, seed: Long): List<BoardCell> {
        val random = Random(seed)
        val container = circlePolygon(segments = 96, radius = 1f)

        // 1. 撒点：每次挑 24 个候选里离已有点最远的那个，分布更均匀
        val seeds = ArrayList<Offset>(count)
        val candidateCount = 24
        repeat(count) {
            var bestPoint = Offset.Zero
            var bestScore = -1f
            repeat(candidateCount) {
                val candidate = randomPoint(maxRadius = 0.82f, random = random)
                var nearest = Float.MAX_VALUE
                for (existing in seeds) {
                    val dx = existing.x - candidate.x
                    val dy = existing.y - candidate.y
                    val distance = dx * dx + dy * dy
                    if (distance < nearest) nearest = distance
                }
                if (nearest > bestScore) {
                    bestScore = nearest
                    bestPoint = candidate
                }
            }
            seeds.add(bestPoint)
        }

        // 2. Lloyd 松弛：让拼块大小趋于均匀
        repeat(3) {
            val relaxed = ArrayList<Offset>(seeds.size)
            for (index in seeds.indices) {
                val polygon = voronoiCell(index, seeds, container)
                if (polygon.size >= 3) {
                    relaxed.add(clampInside(centroid(polygon), radius = 0.86f))
                } else {
                    relaxed.add(seeds[index])
                }
            }
            seeds.clear()
            seeds.addAll(relaxed)
        }

        // 3. 生成最终拼块，并把数字随机分配
        val values = (1..count).shuffled(random)

        val cells = ArrayList<BoardCell>(count)
        for (index in seeds.indices) {
            val polygon = voronoiCell(index, seeds, container)
            if (polygon.size < 3 || index >= values.size) continue
            val center = centroid(polygon)
            cells.add(
                BoardCell(
                    id = index,
                    value = values[index],
                    polygon = polygon,
                    center = center,
                    inradius = minEdgeDistance(center, polygon)
                )
            )
        }
        return cells
    }

    // MARK: - 几何

    /** 圆形外框（用多边形逼近，方便做半平面裁剪） */
    private fun circlePolygon(segments: Int, radius: Float): List<Offset> =
        List(segments) { index ->
            val angle = index.toDouble() / segments.toDouble() * 2.0 * Math.PI
            Offset((radius * cos(angle)).toFloat(), (radius * sin(angle)).toFloat())
        }

    private fun randomPoint(maxRadius: Float, random: Random): Offset {
        val angle = random.nextDouble(0.0, 2.0 * Math.PI)
        // sqrt 让点在圆内均匀分布，而不是挤在圆心
        val distance = sqrt(random.nextDouble(0.0, 1.0)) * maxRadius
        return Offset(
            (cos(angle) * distance).toFloat(),
            (sin(angle) * distance).toFloat()
        )
    }

    private fun clampInside(point: Offset, radius: Float): Offset {
        val length = sqrt(point.x * point.x + point.y * point.y)
        if (length <= radius || length <= 0f) return point
        val scale = radius / length
        return Offset(point.x * scale, point.y * scale)
    }

    /** 第 index 个点的 Voronoi 单元：从圆形外框开始，用其它点的中垂线逐条裁掉 */
    private fun voronoiCell(
        index: Int,
        seeds: List<Offset>,
        container: List<Offset>
    ): List<Offset> {
        var polygon = container
        val own = seeds[index]

        for (other in seeds.indices) {
            if (other == index) continue
            if (polygon.size < 3) return emptyList()
            val target = seeds[other]
            val normalX = target.x - own.x
            val normalY = target.y - own.y
            if (abs(normalX) < 1e-6f && abs(normalY) < 1e-6f) continue

            polygon = clipHalfPlane(
                polygon = polygon,
                normalX = normalX,
                normalY = normalY,
                midX = (own.x + target.x) * 0.5f,
                midY = (own.y + target.y) * 0.5f
            )
        }
        return polygon
    }

    /** 保留 (p - mid) · n <= 0 的一侧 */
    private fun clipHalfPlane(
        polygon: List<Offset>,
        normalX: Float,
        normalY: Float,
        midX: Float,
        midY: Float
    ): List<Offset> {
        if (polygon.size < 3) return emptyList()

        fun side(point: Offset): Float =
            (point.x - midX) * normalX + (point.y - midY) * normalY

        val result = ArrayList<Offset>(polygon.size + 2)

        var previous = polygon[polygon.size - 1]
        var previousSide = side(previous)

        for (current in polygon) {
            val currentSide = side(current)
            val previousInside = previousSide <= 0f
            val currentInside = currentSide <= 0f

            if (currentInside) {
                if (!previousInside) {
                    result.add(crossingPoint(previous, current, previousSide, currentSide))
                }
                result.add(current)
            } else if (previousInside) {
                result.add(crossingPoint(previous, current, previousSide, currentSide))
            }

            previous = current
            previousSide = currentSide
        }
        return result
    }

    private fun crossingPoint(
        from: Offset,
        to: Offset,
        fromSide: Float,
        toSide: Float
    ): Offset {
        val denominator = fromSide - toSide
        if (abs(denominator) < 1e-9f) return from
        val t = fromSide / denominator
        return Offset(
            from.x + (to.x - from.x) * t,
            from.y + (to.y - from.y) * t
        )
    }

    /** 多边形面积重心 */
    private fun centroid(polygon: List<Offset>): Offset {
        if (polygon.isEmpty()) return Offset.Zero

        if (polygon.size < 3) {
            val sumX = polygon.sumOf { it.x.toDouble() }
            val sumY = polygon.sumOf { it.y.toDouble() }
            return Offset((sumX / polygon.size).toFloat(), (sumY / polygon.size).toFloat())
        }

        var doubleArea = 0.0
        var weightedX = 0.0
        var weightedY = 0.0

        for (index in polygon.indices) {
            val current = polygon[index]
            val next = polygon[(index + 1) % polygon.size]
            val cross = current.x * next.y - next.x * current.y
            doubleArea += cross
            weightedX += ((current.x + next.x) * cross).toDouble()
            weightedY += ((current.y + next.y) * cross).toDouble()
        }

        if (abs(doubleArea) < 1e-7) {
            val sumX = polygon.sumOf { it.x.toDouble() }
            val sumY = polygon.sumOf { it.y.toDouble() }
            return Offset((sumX / polygon.size).toFloat(), (sumY / polygon.size).toFloat())
        }

        return Offset(
            (weightedX / (3.0 * doubleArea)).toFloat(),
            (weightedY / (3.0 * doubleArea)).toFloat()
        )
    }

    /** 点到多边形各边的最短距离（用于换算字号） */
    private fun minEdgeDistance(point: Offset, polygon: List<Offset>): Float {
        if (polygon.size < 3) return 0f
        var best = Float.MAX_VALUE
        for (index in polygon.indices) {
            val a = polygon[index]
            val b = polygon[(index + 1) % polygon.size]
            best = min(best, pointToSegmentDistance(point, a, b))
        }
        return if (best.isFinite()) best else 0f
    }

    private fun pointToSegmentDistance(point: Offset, a: Offset, b: Offset): Float {
        val abX = b.x - a.x
        val abY = b.y - a.y
        val lengthSquared = abX * abX + abY * abY

        val projected: Offset
        if (lengthSquared < 1e-9f) {
            projected = a
        } else {
            var t = ((point.x - a.x) * abX + (point.y - a.y) * abY) / lengthSquared
            t = min(max(t, 0f), 1f)
            projected = Offset(a.x + abX * t, a.y + abY * t)
        }

        val dx = point.x - projected.x
        val dy = point.y - projected.y
        return sqrt(dx * dx + dy * dy)
    }
}
