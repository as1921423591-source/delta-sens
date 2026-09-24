import SwiftUI
import CoreMotion

// MARK: - 测试三：陀螺仪追踪
struct GyroTestCard: View {
    @Binding var result: GyroTestResult
    private let motion = CMMotionManager()
    @State private var running = false
    @State private var cx: CGFloat = 0
    @State private var cy: CGFloat = 0
    @State private var timeLeft: Double = 10
    @State private var elapsed: Double = 0
    @State private var onTargetTime: Double = 0
    @State private var horizSum: Double = 0
    @State private var sampleCount: Int = 0
    @State private var baseGamma: Double?
    @State private var baseBeta: Double?
    @State private var timer: Timer?

    var body: some View {
        TestCard(icon: "📱", title: "测试三 · 陀螺仪追踪", done: result.done) {
            Text("手持手机，通过左右倾斜手机控制准星，追踪移动靶子。测10秒。")
                .font(.system(size: 12)).foregroundColor(.secondary)

            GeometryReader { geo in
                let w = geo.size.width, h = geo.size.height
                let tx = w/2 + CGFloat(sin(elapsed*1.5)) * w * 0.3
                let ty = h/2
                let dist = hypot(cx-tx, cy-ty)
                let onTarget = dist < 30

                ZStack {
                    Color.black.opacity(0.6)
                    Circle()
                        .fill(onTarget ? Color.green.opacity(0.3) : Color.white.opacity(0.08))
                        .frame(width: 56, height: 56)
                        .position(x: tx, y: ty)
                    Crosshair(color: onTarget ? .green : .green.opacity(0.6))
                        .position(x: cx, y: cy)
                }
                .frame(width: w, height: h)
                .clipped()
                .overlay(alignment: .top) {
                    HStack {
                        pill("剩余 \(String(format: "%.1f", timeLeft))s")
                        pill("精度 \(Int(clamp(onTargetTime/elapsed*100, 0, 100)))%")
                        pill("水平偏移 \(sampleCount > 0 ? Int(horizSum/Double(sampleCount)) : 0)px")
                        Spacer()
                    }.padding(8).font(.system(size: 11, weight: .medium))
                }
                .onAppear { if !running { cx = w/2; cy = h/2 } }
                .onChange(of: elapsed) { _ in
                    guard running else { return }
                    if onTarget { onTargetTime += 1/60 }
                    horizSum += abs(Double(cx - tx))
                    sampleCount += 1
                }
            }
            .frame(height: 200)
            .overlay {
                if !running {
                    Button("开始测试") { start() }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    private func pill(_ s: String) -> some View {
        Text(s).padding(.horizontal, 8).padding(.vertical, 3)
            .background(Color.white.opacity(0.08)).cornerRadius(10)
    }

    private func start() {
        cx = UIScreen.main.bounds.width/2
        cy = 100
        elapsed = 0; onTargetTime = 0; horizSum = 0; sampleCount = 0; timeLeft = 10
        baseGamma = nil; baseBeta = nil
        running = true

        motion.deviceMotionUpdateInterval = 1/60
        motion.startDeviceMotionUpdates(to: .main) { dm, _ in
            guard let dm = dm, running else { return }
            if self.baseGamma == nil { self.baseGamma = dm.rotationRate.x }
            if self.baseBeta == nil { self.baseBeta = dm.rotationRate.y }
            let dg = dm.rotationRate.x - (self.baseGamma ?? 0)
            let db = dm.rotationRate.y - (self.baseBeta ?? 0)
            // rotationRate 是角速度 rad/s，乘以系数转成像素位移
            cx = min(max(cx + CGFloat(dg * 30), 0), UIScreen.main.bounds.width)
            cy = min(max(cy - CGFloat(db * 20), 0), 200)
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
        result = GyroTestResult(done: true, accuracy: acc, horizontalOffset: hOff)
    }

    private func clamp(_ v: Double, _ a: Double, _ b: Double) -> Double {
        Swift.max(a, Swift.min(b, v))
    }
}
