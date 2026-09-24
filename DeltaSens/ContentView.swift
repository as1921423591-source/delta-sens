import SwiftUI

struct ContentView: View {
    @State private var device: DeviceType = .phone
    @State private var mode: OperationMode = .handGyro
    @State private var weapon: WeaponType = .ar
    @State private var style: PlayStyle = .balanced

    @State var aimResult = AimTestResult()
    @State var trackResult = TrackingTestResult()
    @State var gyroResult = GyroTestResult()

    @State private var step = 0
    @State private var generated: SensitivityResult?
    @State private var tips: [String] = []

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.04, green: 0.05, blue: 0.09).ignoresSafeArea()

                if step == 0 { setupView }
                else if step == 1 { AimTestFull(result: $aimResult) { nextStep() } }
                else if step == 2 { TrackTestFull(result: $trackResult) { nextStep() } }
                else if step == 3 { GyroTestFull(result: $gyroResult) { nextStep() } }
                else if step == 4 { resultView }
            }
            .navigationTitle("")
            .navigationBarHidden(step != 0)
        }
        .tint(.orange)
    }

    private var setupView: some View {
        ScrollView {
            VStack(spacing: 14) {
                VStack(spacing: 6) {
                    Text("三角洲灵敏度助手")
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundStyle(LinearGradient(colors: [.white, .orange], startPoint: .leading, endPoint: .trailing))
                    Text("横屏全屏测试 · 手搓+陀螺仪双参数").font(.system(size: 13)).foregroundColor(.secondary)
                }
                .padding(.top, 20)

                settingsCard

                Button {
                    step = 1
                } label: {
                    Text("开始测试（将切换横屏全屏）")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.orange)
                        .cornerRadius(12)
                }
            }
            .padding(16)
        }
    }

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("设备类型").font(.system(size: 12)).foregroundColor(.secondary)
            Picker("", selection: $device) {
                ForEach(DeviceType.allCases, id: \.self) { t in Text(t.rawValue).tag(t) }
            }.pickerStyle(.segmented)

            Text("操作模式").font(.system(size: 12)).foregroundColor(.secondary)
            Picker("", selection: $mode) {
                ForEach(OperationMode.allCases, id: \.self) { m in Text(m.rawValue).tag(m) }
            }.pickerStyle(.segmented)

            Text("常用武器").font(.system(size: 12)).foregroundColor(.secondary)
            Picker("", selection: $weapon) {
                ForEach(WeaponType.allCases, id: \.self) { w in Text(w.rawValue).tag(w) }
            }.pickerStyle(.segmented)

            Text("打法风格").font(.system(size: 12)).foregroundColor(.secondary)
            Picker("", selection: $style) {
                ForEach(PlayStyle.allCases, id: \.self) { s in Text(s.rawValue).tag(s) }
            }.pickerStyle(.segmented)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(red: 0.07, green: 0.09, blue: 0.15)))
    }

    private var resultView: some View {
        ScrollView {
            VStack(spacing: 14) {
                if let g = generated {
                    ResultView(result: g, tips: tips, showGyro: mode != .hand)
                }
                Button("重新测试") { step = 0 }
                    .buttonStyle(.bordered)
            }
            .padding(16)
        }
    }

    private func nextStep() {
        if step == 1 { step = 2 }
        else if step == 2 {
            step = (mode != .hand) ? 3 : 4
            if step == 4 { generate() }
        }
        else if step == 3 { step = 4; generate() }
    }

    private func generate() {
        let r = SensitivityCalculator.calculate(
            device: device, mode: mode, weapon: weapon, style: style,
            aim: aimResult, track: trackResult, gyro: gyroResult
        )
        generated = r
        tips = SensitivityCalculator.tips(mode: mode, aim: aimResult, track: trackResult, gyro: gyroResult)
    }
}
