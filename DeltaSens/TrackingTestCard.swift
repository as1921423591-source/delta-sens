import SwiftUI

// MARK: - 测试二：手搓追踪（全屏横屏，右半屏控制）
struct TrackTestFull: View {
    @Binding var result: TrackingTestResult
    let onDone: () -> Void

    @State private var running = false
    @State private var cx: CGFloat = 0
    @State private var cy: CGFloat = 0
    @State private var timeLeft: Double = 10
    @State private var elapsed: Double = 0
    @State private var onTargetTime: Double = 0
    @State private var vertSum: Double = 0
    @State private var sampleCount: Int = 0
    @State private var lastTouch: CGPoint?
    @State private var timer: Timer?

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let tx = w/2 + CGFloat(sin(elapsed*1.5)) * w * 0.3
            let ty = h/2
            let dist = hypot(cx-tx, cy-ty)
            let onTarget = dist < 35

            ZStack {
                Color.black.ignoresSafeArea()

                // 左半屏提示
                Rectangle()
                    .fill(Color.white.opacity(0.03))
                    .frame(width: w/2, height: h)
                    .position(x: w/4, y: h/2)
                Text("左半屏（移动区）")
                    .font(.system(size: 14)).foregroundColor(.white.opacity(0.2))
                    .position(x: w/4, y: h/2)

                if running {
                    Circle()
                        .fill(onTarget ? Color.orange.opacity(0.3) : Color.white.opacity(0.08))
                        .frame(width: 60, height: 60)
                        .position(x: tx, y: ty)
                    Crosshair(color: onTarget ? .orange : .orange.opacity(0.6))
                        .position(x: cx, y: cy)

                    VStack {
                        HStack {
                            pill("剩余 \(String(format: "%.1f", timeLeft))s")
                            pill("精度 \(Int(clamp(onTargetTime/elapsed*100, 0, 100)))%")
                            pill("垂直偏移 \(sampleCount > 0 ? Int(vertSum/Double(sampleCount)) : 0)px")
                            Spacer()
                        }.padding()
                        Spacer()
                    }
                } else {
                    VStack(spacing: 16) {
                        Text("测试二 · 手搓追踪").font(.system(size: 28, weight: .heavy)).foregroundColor(.white)
                        Text("靶子左右移动，在屏幕右半区滑动手指\n让准星贴住靶子（左半屏是移动区不用管）\n测10秒")
                            .font(.system(size: 16)).foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("开始") { start(w: w, h: h) }
                            .buttonStyle(.borderedProminent).controlSize(.large)
                    }
                }
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        guard running else { return }
                        let p = v.location
                        // 只响应右半屏触摸
                        guard p.x > w/2 else { return }
                        if let lt = lastTouch {
                            cx = min(max(cx + (p.x-lt.x)*1.5, 0), w)
                            cy = min(max(cy + (p.y-lt.y)*1.5, 0), h)
                        }
                        lastTouch = p
                    }
                    .onEnded { _ in lastTouch = nil }
            )
            .onChange(of: elapsed) { _ in
                guard running else { return }
                if onTarget { onTargetTime += 1/60 }
                vertSum += abs(Double(cy - ty))
                sampleCount += 1
            }
        }
    }

    private func pill(_ s: String) -> some View {
        Text(s).font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(Color.white.opacity(0.1)).cornerRadius(10)
    }

    private func start(w: CGFloat, h: CGFloat) {
        cx = w/2; cy = h/2
        elapsed = 0; onTargetTime = 0; vertSum = 0; sampleCount = 0; timeLeft = 10
        running = true
        timer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { t in
            elapsed += 1/60
            timeLeft -= 1/60
            if timeLeft <= 0 { finish() }
        }
    }

    private func finish() {
        timer?.invalidate()
        running = false
        let acc = clamp(onTargetTime/10*100, 0, 100)
        let vOff = sampleCount > 0 ? vertSum/Double(sampleCount) : 0
        result = TrackingTestResult(done: true, accuracy: acc, verticalOffset: vOff)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { onDone() }
    }

    private func clamp(_ v: Double, _ a: Double, _ b: Double) -> Double {
        Swift.max(a, Swift.min(b, v))
    }
}
