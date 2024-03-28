//
//  AuthenticationView.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2024/01/08.
//
import SwiftUI
import LocalAuthentication

struct AuthenticationView: View {
    // @State private var isUnlocked = false
    private var authenticationManager: AuthenticationManager
    private var canEvaluatePolicy: Bool

    init(authenticationManager: AuthenticationManager) {
        self.authenticationManager = authenticationManager
        self.canEvaluatePolicy = authenticationManager.canEvaluateDeviceOwnerAuthenticationPolicy()
    }
    
    var body: some View {
        VStack {
            if self.authenticationManager.isUnlocked {
                // 認証成功後に表示されるビュー
                Text("認証成功！")
            } else {
                // 認証画面
                if (canEvaluatePolicy) {
                    Text("認証が必要です")
                    Button("認証する") {
                        self.authenticationManager.authenticate()
                    }
                } else {
                    Text("安全にお使いいただくために、デバイスに生体認証やパスコード認証を設定して利用いただくことを推奨します")
                        .padding(16)
                    Button("このまま使用する") {
                        self.authenticationManager.authenticate()
                    }
                    
                }
            }
        }
    }
}


#Preview {
    AuthenticationView(authenticationManager: AuthenticationManager())
}
