import SwiftUI

/// 训练页：5 秒倒计时 → 开始计时 → 顺序点完全部数字 → 点击停止
struct TrainingView: View {
    let difficulty: Difficulty

    @Environment(\.dismiss) private var dismiss

    @State private var numbers: [Int] = []
    @State private var nextExpected = 1
    @State private var runID = UUID()
    @State private var phase: Phase = .countdown
    @State private var countdownValue = 5
    @State private var startedAt: Date?
    @State private var elapsed: TimeInterval = 0
    @State private var mistakes = 0
    @State private var flashingNumber: Int?
    @State private var result: SessionResult?

    private enum Phase {
        case countdown
        case running
        case stopped
    }

    private var total: Int { difficulty.numberCount }
    private var foundCount: Int { min(max(nextExpected - 1, 0), total) }
    private var remaining: Int { max(total - foundCount, 0) }
    private var allFound: Bool { remaining == 0 }

    var body: some View {
        ZStack {
            PFCScreenBackground()

            VStack(spacing: 18) {
                topBar
                statusPanel

                NumberGrid(
                    numbers: numbers,
                    columns: difficulty.columns,
                    nextExpected: nextExpected,
                    tint: difficulty.tint,
                    flashingNumber: flashingNumber,
                    onTap: handleTap
                )
                .allowsHitTesting(phase == .running)
                .padding(.horizontal, 16)

                Spacer(minLength: 0)
                stopButton
                    .padding(.horizontal, 20)
            }
            .padding(.bottom, 20)

            if phase == .countdown {
                countdownOverlay
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .task(id: runID) { await runSession() }
        .sheet(item: $result) { value in
            ResultView(
                result: value,
                onRetry: {
                    result = nil
                    restart()
                },
                onExit: {
                    result = nil
                    dismiss()
                }
            )
        }
    }

    // MARK: - 子视图

    private var topBar: some View {
        ZStack {
            VStack(spacing: 2) {
                Text(difficulty.title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(difficulty.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            HStack {
                CircleIconButton(systemName: "xmark") { dismiss() }
                Spacer()
                CircleIconButton(systemName: "arrow.clockwise") { restart() }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var statusPanel: some View {
        VStack(spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(TimeFormat.plain(elapsed))
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(phase == .running ? Color.white : Color.white.opacity(0.85))
                Text("秒")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 6) {
                ProgressView(value: Double(foundCount), total: Double(total))
                    .tint(difficulty.tint)

                HStack {
                    Text("已找 \(foundCount)/\(total)")
                    Spacer()
                    Text(mistakes > 0 ? "失误 \(mistakes)" : "零失误")
                        .foregroundStyle(mistakes > 0 ? Color.orange : Color.secondary)
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 40)
        }
    }

    private var stopButton: some View {
        Button(action: stop) {
            HStack(spacing: 8) {
                Image(systemName: allFound ? "stop.circle.fill" : "hourglass")
                Text(allFound ? "全部找到 · 点击停止" : "还剩 \(remaining) 个数字")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        allFound
                            ? AnyShapeStyle(Color.green.gradient)
                            : AnyShapeStyle(Color.white.opacity(0.08))
                    )
            )
            .foregroundStyle(allFound ? Color.black.opacity(0.85) : Color.white.opacity(0.45))
            .shadow(color: Color.green.opacity(allFound ? 0.35 : 0), radius: 18, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(!allFound || phase != .running)
        .animation(.snappy, value: allFound)
    }

    private var countdownOverlay: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Text("准备好")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)

                Text("\(countdownValue)")
                    .font(.system(size: 128, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(difficulty.tint)
                    .contentTransition(.numericText(countsDown: true))

                Text("按 1 → \(total) 的顺序点选数字")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .transition(.opacity)
    }

    // MARK: - 交互

    private func handleTap(_ number: Int) {
        guard phase == .running else { return }

        if number == nextExpected {
            withAnimation(.snappy(duration: 0.18)) {
                nextExpected += 1
            }
            if nextExpected > total {
                Haptics.success()
            } else {
                Haptics.light()
            }
        } else if number > nextExpected {
            // 点错了：记一次失误并闪烁提示
            mistakes += 1
            Haptics.error()
            withAnimation(.easeOut(duration: 0.12)) {
                flashingNumber = number
            }
            Task {
                try? await Task.sleep(for: .milliseconds(320))
                if flashingNumber == number {
                    withAnimation(.easeOut(duration: 0.25)) {
                        flashingNumber = nil
                    }
                }
            }
        }
        // number < nextExpected：已经找过，忽略
    }

    private func stop() {
        guard phase == .running, allFound else { return }

        if let startedAt {
            elapsed = Date.now.timeIntervalSince(startedAt)
        }
        phase = .stopped
        Haptics.success()

        let isNewRecord = BestTimeStorage.submit(elapsed, for: difficulty)
        result = SessionResult(
            difficulty: difficulty,
            duration: elapsed,
            mistakes: mistakes,
            isNewRecord: isNewRecord
        )
    }

    private func restart() {
        numbers = (1...total).shuffled()
        nextExpected = 1
        mistakes = 0
        flashingNumber = nil
        elapsed = 0
        startedAt = nil
        countdownValue = 5
        phase = .countdown
        runID = UUID()
    }

    // MARK: - 计时流程

    @MainActor
    private func runSession() async {
        // 重置本轮状态
        numbers = (1...total).shuffled()
        nextExpected = 1
        mistakes = 0
        flashingNumber = nil
        elapsed = 0
        startedAt = nil
        result = nil
        countdownValue = 5
        phase = .countdown

        // 5 秒倒计时：5 → 4 → 3 → 2 → 1
        for value in stride(from: 5, through: 1, by: -1) {
            if Task.isCancelled { return }
            withAnimation(.snappy) { countdownValue = value }
            try? await Task.sleep(for: .seconds(1))
        }

        if Task.isCancelled { return }

        // 开始计时
        startedAt = Date.now
        elapsed = 0
        Haptics.medium()
        withAnimation(.easeOut(duration: 0.2)) { phase = .running }

        // 计时刷新（约 30fps）
        while !Task.isCancelled, phase == .running {
            if let startedAt {
                elapsed = Date.now.timeIntervalSince(startedAt)
            }
            try? await Task.sleep(for: .milliseconds(33))
        }
    }
}

private struct CircleIconButton: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color.white.opacity(0.08)))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        TrainingView(difficulty: .advanced)
    }
    .preferredColorScheme(.dark)
}
