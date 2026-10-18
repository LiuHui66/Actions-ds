import SwiftUI

/// 任意多边形（拼块轮廓）
struct PolygonShape: Shape {
    var points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard points.count >= 3 else { return path }

        path.move(to: points[0])
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }
}

/// 不规则拼块数字板（替代原来的规整网格）
///
/// 拼块形状由 `BoardLayout` 在单位圆里算好后传进来，这里只负责
/// 按实际尺寸放大、上色、放数字、并把点击落在正确的块上。
struct NumberBoard: View {
    let cells: [BoardCell]
    /// 下一个应该被点到的数字；小于它的都算已找到
    let nextExpected: Int
    let tint: Color
    /// 点错时闪烁的数字
    let flashingNumber: Int?
    let onTap: (Int) -> Void

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let radius = max(side / 2 - 2, 1)
            let origin = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)

            ZStack {
                // 拼块底色与描边
                ForEach(cells) { cell in
                    let shape = PolygonShape(points: screenPoints(cell.polygon, origin: origin, radius: radius))
                    shape
                        .fill(fillColor(for: cell))
                        .overlay(
                            shape.stroke(borderColor(for: cell), lineWidth: 1.4)
                        )
                        .animation(.snappy(duration: 0.22), value: nextExpected)
                        .animation(.easeOut(duration: 0.15), value: flashingNumber)
                }

                // 数字
                ForEach(cells) { cell in
                    Text("\(cell.value)")
                        .font(
                            .system(
                                size: fontSize(for: cell, radius: radius),
                                weight: .semibold,
                                design: .rounded
                            )
                        )
                        .monospacedDigit()
                        .foregroundStyle(textColor(for: cell))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .position(
                            x: origin.x + cell.center.x * radius,
                            y: origin.y + cell.center.y * radius
                        )
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .gesture(
                SpatialTapGesture()
                    .onEnded { value in
                        if let hit = cellValue(at: value.location, origin: origin, radius: radius) {
                            onTap(hit)
                        }
                    }
            )
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - 坐标与命中

    private func screenPoints(_ unitPoints: [CGPoint], origin: CGPoint, radius: CGFloat) -> [CGPoint] {
        unitPoints.map { point in
            CGPoint(x: origin.x + point.x * radius, y: origin.y + point.y * radius)
        }
    }

    /// 把点击位置换算成单位坐标，找到落在哪个拼块里
    private func cellValue(at location: CGPoint, origin: CGPoint, radius: CGFloat) -> Int? {
        guard radius > 0 else { return nil }
        let unit = CGPoint(
            x: (location.x - origin.x) / radius,
            y: (location.y - origin.y) / radius
        )
        for cell in cells where polygonContains(cell.polygon, unit) {
            return cell.value
        }
        return nil
    }

    /// 射线法判断点是否在多边形内
    private func polygonContains(_ polygon: [CGPoint], _ point: CGPoint) -> Bool {
        guard polygon.count >= 3 else { return false }

        var inside = false
        var previousIndex = polygon.count - 1

        for index in polygon.indices {
            let a = polygon[index]
            let b = polygon[previousIndex]

            if (a.y > point.y) != (b.y > point.y) {
                let crossingX = (b.x - a.x) * (point.y - a.y) / (b.y - a.y) + a.x
                if point.x < crossingX {
                    inside.toggle()
                }
            }
            previousIndex = index
        }
        return inside
    }

    // MARK: - 外观

    private func isFound(_ value: Int) -> Bool {
        value < nextExpected
    }

    private func fillColor(for cell: BoardCell) -> Color {
        if flashingNumber == cell.value { return Color.red.opacity(0.30) }
        if isFound(cell.value) { return tint.opacity(0.16) }
        // 相邻块深浅交替，让拼块边界更清楚
        return Color.white.opacity(cell.id.isMultiple(of: 2) ? 0.10 : 0.065)
    }

    private func borderColor(for cell: BoardCell) -> Color {
        if flashingNumber == cell.value { return .red }
        if isFound(cell.value) { return tint.opacity(0.40) }
        return Color.white.opacity(0.13)
    }

    private func textColor(for cell: BoardCell) -> Color {
        if flashingNumber == cell.value { return .white }
        if isFound(cell.value) { return tint.opacity(0.55) }
        return .white
    }

    private func fontSize(for cell: BoardCell, radius: CGFloat) -> CGFloat {
        let cellInradius = cell.inradius * radius
        guard cellInradius > 0 else { return 14 }

        // 两位数的字更宽，稍微收一点
        let digitsScale: CGFloat = cell.value >= 10 ? 0.92 : 1.0
        let raw = cellInradius * 1.25 * digitsScale
        return max(11, min(raw, 40))
    }
}

#Preview {
    ZStack {
        PFCScreenBackground()
        NumberBoard(
            cells: BoardLayout.make(count: 20, seed: 12345),
            nextExpected: 6,
            tint: .cyan,
            flashingNumber: nil,
            onTap: { _ in }
        )
        .padding(20)
    }
    .preferredColorScheme(.dark)
}
