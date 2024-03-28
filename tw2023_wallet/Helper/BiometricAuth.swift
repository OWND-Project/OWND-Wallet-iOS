//
//  BiometricAuth.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2024/01/08.
//

import Foundation
import LocalAuthentication


class BiometricAuth {
    func isBiometricAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        
        // https://developer.apple.com/documentation/localauthentication/lapolicy/deviceownerauthentication
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
}

@Observable
class AuthenticationManager {
    var isUnlocked: Bool = false {
        didSet {
            if isUnlocked {
                lastUnlocked = Date()
            }
        }
    }
    private var lastUnlocked = Date()

    func shouldLock() -> Bool {
        let currentTime = Date()
        let lockInterval = TimeInterval(1 * 60) // 3分
        return currentTime.timeIntervalSince(lastUnlocked) > lockInterval
    }
    
    func canEvaluateDeviceOwnerAuthenticationPolicy() -> Bool {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            print("can Evaluate DeviceOwnerAuthentication Policy")
            return true
        } else {
            print("can not Evaluate DeviceOwnerAuthentication Policy")
            return false
        }
    }
    
    func authenticate() {
        print("authenticate")
        let context = LAContext()
        var error: NSError?

        // 生体認証が利用可能かをチェック
        // https://developer.apple.com/documentation/localauthentication/lapolicy/deviceownerauthentication
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            print("canEvaluatePolicy")
            // 生体認証開始
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "アプリのロックを解除するために認証が必要です") { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        print("unlock success")
                        // 認証成功
                        self.isUnlocked = true
                    } else {
                        print("unlock failure")
                        // 認証失敗
                        // 必要に応じてエラーハンドリング
                    }
                }
            }
        } else {
            print("can not EvaluatePolicy")
            // 生体認証が利用不可
            self.isUnlocked = true
        }
    }
}
