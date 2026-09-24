import SwiftUI

struct ContentView: View {
    @State private var device: DeviceType = .phone
    @State private var mode: OperationMode = .handGyro
    @State private var weapon: WeaponType = .ar
    @State private var style: PlayStyle = .balanced

    @State var aimResult = AimTestResult()
    @State var trackResult = TrackingTestResult()
    @State var gyroResult = GyroTestResult()

    @State private var generated: SensitivityResult?
    @State private var tips: [String] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    header

                    settingsCard

                    AimTestCard(result: $aimResult)
                    TrackingTestCard(result: $trackResult)

                    if mode != .hand {
                        GyroTestCard(result: $gyroResult)
                    }

                    generateButton

                    if let g = generated {
                        ResultView(result: g, tips: tips, showGyro: mode != .hand)
                    }
                }
                .padding(16)
                .padding(.bottom, 40)
            }
            .background(Color(red: 0.04, green: 0.05, blue: 0.09).ignoresSafeArea())
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .tint(.orange)
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("三角洲灵敏度助手")
                .font(.system(size: 26, weight: .heavy))
                .foregroundStyle(
                    LinearGradient(colors: [.white, .orange, .orange],
                                   startPoint: .leading, endPoint: .trailing)
                )
            Text("真实交互测试 · 手搓+陀螺仪双参数")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 12)
    }

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            label("设备类型")
            Picker("", selection: $device) {
                ForEach(DeviceType.allCases, id: \.self) { t in Text(t.rawValue).tag(t) }
            }
            .pickerStyle(.segmented)

            label("操作模式")
            Picker("", selection: $mode) {
                ForEach(OperationMode.allCases, id: \.self) { m in Text(m.rawValue).tag(m) }
            }
            .pickerStyle(.segmented)

            label("常用武器")
            Picker("", selection: $weapon) {
                ForEach(WeaponType.allCases, id: \.self) { w in Text(w.rawValue).tag(w) }
            }
            .pickerStyle(.segmented)

            label("打法风格")
            Picker("", selection: $style) {
                ForEach(PlayStyle.allCases, id: \.self) { s in Text(s.rawValue).tag(s) }
            }
            .pickerStyle(.segmented)
        }
        .padding(16)
        .background(cardBg)
    }

    private func label(_ t: String) -> some View {
        Text(t).font(.system(size: 12, weight: .medium)).foregroundColor(.secondary)
    }

    private var generateButton: some View {
        Button {
            let r = SensitivityCalculator.calculate(
                device: device, mode: mode, weapon: weapon, style: style,
                aim: aimResult, track: trackResult, gyro: gyroResult
            )
            generated = r
            tips = SensitivityCalculator.tips(mode: mode, aim: aimResult, track: trackResult, gyro: gyroResult)
        } label: {
            Text("生成我的专属灵敏度")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.orange)
                .cornerRadius(12)
        }
    }

    private var cardBg: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Color(red: 0.07, green: 0.09, blue: 0.15))
    }
}

// MARK: - 通用卡片壳
struct TestCard<Content: View>: View {
    let icon: String
    let title: String
    var done: Bool
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(icon).font(.system(size: 16))
                Text(title).font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                if done {
                    Text("已完成").font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.green).cornerRadius(8)
                        .foregroundColor(.white)
                }
                Spacer()
            }
            content()
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(red: 0.07, green: 0.09, blue: 0.15)))
    }
}
