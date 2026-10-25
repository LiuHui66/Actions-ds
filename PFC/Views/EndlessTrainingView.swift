import SwiftUI

/// 无限模式：100 秒内不断找数字，完成一轮就 +5 个，时间归零自动结算
///
/// 规则细节：
/// - 开局板面 10 个数字（1 → 10），5 秒倒计时后开始计时
/// - 把当前板面上的数字全部按顺序点完 = 完成一轮 → 板面追加 5 个数字（10 → 15 → 20 …）
///   已找过的数字仍然留在板上但变淡，接着找新出现的数字即可
/// - 剩余时间归零 → 立即冻结成绩并弹出结算页（不需要手动停止）
struct EndlessTrainingView: View {
    @Environment(\.dismiss) private var dismiss

    /// 当前这一轮的拼块
    @State private var cells: [BoardCell] = []
    /// 板面上数字总数（每完成一轮 +5）
    @State private var boardTotal = EndlessRules.initialCount
    /// 下一个应该被点到的数字
    @State private var nextExpected = 1
    /// 一共找出了多少个数字
    @State private var clearedCount = 0
    /// 完整清空的轮数
    @State private var roundsCompleted = 0
    @State private var mistakes = 0
    @State private var flashingNumber: Int?

    @State private var phase: Phase = .countdown
    @State private var countdownValue = EndlessRules.countdownSeconds
    @State private var startedAt: Date?
    /// 剩余时间（秒）
    @State private var remaining = EndlessRules.totalDuration

    /// 追加数字时的「+5」提示
    @State private var batchFlash = false

    @State private var result: EndlessResult?
    @State private var runID = UUID()

    private enum Phase {
        case countdown
        case running
        case stopped
    }

    /// 本轮开始前已经找过多少个数字（第 1 轮为 0）
    private var roundStart: Int {
        roundsCompleted == 0 ? 0 : boardTotal - EndlessRules.increment
    }

    /// 本轮已经找出多少个（第 1 轮 0…10，之后 0…5）
    private var clearedThisRound: Int {
        max(clearedCount - roundStart, 0)
    }

    /// 本轮需要找的个数
    private var roundSize: Int {
        max(boardTotal - roundStart, 1)
    }

    /// 板面上还没找到的个数
    private var remainingOnBoard: Int {
        max(boardTotal - clearedCount, 0)
    }

    private var timeLeft: TimeInterval {
        guard let startedAt else { return EndlessRules.totalDuration }
        return max(EndlessRules.totalDuration - Date.now.timeIntervalSince(startedAt), 0)
    }

    private var formattedRemaining: String {
        String(format: "%.1f", max(remaining, 0))
    }

    var body: some View {
        ZStack {
            PFCScreenBackground()

            VStack(spacing: 18) {
                topBar
                statusPanel

                NumberBoard(
                    cells: cells,
                    nextExpected: nextExpected,
                    tint: .purple,
                    flashingNumber: flashingNumber,
                    onTap: handleTap
                )
                .allowsHitTesting(phase == .running)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .top) { batchFlashView }

                footerStatus
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
            EndlessResultView(
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
                Text("无限模式")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(EndlessRules.summary)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            HStack {
                EndlessIconButton(systemName: "xmark") { dismiss() }
                Spacer()
                EndlessIconButton(systemName: "arrow.clockwise") { restart() }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var statusPanel: some View {
        VStack(spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(formattedRemaining)
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(remaining <= 20 ? Color.orange : Color.white)
                Text("秒")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 6) {
                ProgressView(value: Double(clearedThisRound), total: Double(roundSize))
                    .tint(.purple)

                HStack {
                    Text("本轮 \(clearedThisRound)/\(roundSize)")
                    Spacer()
                    Text(mistakes > 0 ? "失误 \(mistakes)" : "零失误")
                        .foregroundStyle(mistakes > 0 ? Color.orange : Color.secondary)
                }
                .font(.footnote)
                .foregroundStyle(.secondary)

                HStack {
                    Text("累计 \(clearedCount) 个")
                    Spacer()
                    Text("完成 \(roundsCompleted) 轮")
                }
                .font(.caption2)
                .foregroundStyle(.secondary.opacity(0.85))
            }
            .padding(.horizontal, 40)
        }
    }

    /// 底部状态条（只展示）：板面上还剩几个数字
    private var footerStatus: some View {
        HStack(spacing: 8) {
            Image(systemName: phase == .running ? "hourglass" : "clock.badge.exclamationmark")
            Text(phase == .running ? "板面 \(boardTotal) 个 · 还剩 \(remainingOnBoard) 个" : "时间到 · 正在结算")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(phase == .running ? Color.white.opacity(0.06) : Color.orange.opacity(0.18))
        )
        .foregroundStyle(phase == .running ? Color.white.opacity(0.55) : Color.orange)
        .animation(.snappy, value: phase)
    }

    private var batchFlashView: some View {
        Group {
            if batchFlash {
                Text("+\(EndlessRules.increment)")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(.purple)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.purple.opacity(0.16)))
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.top, 6)
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
                    .foregroundStyle(.purple)
                    .contentTransition(.numericText(countsDown: true))

                Text("\(Int(EndlessRules.totalDuration)) 秒内找出尽可能多的数字")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Text("每清空一轮自动 +\(EndlessRules.increment) 个数字")
                    .font(.caption2)
                    .foregroundStyle(.secondary.opacity(0.8))
            }
        }
        .transition(.opacity)
    }

    // MARK: - 交互

    private func handleTap(_ number: Int) {
        guard phase == .running else { return }

        // 时间刚好走完的瞬间：直接结算，不再处理这次点击
        if timeLeft <= 0 {
            finish()
            return
        }

        if number == nextExpected {
            clearedCount += 1
            nextExpected += 1
            Haptics.light()

            if clearedCount >= boardTotal {
                addNextBatch()
            }
        } else if number > nextExpected {
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

    /// 清空一轮 → 板面追加 5 个数字，并重新生成一套拼块
    private func addNextBatch() {
        guard phase == .running else { return }

        roundsCompleted += 1
        let newTotal = boardTotal + EndlessRules.increment
        Haptics.success()

        withAnimation(.snappy(duration: 0.28)) {
            boardTotal = newTotal
            cells = BoardLayout.make(count: newTotal, seed: UInt64.random(in: 1...UInt64.max))
        }

        showBatchFlash()
    }

    private func showBatchFlash() {
        withAnimation(.snappy) { batchFlash = true }
        Task {
            try? await Task.sleep(for: .milliseconds(900))
            withAnimation(.easeOut(duration: 0.3)) { batchFlash = false }
        }
    }

    /// 时间耗尽 → 冻结成绩 → 弹出结算
    private func finish() {
        guard phase == .running else { return }

        let finalCleared = clearedCount
        let finalRounds = roundsCompleted
        let finalMistakes = mistakes
        let finalBoard = boardTotal
        let capturedRunID = runID

        phase = .stopped
        remaining = 0
        Haptics.medium()

        Task {
            try? await Task.sleep(for: .milliseconds(360))
            // 期间用户可能点了「重新开始」或退出，用 runID 判断是否仍是同一局
            guard runID == capturedRunID else { return }

            let isNewRecord = EndlessRecordStorage.submit(finalCleared)
            result = EndlessResult(
                clearedCount: finalCleared,
                roundsCompleted: finalRounds,
                mistakes: finalMistakes,
                boardTotal: finalBoard,
                isNewRecord: isNewRecord
            )
        }
    }

    private func restart() {
        countdownValue = EndlessRules.countdownSeconds
        phase = .countdown
        result = nil
        runID = UUID()
    }

    // MARK: - 计时流程

    @MainActor
    private func runSession() async {
        // 重置本局状态
        boardTotal = EndlessRules.initialCount
        nextExpected = 1
        clearedCount = 0
        roundsCompleted = 0
        mistakes = 0
        flashingNumber = nil
        batchFlash = false
        remaining = EndlessRules.totalDuration
        startedAt = nil
        result = nil
        countdownValue = EndlessRules.countdownSeconds
        phase = .countdown
        cells = BoardLayout.make(count: boardTotal, seed: UInt64.random(in: 1...UInt64.max))

        // 5 秒倒计时
        for value in stride(from: EndlessRules.countdownSeconds, through: 1, by: -1) {
            if Task.isCancelled { return }
            withAnimation(.snappy) { countdownValue = value }
            try? await Task.sleep(for: .seconds(1))
        }

        if Task.isCancelled { return }

        startedAt = Date.now
        remaining = EndlessRules.totalDuration
        Haptics.medium()
        withAnimation(.easeOut(duration: 0.2)) { phase = .running }

        // 倒计时刷新（约 20fps）；时间归零后 phase 变为 .stopped，循环自动结束
        while !Task.isCancelled, phase == .running {
            if let startedAt {
                remaining = max(EndlessRules.totalDuration - Date.now.timeIntervalSince(startedAt), 0)
            }
            if remaining <= 0 {
                finish()
                break
            }
            try? await Task.sleep(for: .milliseconds(50))
        }
    }
}

/// 无限模式自己的圆形图标按钮（训练页里那个是 fileprivate，不能跨文件用）
private struct EndlessIconButton: View {
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
        EndlessTrainingView()
    }
    .preferredColorScheme(.dark)
}
