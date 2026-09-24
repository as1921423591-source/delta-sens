import SwiftUI

// MARK: - 测试一：手搓定位
struct AimTestCard: View {
    @Binding var result: AimTestResult
    @State private var running = false
    @State private var cx: CGFloat = 0
    @State private var cy: CGFloat = 0
    @State private var target: CGPoint = .zero
    @State private var targetR: CGFloat = 28
    @State private var timeLeft: Double = 10
    @State private var hits = 0
    @State private var overshoots = 0
    @State private var lastTouch: CGPoint?
    @State private var lastSpeed: CGFloat = 0
    @State private var timer: Timer?

    var body: some View {
        TestCard(icon: "🎯", title: "测试一 · 手搓定位", done: result.done) {
            Text("手指在屏幕滑动控制准星，碰到橙色靶子算命中。测10秒。")
                .font(.system(size: 12)).foregroundColor(.secondary)

            GeometryReader { geo in
                ZStack {
                    Color.black.opacity(0.6)
                    if running {
                        Circle()
                            .fill(Color.orange.opacity(0.25))
                            .frame(width: targetR*2, height: targetR*2)
                            .position(target)
                        Crosshair(color: .orange)
                            .position(x: cx, y: cy)
                    } else {
                        Button("开始测试") { start(size: geo.size) }
                            .buttonStyle(.borderedProminent)
                    }
                }
                .frame(height: geo.size.width * 0.56)
                .clipped()
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { v in
                            guard running else { return }
                            let p = v.location
                            if let lt = lastTouch {
                                let dx = p.x - lt.x, dy = p.y - lt.y
                                cx = min(max(cx + dx*1.5, 0), geo.size.width)
                                cy = min(max(cy + dy*1.5, 0), geo.size.height)
                                lastSpeed = hypot(dx, dy)
                            }
                            lastTouch = p
                            checkHit(size: geo.size)
                        }
                        .onEnded { _ in lastTouch = nil }
                )
                .overlay(alignment: .top) { hud }
            }
            .frame(height: 200)
        }
    }

    private var hud: some View {
        HStack {
            pill("剩余 \(String(format: "%.1f", timeLeft))s")
            pill("命中 \(hits)")
            pill("过冲 \(hits > 0 ? Int(Double(overshoots)/Double(hits)*100) : 0)%")
            Spacer()
        }
        .padding(8)
        .font(.system(size: 11, weight: .medium))
    }

    private func pill(_ s: String) -> some View {
        Text(s).padding(.horizontal, 8).padding(.vertical, 3)
            .background(Color.white.opacity(0.08)).cornerRadius(10)
    }

    private func start(size: CGSize) {
        cx = size.width/2; cy = size.height/2
        hits = 0; overshoots = 0; timeLeft = 10
        spawnTarget(size: size)
        running = true
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { t in
            timeLeft -= 0.1
            if timeLeft <= 0 { finish() }
        }
    }

    private func spawnTarget(size: CGSize) {
        let pad: CGFloat = 40
        targetR = max(22, size.width * 0.05)
        target = CGPoint(
            x: pad + CGFloat.random(in: 0...1) * (size.width - pad*2),
            y: pad + CGFloat.random(in: 0...1) * (size.height - pad*2)
        )
    }

    private func checkHit(size: CGSize) {
        let d = hypot(cx - target.x, cy - target.y)
        if d < targetR {
            hits += 1
            if lastSpeed > 25 { overshoots += 1 }
            spawnTarget(size: size)
        }
    }

    private func finish() {
        timer?.invalidate()
        running = false
        result = AimTestResult(
            done: true,
            hits: hits,
            overshootRate: hits > 0 ? Double(overshoots)/Double(hits) : 0
        )
    }
}

struct Crosshair: View {
    let color: Color
    var body: some View {
        ZStack {
            Path { p in
                p.move(to: CGPoint(x: -10, y: 0)); p.addLine(to: CGPoint(x: -4, y: 0))
                p.move(to: CGPoint(x: 4, y: 0)); p.addLine(to: CGPoint(x: 10, y: 0))
                p.move(to: CGPoint(x: 0, y: -10)); p.addLine(to: CGPoint(x: 0, y: -4))
                p.move(to: CGPoint(x: 0, y: 4)); p.addLine(to: CGPoint(x: 0, y: 10))
            }.stroke(color, lineWidth: 2)
            Circle().fill(color).frame(width: 3, height: 3)
        }
        .frame(width: 20, height: 20)
    }
}
