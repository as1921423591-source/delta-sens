import SwiftUI
import CoreMotion

// MARK: - 测试三：陀螺仪追踪（全屏横屏，同时测水平+垂直偏移）
struct GyroTestFull: View {
    @Binding var result: GyroTestResult
    let onDone: () -> Void

    private let motion = CMMotionManager()
    @State private var running = false
    @State private var cx: CGFloat = 0
    @State private var cy: CGFloat = 0
    @State private var timeLeft: Double = 10
    @State private var elapsed: Double = 0
    @State private var onTargetTime: Double = 0
    @State private var horizSum: Double = 0
    @State private var vertSum: Double = 0
    @State private var sampleCount: Int = 0
    @State private var baseX: Double?
    @State private var baseY: Double?
    @State private var timer: Timer?

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            // 靶子走对角线轨迹，同时考验水平和垂直
            let tx = w/2 + CGFloat(sin(elapsed*1.2)) * w * 0.3
            let ty = h/2 + CGFloat(sin(elapsed*1.8)) * h * 0.25
            let dist = hypot(cx-tx, cy-ty)
            let onTarget = dist < 35

            ZStack {
                Color.black.ignoresSafeArea()

                if running {
                    Circle()
                        .fill(onTarget ? Color.green.opacity(0.3) : Color.white.opacity(0.08))
                        .frame(width: 60, height: 60)
                        .position(x: tx, y: ty)
                    Crosshair(color: onTarget ? .green : .green.opacity(0.6))
                        .position(x: cx, y: cy)

                    VStack {
                        HStack {
                            pill("剩余 \(String(format: "%.1f", timeLeft))s")
                            pill("精度 \(Int(clamp(onTargetTime/elapsed*100, 0, 100)))%")
                            pill("水平偏移 \(sampleCount > 0 ? Int(horizSum/Double(sampleCount)) : 0)px")
                            pill("垂直偏移 \(sampleCount > 0 ? Int(vertSum/Double(sampleCount)) : 0)px")
                            Spacer()
                        }.padding()
                        Spacer()
                    }
                } else {
                    VStack(spacing: 16) {
                        Text("测试三 · 陀螺仪追踪").font(.system(size: 28, weight: .heavy)).foregroundColor(.white)
                        Text("横握手机，倾斜手机控制准星\n靶子走对角线，同时考验水平和垂直\n握稳手机，测10秒")
                            .font(.system(size: 16)).foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("开始") { start(w: w, h: h) }
                            .buttonStyle(.borderedProminent).controlSize(.large)
                    }
                }
            }
            .onChange(of: elapsed) { _ in
                guard running else { return }
                if onTarget { onTargetTime += 1/60 }
                horizSum += abs(Double(cx - tx))
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
        elapsed = 0; onTargetTime = 0; horizSum = 0; vertSum = 0; sampleCount = 0; timeLeft = 10
        baseX = nil; baseY = nil
        running = true

        motion.deviceMotionUpdateInterval = 1/60
        motion.startDeviceMotionUpdates(to: .main) { dm, _ in
            guard let dm = dm, running else { return }
            if self.baseX == nil { self.baseX = dm.rotationRate.x }
            if self.baseY == nil { self.baseY = dm.rotationRate.y }
            let dx = dm.rotationRate.x - (self.baseX ?? 0)
            let dy = dm.rotationRate.y - (self.baseY ?? 0)
            // 横屏：rotationRate.x = 横摇（左右），rotationRate.y = 俯仰（上下）
            cx = min(max(cx + CGFloat(dx * 30), 0), w)
            cy = min(max(cy - CGFloat(dy * 20), 0), h)
        }

        timer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { t in
            elapsed += 1/60
            timeLeft -= 1/60
            if timeLeft <= 0 { finish() }
        }
    }

    private func finish() {
        timer?.invalidate()
        motion.stopDeviceMotionUpdates()
        running = false
        let acc = clamp(onTargetTime/10*100, 0, 100)
        let hOff = sampleCount > 0 ? horizSum/Double(sampleCount) : 0
        let vOff = sampleCount > 0 ? vertSum/Double(sampleCount) : 0
        result = GyroTestResult(done: true, accuracy: acc, horizontalOffset: hOff, verticalOffset: vOff)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { onDone() }
    }

    private func clamp(_ v: Double, _ a: Double, _ b: Double) -> Double {
        Swift.max(a, Swift.min(b, v))
    }
}
