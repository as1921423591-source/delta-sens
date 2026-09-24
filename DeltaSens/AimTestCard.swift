import SwiftUI

// MARK: - 测试一：手搓定位（全屏横屏）
struct AimTestFull: View {
    @Binding var result: AimTestResult
    let onDone: () -> Void

    @State private var running = false
    @State private var cx: CGFloat = 0
    @State private var cy: CGFloat = 0
    @State private var target: CGPoint = .zero
    @State private var targetR: CGFloat = 30
    @State private var timeLeft: Double = 10
    @State private var hits = 0
    @State private var overshoots = 0
    @State private var lastTouch: CGPoint?
    @State private var lastSpeed: CGFloat = 0
    @State private var timer: Timer?

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                Color.black.ignoresSafeArea()

                if running {
                    Circle()
                        .fill(Color.orange.opacity(0.25))
                        .frame(width: targetR*2, height: targetR*2)
                        .position(target)
                    Crosshair(color: .orange)
                        .position(x: cx, y: cy)

                    VStack {
                        HStack {
                            pill("剩余 \(String(format: "%.1f", timeLeft))s")
                            pill("命中 \(hits)")
                            pill("过冲 \(hits > 0 ? Int(Double(overshoots)/Double(hits)*100) : 0)%")
                            Spacer()
                        }
                        .padding()
                        Spacer()
                    }
                } else {
                    VStack(spacing: 16) {
                        Text("测试一 · 手搓定位").font(.system(size: 28, weight: .heavy)).foregroundColor(.white)
                        Text("手指在屏幕任意位置滑动，准星跟着移动\n碰到橙色靶子算命中，自动出下一个\n测10秒")
                            .font(.system(size: 16)).foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("开始") { start(w: w, h: h) }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                    }
                }
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        guard running else { return }
                        let p = v.location
                        if let lt = lastTouch {
                            let dx = p.x - lt.x, dy = p.y - lt.y
                            cx = min(max(cx + dx*1.5, 0), w)
                            cy = min(max(cy + dy*1.5, 0), h)
                            lastSpeed = hypot(dx, dy)
                        }
                        lastTouch = p
                        checkHit(w: w, h: h)
                    }
                    .onEnded { _ in lastTouch = nil }
            )
        }
    }

    private func pill(_ s: String) -> some View {
        Text(s).font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(Color.white.opacity(0.1)).cornerRadius(10)
    }

    private func start(w: CGFloat, h: CGFloat) {
        cx = w/2; cy = h/2
        hits = 0; overshoots = 0; timeLeft = 10
        spawnTarget(w: w, h: h)
        running = true
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { t in
            timeLeft -= 0.1
            if timeLeft <= 0 { finish() }
        }
    }

    private func spawnTarget(w: CGFloat, h: CGFloat) {
        let pad: CGFloat = 60
        targetR = 30
        target = CGPoint(
            x: pad + CGFloat.random(in: 0...1) * (w - pad*2),
            y: pad + CGFloat.random(in: 0...1) * (h - pad*2)
        )
    }

    private func checkHit(w: CGFloat, h: CGFloat) {
        let d = hypot(cx - target.x, cy - target.y)
        if d < targetR {
            hits += 1
            if lastSpeed > 25 { overshoots += 1 }
            spawnTarget(w: w, h: h)
        }
    }

    private func finish() {
        timer?.invalidate()
        running = false
        result = AimTestResult(done: true, hits: hits,
                               overshootRate: hits > 0 ? Double(overshoots)/Double(hits) : 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { onDone() }
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
