import SwiftUI

struct ResultView: View {
    let result: SensitivityResult
    let tips: [String]
    let showGyro: Bool
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("🏆 专属灵敏度方案")
                .font(.system(size: 18, weight: .heavy))
                .foregroundColor(.white)

            section("📱 滑屏灵敏度（手搓）") {
                row("转向模式", result.turnMode)
                row("镜头加速度", "\(result.cameraAcceleration)")
                row("开火加速度", "\(result.fireAcceleration)")
                row("总滑屏灵敏度", "\(result.touchTotal)")
                row("滑屏MDV", String(format: "%.2f", result.touchMDV))
                row("总滑屏垂直灵敏度", "\(result.touchVertical)")
                row("总滑屏水平灵敏度", "\(result.touchHorizontal)")
                row("总开火灵敏度", "\(result.touchFireTotal)")
                row("滑屏开火MDV", String(format: "%.2f", result.touchFireMDV))
                row("总开火垂直灵敏度", "\(result.touchFireVertical)")
                row("总开火水平灵敏度", "\(result.touchFireHorizontal)")

                scopeTable(result.touchScope)
            }

            if showGyro {
                section("📱 陀螺仪灵敏度") {
                    row("陀螺仪灵敏度", "\(result.gyroTotal)")
                    row("陀螺仪MDV", String(format: "%.2f", result.gyroMDV))
                    row("陀螺仪垂直灵敏度", "\(result.gyroVertical)")
                    row("陀螺仪水平灵敏度", "\(result.gyroHorizontal)")
                    row("陀螺仪开火灵敏度", "\(result.gyroFireTotal)")
                    row("陀螺仪开火MDV", String(format: "%.2f", result.gyroFireMDV))
                    row("陀螺仪开火垂直灵敏度", "\(result.gyroFireVertical)")
                    row("陀螺仪开火水平灵敏度", "\(result.gyroFireHorizontal)")

                    scopeTable(result.gyroScope)
                }
            }

            ForEach(tips, id: \.self) { t in
                Text("💡 \(t)")
                    .font(.system(size: 13))
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.1))
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.orange, lineWidth: 1).padding(.vertical, -8))
                    .cornerRadius(8)
            }

            Button {
                copy()
            } label: {
                Text(copied ? "✅ 已复制" : "📋 一键复制全部参数")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.orange)
                    .cornerRadius(12)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(red: 0.07, green: 0.09, blue: 0.15)))
    }

    private func section<Content: View>(_ title: String, @ViewBuilder _ c: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 14, weight: .bold)).foregroundColor(.orange)
            Divider().background(Color.gray.opacity(0.3))
            c()
        }
    }

    private func row(_ n: String, _ v: String) -> some View {
        HStack {
            Text(n).font(.system(size: 13)).foregroundColor(.secondary)
            Spacer()
            Text(v).font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundColor(.orange)
        }
        .padding(.vertical, 4)
    }

    private func scopeTable(_ rows: [ScopeRow]) -> some View {
        VStack(spacing: 2) {
            HStack {
                Text("倍镜").font(.system(size: 12, weight: .bold)).foregroundColor(.orange)
                Spacer()
                Text("镜头").font(.system(size: 12, weight: .bold)).foregroundColor(.orange)
                Text("开火").font(.system(size: 12, weight: .bold)).foregroundColor(.orange)
                    .frame(width: 40, alignment: .trailing)
            }
            Divider()
            ForEach(rows) { r in
                HStack {
                    Text(r.name).font(.system(size: 12)).foregroundColor(.secondary)
                    Spacer()
                    Text("\(r.camera)").font(.system(size: 12, design: .monospaced))
                    Text("\(r.fire)").font(.system(size: 12, design: .monospaced))
                        .frame(width: 40, alignment: .trailing)
                }
            }
        }
    }

    private func copy() {
        var t = "【三角洲灵敏度方案】\n\n═══ 滑屏灵敏度 ═══\n"
        t += "转向模式：\(result.turnMode)\n"
        t += "镜头加速度：\(result.cameraAcceleration)\n"
        t += "开火加速度：\(result.fireAcceleration)\n"
        t += "总滑屏灵敏度：\(result.touchTotal)\n"
        t += "滑屏MDV：\(String(format: "%.2f", result.touchMDV))\n"
        t += "总滑屏垂直：\(result.touchVertical)\n"
        t += "总滑屏水平：\(result.touchHorizontal)\n"
        t += "总开火灵敏度：\(result.touchFireTotal)\n"
        t += "滑屏开火MDV：\(String(format: "%.2f", result.touchFireMDV))\n"
        t += "总开火垂直：\(result.touchFireVertical)\n"
        t += "总开火水平：\(result.touchFireHorizontal)\n\n"
        t += "【倍镜灵敏度】\n倍镜\t镜头\t开火\n"
        result.touchScope.forEach { t += "\($0.name)\t\($0.camera)\t\($0.fire)\n" }

        if showGyro {
            t += "\n═══ 陀螺仪灵敏度 ═══\n"
            t += "陀螺仪灵敏度：\(result.gyroTotal)\n"
            t += "陀螺仪MDV：\(String(format: "%.2f", result.gyroMDV))\n"
            t += "陀螺仪垂直：\(result.gyroVertical)\n"
            t += "陀螺仪水平：\(result.gyroHorizontal)\n"
            t += "陀螺仪开火灵敏度：\(result.gyroFireTotal)\n"
            t += "陀螺仪开火MDV：\(String(format: "%.2f", result.gyroFireMDV))\n"
            t += "陀螺仪开火垂直：\(result.gyroFireVertical)\n"
            t += "陀螺仪开火水平：\(result.gyroFireHorizontal)\n\n"
            t += "【陀螺仪倍镜灵敏度】\n倍镜\t镜头\t开火\n"
            result.gyroScope.forEach { t += "\($0.name)\t\($0.camera)\t\($0.fire)\n" }
        }

        UIPasteboard.general.string = t
        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now()+2) { copied = false }
    }
}
