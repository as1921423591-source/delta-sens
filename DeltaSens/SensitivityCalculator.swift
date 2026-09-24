import Foundation

struct SensitivityCalculator {

    static func calculate(
        device: DeviceType,
        mode: OperationMode,
        weapon: WeaponType,
        style: PlayStyle,
        aim: AimTestResult,
        track: TrackingTestResult,
        gyro: GyroTestResult
    ) -> SensitivityResult {

        let deviceMult = device.multiplier
        let styleMult = style.multiplier
        let recoil = weapon.recoilLevel

        // ===== 滑屏基准 =====
        var hTotal = 100.0 * deviceMult * styleMult
        var hVert = 80.0
        var hHoriz = 100.0
        var hFire = 100.0
        var hFireVert = 80.0
        var hFireHoriz = 100.0
        var hMDV = 1.33
        var hFireMDV = 1.33
        var turnMode = "固定模式"
        var camAcc = 15
        var fireAcc = 13

        // 定位测试：过冲率高 -> 降灵敏度
        if aim.done {
            if aim.overshootRate > 0.3 {
                hTotal -= 15
                hFire -= 10
            } else if aim.overshootRate < 0.1 && aim.hits > 5 {
                hTotal += 8
            }
        }

        // 追踪测试：垂直偏移大 -> 降垂直灵敏度
        if track.done {
            if track.verticalOffset > 40 {
                hVert -= 10
                hFireVert -= 8
            } else if track.verticalOffset < 15 && track.accuracy > 60 {
                hVert += 5
            }
        }

        // 武器后坐力影响开火垂直
        switch weapon {
        case .ar: hFireVert += 10
        case .smg: hFireVert += 5
        case .sniper: hFireVert -= 15
        case .dmr: break
        }

        // 操作模式：加陀螺仪后手搓降档，避免冲突
        switch mode {
        case .gyro:
            hTotal *= 0.6
            hFire *= 0.6
            turnMode = "加速模式"
            camAcc = 20
            fireAcc = 18
        case .handGyro:
            hTotal *= 0.85
            hFire *= 0.85
        case .hand:
            break
        }

        hTotal = clamp(hTotal, 40, 200)
        hVert = clamp(hVert * styleMult, 50, 150)
        hHoriz = clamp(hHoriz * styleMult, 60, 160)
        hFire = clamp(hFire, 40, 200)
        hFireVert = clamp(hFireVert, 50, 180)
        hFireHoriz = clamp(hFireHoriz, 60, 160)

        // ===== 陀螺仪 =====
        var gTotal = 0.0, gVert = 0.0, gHoriz = 0.0
        var gFire = 0.0, gFireVert = 0.0, gFireHoriz = 0.0
        var gMDV = 1.33, gFireMDV = 1.33
        let showGyro = (mode != .hand)

        switch mode {
        case .handGyro:
            gTotal = 120; gVert = 100; gHoriz = 90
            gFire = 140; gFireVert = 120 + recoil * 20; gFireHoriz = 100
        case .gyro:
            gTotal = 230; gVert = 180; gHoriz = 160
            gFire = 230; gFireVert = 200 + recoil * 30; gFireHoriz = 150
        case .hand:
            break
        }

        // 陀螺仪测试反馈
        if gyro.done && showGyro {
            if gyro.horizontalOffset > 50 {
                gTotal -= 20
                gFire -= 15
            } else if gyro.horizontalOffset < 20 && gyro.accuracy > 60 {
                gTotal += 15
            }
        }

        // 风格
        if showGyro {
            switch style {
            case .aggro: gTotal += 20; gFire += 10
            case .steady: gTotal -= 20
            case .balanced: break
            }
        }
        if device == .tablet && showGyro { gTotal *= 0.9 }

        gTotal = clamp(gTotal, 0, 300)
        gVert = clamp(gVert, 0, 300)
        gHoriz = clamp(gHoriz, 0, 300)
        gFire = clamp(gFire, 0, 300)
        gFireVert = clamp(gFireVert, 0, 300)
        gFireHoriz = clamp(gFireHoriz, 0, 300)

        // ===== 倍镜表 =====
        let touchScope = buildScope(base: hTotal, fireBase: hFire, gyro: false)
        let gyroScope = showGyro ? buildScope(base: gTotal, fireBase: gFire, gyro: true) : []

        var result = SensitivityResult()
        result.turnMode = turnMode
        result.cameraAcceleration = camAcc
        result.fireAcceleration = fireAcc
        result.touchTotal = Int(hTotal.rounded())
        result.touchMDV = hMDV
        result.touchVertical = Int(hVert.rounded())
        result.touchHorizontal = Int(hHoriz.rounded())
        result.touchFireTotal = Int(hFire.rounded())
        result.touchFireMDV = hFireMDV
        result.touchFireVertical = Int(hFireVert.rounded())
        result.touchFireHorizontal = Int(hFireHoriz.rounded())
        result.gyroTotal = Int(gTotal.rounded())
        result.gyroMDV = gMDV
        result.gyroVertical = Int(gVert.rounded())
        result.gyroHorizontal = Int(gHoriz.rounded())
        result.gyroFireTotal = Int(gFire.rounded())
        result.gyroFireMDV = gFireMDV
        result.gyroFireVertical = Int(gFireVert.rounded())
        result.gyroFireHorizontal = Int(gFireHoriz.rounded())
        result.touchScope = touchScope
        result.gyroScope = gyroScope
        return result
    }

    private static func buildScope(base: Double, fireBase: Double, gyro: Bool) -> [ScopeRow] {
        let camDecay: [Double] = gyro
            ? [1.0, 0.72, 0.70, 0.63, 0.58, 0.56, 0.51, 0.47, 0.47, 0.47, 0.47, 0.47]
            : [1.0, 0.92, 0.83, 0.75, 0.75, 0.75, 0.75, 0.75, 0.75, 0.75, 0.75, 0.75]
        let fireDecay: [Double] = gyro
            ? [1.0, 0.88, 0.84, 0.81, 0.77, 0.47, 0.47, 0.47, 0.47, 0.47, 0.47, 0.47]
            : [1.0, 0.92, 0.83, 0.75, 0.75, 0.75, 0.75, 0.75, 0.75, 0.75, 0.75, 0.75]
        return scopeNames.enumerated().map { i, name in
            ScopeRow(name: name,
                     camera: Int((base * camDecay[i]).rounded()),
                     fire: Int((fireBase * fireDecay[i]).rounded()))
        }
    }

    private static func clamp(_ v: Double, _ a: Double, _ b: Double) -> Double {
        Swift.max(a, Swift.min(b, v))
    }

    static func tips(
        mode: OperationMode,
        aim: AimTestResult,
        track: TrackingTestResult,
        gyro: GyroTestResult
    ) -> [String] {
        var t: [String] = []
        if aim.done && aim.overshootRate > 0.3 {
            t.append("定位过冲率 \(Int(aim.overshootRate*100))% 偏高，已降低灵敏度。练习拉枪到最后减速停住。")
        }
        if track.done && track.verticalOffset > 40 {
            t.append("追踪测试垂直偏移 \(Int(track.verticalOffset))px，手上下抖得多，已降低垂直灵敏度。手肘贴桌面稳定手腕。")
        }
        if track.done && track.accuracy < 40 {
            t.append("追踪精度只有 \(Int(track.accuracy))%，跟枪还需练习。灵敏度已调低方便稳准星。")
        }
        if gyro.done && mode != .hand && gyro.horizontalOffset > 50 {
            t.append("陀螺仪水平偏移 \(Int(gyro.horizontalOffset))px，晃手机幅度太大，已降低陀螺仪灵敏度。")
        }
        if mode == .handGyro {
            t.append("⚠️ 主手副陀：大幅拉枪用手搓，小幅修正用陀螺仪，两个不要同时猛动。")
        }
        if mode == .gyro {
            t.append("⚠️ 全陀：握稳手机，手抖动会直接反映到准星。先从红点练起。")
        }
        return t
    }
}
