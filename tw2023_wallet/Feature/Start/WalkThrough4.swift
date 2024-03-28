//
//  WalkThrough4.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2024/01/07.
//

import SwiftUI

struct WalkThrough4: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var navigateToCredentialList = false // 追加
    @State private var navigateToRestore = false
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfUse = false

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    Image("step4")
                        .frame(width: geometry.size.width * 0.6)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2) // 画面上下左右中央
                    Image("walkthrough4")
                        .imageScale(.large)
                        .foregroundStyle(.tint)
                        .frame(width: geometry.size.width * 0.6)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2 + 80)
                    VStack {
                        HStack {
                            Button(action: {
                                self.showPrivacyPolicy = true
                            }) {
                                Text("privacy_policy")
                                    .modifier(BodyBlack())
                                    .underline()
                                    .sheet(isPresented: $showPrivacyPolicy, content: {
                                        SafariView(url: URL(string: "https://www.ownd-project.com/wallet/privacy/index.html")!)
                                    })
                            }

                            Button(action: {
                                self.showTermsOfUse = true
                            }) {
                                Text("terms_of_use")
                                    .modifier(BodyBlack())
                                    .underline()
                                    .sheet(isPresented: $showTermsOfUse, content: {
                                        SafariView(url: URL(string: "https://www.ownd-project.com/wallet/tos/index.html")!)
                                    })
                            }
                        }
                        .modifier(BodyBlack())
                        .underline()
                        .padding(.vertical, 8)

                        Text("walkthrough_4_3")
                            .modifier(SubHeadLineBlack())
                    }
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2 + 210)
                }
                VStack {
                    VStack {
                        Text("walkthrough_4_1")
                            .modifier(TitleBlack())
                            .padding(.vertical, 32)
                        Text("walkthrough_4_2")
                            .modifier(TitleBlack())
                            .padding(.vertical, 32)
                    }
                    .padding(.vertical, 50)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)
                    Spacer() // 下部の余白
                    VStack {
                        HStack {
                            Button(action: {
                                self.presentationMode.wrappedValue.dismiss()
                            }) {
                                Image(systemName: "chevron.backward")
                                    .modifier(Title3Gray())
                            }
                            Spacer() // 下部の余白
                        }
                    }
                    .padding(.bottom, geometry.size.height * 0.2) // 下部からの位置を調整
                    ActionButtonBlack(title: "begin_anew", action: {
                        self.navigateToCredentialList = true
                        UserDefaults.standard.set(true, forKey: "isNotFirstLaunch")
                    })
                    .padding(.vertical, 16)
                    .navigationDestination(isPresented: $navigateToCredentialList) {
                        Home()
                    }
                    Button(action: {
                        self.navigateToRestore = true
                    }) {
                        Text("start_from_backup")
                            .modifier(BodyBlack())
                            .underline()
                    }
                    .navigationDestination(isPresented: $navigateToRestore) {
                        Restore()
                    }
                }
            }
            .padding(.horizontal, 32)
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    WalkThrough4()
}
