import CoreGraphics
import Foundation

/// 板上的一块不规则拼块（一个 Voronoi 单元）
struct BoardCell: Identifiable, Equatable {
    let id: Int
    /// 这一块里显示的数字
    let value: Int
    /// 多边形顶点，单位坐标：圆心 (0, 0)，外接圆半径 1
    let polygon: [CGPoint]
    /// 数字落点（多边形重心），单位坐标
    let center: CGPoint
    /// 重心到最近边的距离，单位坐标；用来换算字号
    let inradius: CGFloat
}

/// 不规则拼块布局生成器
///
/// 思路：
/// 1. 在圆形区域内撒 `count` 个点（最佳候选采样，避免扎堆）
/// 2. Lloyd 松弛若干轮：把每个点推向自己单元的重心，让拼块大小趋于均匀
/// 3. 对每个点求 Voronoi 单元（用其余点的中垂线反复裁剪）
/// 4. 用圆形外框再裁一次，得到一块圆形的「蜂巢」
///
/// 结果：每块面积接近、形状各不相同 —— 是拼块，不是网格。
enum BoardLayout {

    /// 生成 `count` 块拼块，并把 1...count 随机分配到其中
    static func make(count: Int, seed: UInt64) -> [BoardCell] {
        guard count > 0 else { return [] }

        var attemptSeed = seed
        for round in 0..<6 {
            let cells = build(count: count, seed: attemptSeed)
            if cells.count == count { return cells }
            // 极端情况下个别单元退化，换一组随机数重来
            attemptSeed = attemptSeed &* 6_364_136_223_846_793_005
                &+ UInt64(round + 1) &* 1_442_695_040_888_963_407
        }
        return build(count: count, seed: seed)
    }

    // MARK: - 构建

    private static func build(count: Int, seed: UInt64) -> [BoardCell] {
        var rng = SeededGenerator(seed: seed)
        let container = circlePolygon(segments: 96, radius: 1)

        // 1. 撒点：每次挑 24 个候选里离已有点最远的那个，分布更均匀
        var seeds: [CGPoint] = []
        seeds.reserveCapacity(count)
        let candidateCount = 24
        for _ in 0..<count {
            var bestPoint = CGPoint.zero
            var bestScore: CGFloat = -1
            for _ in 0..<candidateCount {
                let candidate = randomPoint(inRadius: 0.82, using: &rng)
                var nearest = CGFloat.greatestFiniteMagnitude
                for existing in seeds {
                    let dx = existing.x - candidate.x
                    let dy = existing.y - candidate.y
                    nearest = min(nearest, dx * dx + dy * dy)
                }
                if nearest > bestScore {
                    bestScore = nearest
                    bestPoint = candidate
                }
            }
            seeds.append(bestPoint)
        }

        // 2. Lloyd 松弛：让拼块大小趋于均匀
        for _ in 0..<3 {
            var relaxed: [CGPoint] = []
            relaxed.reserveCapacity(seeds.count)
            for index in seeds.indices {
                let polygon = voronoiCell(at: index, seeds: seeds, container: container)
                if polygon.count >= 3 {
                    relaxed.append(clampInside(centroid(polygon), radius: 0.86))
                } else {
                    relaxed.append(seeds[index])
                }
            }
            seeds = relaxed
        }

        // 3. 生成最终拼块，并把数字随机分配
        var values = Array(1...count)
        values.shuffle(using: &rng)

        var cells: [BoardCell] = []
        cells.reserveCapacity(count)
        for index in seeds.indices {
            let polygon = voronoiCell(at: index, seeds: seeds, container: container)
            guard polygon.count >= 3, index < values.count else { continue }
            let center = centroid(polygon)
            let inradius = minEdgeDistance(from: center, polygon: polygon)
            cells.append(
                BoardCell(
                    id: index,
                    value: values[index],
                    polygon: polygon,
                    center: center,
                    inradius: inradius
                )
            )
        }
        return cells
    }

    // MARK: - 几何

    /// 圆形外框（用多边形逼近，方便做半平面裁剪）
    private static func circlePolygon(segments: Int, radius: CGFloat) -> [CGPoint] {
        var points: [CGPoint] = []
        points.reserveCapacity(segments)
        for index in 0..<segments {
            let angle = Double(index) / Double(segments) * 2 * Double.pi
            points.append(
                CGPoint(x: radius * CGFloat(cos(angle)), y: radius * CGFloat(sin(angle)))
            )
        }
        return points
    }

    private static func randomPoint(inRadius maxRadius: CGFloat, using rng: inout SeededGenerator) -> CGPoint {
        let angle = Double.random(in: 0..<(2 * Double.pi), using: &rng)
        // sqrt 让点在圆内均匀分布，而不是挤在圆心
        let distance = Double.random(in: 0...1, using: &rng).squareRoot() * Double(maxRadius)
        return CGPoint(x: CGFloat(cos(angle)) * CGFloat(distance),
                       y: CGFloat(sin(angle)) * CGFloat(distance))
    }

    private static func clampInside(_ point: CGPoint, radius: CGFloat) -> CGPoint {
        let length = (point.x * point.x + point.y * point.y).squareRoot()
        guard length > radius, length > 0 else { return point }
        let scale = radius / length
        return CGPoint(x: point.x * scale, y: point.y * scale)
    }

    /// 第 index 个点的 Voronoi 单元：从圆形外框开始，用其它点的中垂线逐条裁掉
    private static func voronoiCell(at index: Int, seeds: [CGPoint], container: [CGPoint]) -> [CGPoint] {
        var polygon = container
        let own = seeds[index]

        for other in seeds.indices where other != index {
            if polygon.count < 3 { return [] }
            let target = seeds[other]
            let normalX = target.x - own.x
            let normalY = target.y - own.y
            if abs(normalX) < 1e-9 && abs(normalY) < 1e-9 { continue }

            polygon = clipHalfPlane(
                polygon,
                normalX: normalX,
                normalY: normalY,
                midX: (own.x + target.x) * 0.5,
                midY: (own.y + target.y) * 0.5
            )
        }
        return polygon
    }

    /// 保留 (p - mid) · n <= 0 的一侧
    private static func clipHalfPlane(
        _ polygon: [CGPoint],
        normalX: CGFloat,
        normalY: CGFloat,
        midX: CGFloat,
        midY: CGFloat
    ) -> [CGPoint] {
        guard polygon.count >= 3 else { return [] }

        func side(_ point: CGPoint) -> CGFloat {
            (point.x - midX) * normalX + (point.y - midY) * normalY
        }

        var result: [CGPoint] = []
        result.reserveCapacity(polygon.count + 2)

        var previous = polygon[polygon.count - 1]
        var previousSide = side(previous)

        for current in polygon {
            let currentSide = side(current)
            let previousInside = previousSide <= 0
            let currentInside = currentSide <= 0

            if currentInside {
                if !previousInside {
                    result.append(crossingPoint(previous, current, previousSide, currentSide))
                }
                result.append(current)
            } else if previousInside {
                result.append(crossingPoint(previous, current, previousSide, currentSide))
            }

            previous = current
            previousSide = currentSide
        }
        return result
    }

    private static func crossingPoint(
        _ from: CGPoint,
        _ to: CGPoint,
        _ fromSide: CGFloat,
        _ toSide: CGFloat
    ) -> CGPoint {
        let denominator = fromSide - toSide
        guard abs(denominator) > 1e-12 else { return from }
        let t = fromSide / denominator
        return CGPoint(x: from.x + (to.x - from.x) * t,
                       y: from.y + (to.y - from.y) * t)
    }

    /// 多边形面积重心
    private static func centroid(_ polygon: [CGPoint]) -> CGPoint {
        guard !polygon.isEmpty else { return .zero }

        guard polygon.count >= 3 else {
            let sumX = polygon.reduce(0) { $0 + $1.x }
            let sumY = polygon.reduce(0) { $0 + $1.y }
            return CGPoint(x: sumX / CGFloat(polygon.count), y: sumY / CGFloat(polygon.count))
        }

        var doubleArea: CGFloat = 0
        var weightedX: CGFloat = 0
        var weightedY: CGFloat = 0

        for index in polygon.indices {
            let current = polygon[index]
            let next = polygon[(index + 1) % polygon.count]
            let cross = current.x * next.y - next.x * current.y
            doubleArea += cross
            weightedX += (current.x + next.x) * cross
            weightedY += (current.y + next.y) * cross
        }

        if abs(doubleArea) < 1e-9 {
            let sumX = polygon.reduce(0) { $0 + $1.x }
            let sumY = polygon.reduce(0) { $0 + $1.y }
            return CGPoint(x: sumX / CGFloat(polygon.count), y: sumY / CGFloat(polygon.count))
        }

        return CGPoint(x: weightedX / (3 * doubleArea), y: weightedY / (3 * doubleArea))
    }

    /// 点到多边形各边的最短距离（用于换算字号）
    private static func minEdgeDistance(from point: CGPoint, polygon: [CGPoint]) -> CGFloat {
        guard polygon.count >= 3 else { return 0 }
        var best = CGFloat.greatestFiniteMagnitude
        for index in polygon.indices {
            let a = polygon[index]
            let b = polygon[(index + 1) % polygon.count]
            best = min(best, pointToSegmentDistance(point, a, b))
        }
        return best.isFinite ? best : 0
    }

    private static func pointToSegmentDistance(_ point: CGPoint, _ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let abX = b.x - a.x
        let abY = b.y - a.y
        let lengthSquared = abX * abX + abY * abY

        let projected: CGPoint
        if lengthSquared < 1e-12 {
            projected = a
        } else {
            var t = ((point.x - a.x) * abX + (point.y - a.y) * abY) / lengthSquared
            t = min(max(t, 0), 1)
            projected = CGPoint(x: a.x + abX * t, y: a.y + abY * t)
        }

        let dx = point.x - projected.x
        let dy = point.y - projected.y
        return (dx * dx + dy * dy).squareRoot()
    }
}

/// 可复现的伪随机数生成器（SplitMix64），保证同一 seed 得到同一套拼块
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed
    }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
