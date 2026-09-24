import Foundation

// MARK: - 用户选择
enum DeviceType: String, CaseIterable {
    case phone = "手机"
    case tablet = "平板"
    var multiplier: Double { self == .tablet ? 0.9 : 1.0 }
}

enum OperationMode: String, CaseIterable {
    case hand = "纯手搓"
    case handGyro = "主手副陀"
    case gyro = "全陀"
}

enum WeaponType: String, CaseIterable {
    case ar = "突击步枪"
    case smg = "冲锋枪"
    case dmr = "射手步枪"
    case sniper = "狙击枪"
    var recoilLevel: Double {
        switch self {
        case .ar: return 0.8
        case .smg: return 0.6
        case .dmr: return 0.4
        case .sniper: return 0.2
        }
    }
}

enum PlayStyle: String, CaseIterable {
    case aggro = "激进近战"
    case balanced = "均衡"
    case steady = "架枪远射"
    var multiplier: Double {
        switch self {
        case .aggro: return 1.15
        case .balanced: return 1.0
        case .steady: return 0.9
        }
    }
}

// MARK: - 测试结果
struct AimTestResult {
    var done: Bool = false
    var hits: Int = 0
    var overshootRate: Double = 0  // 0~1
}

struct TrackingTestResult {
    var done: Bool = false
    var accuracy: Double = 0       // 0~100
    var verticalOffset: Double = 0 // px
}

struct GyroTestResult {
    var done: Bool = false
    var accuracy: Double = 0
    var horizontalOffset: Double = 0
    var verticalOffset: Double = 0
}

// MARK: - 灵敏度输出
struct SensitivityResult {
    // 滑屏
    var turnMode: String = "固定模式"
    var cameraAcceleration: Int = 15
    var fireAcceleration: Int = 13
    var touchTotal: Int = 100
    var touchMDV: Double = 1.33
    var touchVertical: Int = 80
    var touchHorizontal: Int = 100
    var touchFireTotal: Int = 100
    var touchFireMDV: Double = 1.33
    var touchFireVertical: Int = 80
    var touchFireHorizontal: Int = 100

    // 陀螺仪
    var gyroTotal: Int = 0
    var gyroMDV: Double = 1.33
    var gyroVertical: Int = 0
    var gyroHorizontal: Int = 0
    var gyroFireTotal: Int = 0
    var gyroFireMDV: Double = 1.33
    var gyroFireVertical: Int = 0
    var gyroFireHorizontal: Int = 0

    // 倍镜表
    var touchScope: [ScopeRow] = []
    var gyroScope: [ScopeRow] = []
}

struct ScopeRow: Identifiable {
    let id = UUID()
    let name: String
    let camera: Int
    let fire: Int
}

let scopeNames = [
    "机瞄/红点/全息", "2倍镜", "3倍镜", "4倍镜", "5倍镜", "6倍镜",
    "7倍镜", "8倍镜", "9倍镜", "10倍镜", "11倍镜", "≥12倍镜"
]
