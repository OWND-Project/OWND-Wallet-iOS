//
//  PinCodeInput.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2024/01/16.
//

import SwiftUI

struct PinCodeInput: View {
    @State private var pinCode = ""  // PINコード用の状態変数
    @State var viewModel: CredentialOfferViewModel
    @State private var navigateToCredentialList = false
    @FocusState private var isInputActive: Bool

    init(viewModel: CredentialOfferViewModel = CredentialOfferViewModel()) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.dataModel.isLoading {
                    ProgressView().progressViewStyle(CircularProgressViewStyle())
                }
                else {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("pincode_view_title")
                            .modifier(Title2Black())
                            .padding(.vertical, 16)
                        Text("pincode_view_description")
                            .modifier(BodyBlack())
                            .padding(.vertical, 16)
                        Text("pincode_view_label")
                            .modifier(SubHeadLineBlack())
                            .padding(.vertical, 16)
                        // PINコード入力フィールド
                        SecureField("Enter PIN Code", text: $pinCode)
                            .keyboardType(.numberPad)  // 数字キーボードの使用
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color("outlinedButtonBorderColor"), lineWidth: 1)
                            )
                            .padding(.vertical, 16)
                            .focused($isInputActive)  // FocusStateを適用

                        // デバッグ用：入力されたPINコードを表示
                        ActionButtonBlack(
                            title: "authentication",
                            action: {
                                Task {
                                    try await viewModel.sendRequest(txCode: pinCode)
                                    self.navigateToCredentialList = true
                                }
                            }
                        )
                        .navigationDestination(
                            isPresented: $navigateToCredentialList,
                            destination: {
                                CredentialList()
                            }
                        )
                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .navigationTitle(LocalizedStringKey("add_certificate"))
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            // ビューが表示されたときにテキストフィールドにフォーカスを設定
            // ビューがまだ準備ができていない状態でフォーカスが設定されることがあるため、少し遅延させる
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isInputActive = true
            }
        }
    }
}

#Preview {
    PinCodeInput(viewModel: CredentialOfferViewModel())
}
