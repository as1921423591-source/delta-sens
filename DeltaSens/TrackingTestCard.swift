import SwiftUI
import CoreMotion

// MARK: - 测试二：手搓追踪
struct TrackingTestCard: View {
    @Binding var result: TrackingTestResult
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
        TestCard(icon: "📡", title: "测试二 · 手搓追踪", done: result.done) {
            Text("靶子左右来回移动，滑动屏幕让准星贴住靶子。测10秒。")
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
                        .fill(onTarget ? Color.orange.opacity(0.3) : Color.white.opacity(0.08))
                        .frame(width: 56, height: 56)
                        .position(x: tx, y: ty)
                    Crosshair(color: onTarget ? .orange : .orange.opacity(0.6))
                        .position(x: cx, y: cy)
                }
                .frame(width: w, height: h)
                .clipped()
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { v in
                            guard running else { return }
                            let p = v.location
                            if let lt = lastTouch {
                                cx = min(max(cx + (p.x-lt.x)*1.5, 0), w)
                                cy = min(max(cy + (p.y-lt.y)*1.5, 0), h)
                            }
                            lastTouch = p
                        }
                        .onEnded { _ in lastTouch = nil }
                )
                .overlay(alignment: .top) {
                    HStack {
                        pill("剩余 \(String(format: "%.1f", timeLeft))s")
                        pill("精度 \(Int(clamp(onTargetTime/elapsed*100, 0, 100)))%")
                        pill("垂直偏移 \(sampleCount > 0 ? Int(vertSum/Double(sampleCount)) : 0)px")
                        Spacer()
                    }.padding(8).font(.system(size: 11, weight: .medium))
                }
                .onAppear {
                    if !running { cx = w/2; cy = h/2 }
                }
                .onChange(of: elapsed) { _ in
                    guard running else { return }
                    if onTarget { onTargetTime += 1/60 }
                    vertSum += abs(Double(cy - ty))
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
    }

    private func clamp(_ v: Double, _ a: Double, _ b: Double) -> Double {
        Swift.max(a, Swift.min(b, v))
    }
}
