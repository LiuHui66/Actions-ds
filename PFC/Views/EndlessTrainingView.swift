import SwiftUI

/// 无限模式：每一轮都是独立的一关
///
/// 规则：
/// - 第 1 轮 10 个数字（1 → 10），限时 100 秒，开局有 5 秒倒计时
/// - 清空这一轮 → 下一轮 15 个数字，**数字从 1 重新开始、板面全部重置、倒计时重置回 100 秒**
/// - 依次 10 → 15 → 20 → 25 …，直到某一轮时间归零
/// - 时间归零自动结算（不需要手动停止）
struct EndlessTrainingView: View {
    @Environment(\.dismiss) private var dismiss

    /// 当前这一轮的拼块
    @State private var cells: [BoardCell] = []

    /// 当前第几轮（从 1 开始）
    @State private var round = 1
    /// 当前这一轮的数字个数
    @State private var boardTotal = EndlessRules.initialCount
    /// 当前这一轮下一个该点的数字（每轮回到 1）
    @State private var nextExpected = 1
    /// 当前这一轮已经找出多少个
    @State private var clearedInRound = 0
    /// 跨轮累计找出多少个
    @State private var clearedTotal = 0
    /// 已完整清空的轮数
    @State private var roundsCompleted = 0
    @State private var mistakes = 0
    @State private var flashingNumber: Int?

    @State private var phase: Phase = .countdown
    @State private var countdownValue = EndlessRules.countdownSeconds

    /// 当前这一轮的开始时间（每轮重置）
    @State private var roundStartedAt: Date?
    /// 已结束各轮的累计用时
    @State private var elapsedBefore: TimeInterval = 0
    /// 当前这一轮剩余时间
    @State private var roundRemaining = EndlessRules.roundDuration

    /// 进入新一轮时的提示文字
    @State private var roundFlash: String?

    @State private var result: EndlessResult?
    @State private var runID = UUID()

    private enum Phase {
        case countdown
        case running
        case stopped
    }

    /// 本局到目前为止的总用时（含正在进行的这一轮）
    private var elapsedTotal: TimeInterval {
        elapsedBefore + max(EndlessRules.roundDuration - roundRemaining, 0)
    }

    /// 板面上还没找到的个数
    private var remainingOnBoard: Int {
        max(boardTotal - clearedInRound, 0)
    }

    private var formattedRemaining: String {
        String(format: "%.1f", max(roundRemaining, 0))
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
                .overlay(alignment: .top) { roundFlashView }

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
            Text("第 \(round) 轮 · \(boardTotal) 个数字")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.purple)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.purple.opacity(0.16)))
                .animation(.snappy, value: round)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(formattedRemaining)
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(roundRemaining <= 20 ? Color.orange : Color.white)
                Text("秒")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 6) {
                ProgressView(value: Double(clearedInRound), total: Double(max(boardTotal, 1)))
                    .tint(.purple)

                HStack {
                    Text("本轮 \(clearedInRound)/\(boardTotal)")
                    Spacer()
                    Text(mistakes > 0 ? "失误 \(mistakes)" : "零失误")
                        .foregroundStyle(mistakes > 0 ? Color.orange : Color.secondary)
                }
                .font(.footnote)
                .foregroundStyle(.secondary)

                HStack {
                    Text("累计 \(clearedTotal) 个")
                    Spacer()
                    Text("已清空 \(roundsCompleted) 轮")
                }
                .font(.caption2)
                .foregroundStyle(.secondary.opacity(0.85))
            }
            .padding(.horizontal, 40)
        }
    }

    /// 底部状态条（只展示）
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

    private var roundFlashView: some View {
        Group {
            if let roundFlash {
                Text(roundFlash)
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(.purple)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.purple.opacity(0.16)))
                    .overlay(Capsule().strokeBorder(Color.purple.opacity(0.35), lineWidth: 1))
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

                Text("第 1 轮 \(EndlessRules.initialCount) 个数字 · 限时 \(Int(EndlessRules.roundDuration)) 秒")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Text("清空一轮就 +\(EndlessRules.increment) 个，数字与时间全部重置")
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
        if roundRemaining <= 0 {
            finish()
            return
        }

        if number == nextExpected {
            clearedInRound += 1
            clearedTotal += 1
            nextExpected += 1
            Haptics.light()

            if clearedInRound >= boardTotal {
                finishRound()
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

    /// 清空这一轮 → 进入下一轮：数字从 1 重置、板面重画、倒计时重置
    private func finishRound() {
        guard phase == .running else { return }

        // 记下这一轮实际花了多久
        if let roundStartedAt {
            elapsedBefore += Date.now.timeIntervalSince(roundStartedAt)
        }
        roundsCompleted += 1
        round += 1

        let newTotal = EndlessRules.roundSize(round)
        Haptics.success()

        withAnimation(.snappy(duration: 0.28)) {
            boardTotal = newTotal
            nextExpected = 1          // 数字从 1 重新开始
            clearedInRound = 0        // 本轮进度清零
            roundRemaining = EndlessRules.roundDuration   // 时间重置
            cells = BoardLayout.make(count: newTotal, seed: UInt64.random(in: 1...UInt64.max))
        }

        // 新一轮从此刻重新计时
        roundStartedAt = Date.now

        showRoundFlash("第 \(round) 轮 · \(newTotal) 个")
    }

    private func showRoundFlash(_ text: String) {
        withAnimation(.snappy) { roundFlash = text }
        Task {
            try? await Task.sleep(for: .milliseconds(1000))
            withAnimation(.easeOut(duration: 0.3)) { roundFlash = nil }
        }
    }

    /// 时间耗尽 → 冻结成绩 → 弹出结算
    private func finish() {
        guard phase == .running else { return }

        let finalCleared = clearedTotal
        let finalRounds = roundsCompleted
        let finalMistakes = mistakes
        let finalBoard = boardTotal
        let finalElapsed = elapsedTotal
        let capturedRunID = runID

        phase = .stopped
        roundRemaining = 0
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
                elapsed: finalElapsed,
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
        round = 1
        boardTotal = EndlessRules.initialCount
        nextExpected = 1
        clearedInRound = 0
        clearedTotal = 0
        roundsCompleted = 0
        mistakes = 0
        flashingNumber = nil
        roundFlash = nil
        roundRemaining = EndlessRules.roundDuration
        elapsedBefore = 0
        roundStartedAt = nil
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

        roundStartedAt = Date.now
        roundRemaining = EndlessRules.roundDuration
        Haptics.medium()
        withAnimation(.easeOut(duration: 0.2)) { phase = .running }

        // 倒计时刷新（约 20fps）；时间归零后 phase 变为 .stopped，循环自动结束
        // 每清空一轮 roundStartedAt 会被重置，倒计时自然回到 100 秒
        while !Task.isCancelled, phase == .running {
            if let roundStartedAt {
                roundRemaining = max(EndlessRules.roundDuration - Date.now.timeIntervalSince(roundStartedAt), 0)
            }
            if roundRemaining <= 0 {
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
