//
//  Setting.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2023/12/21.
//

import SwiftUI

struct Setting: View {
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfUse = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                /*
                 account info section
                 */
                Text("account_info").modifier(Title3Black())

                HStack {
                    Text("backup").modifier(BodyBlack())
                    Spacer()
                    NavigationLink(destination: Backup()) {
                        Image(systemName: "chevron.forward")
                            .modifier(BodyBlack())
                    }
                }
                .padding(.vertical, 16)
                
                /*
                 this app section
                 */
                Text("about_this_app").modifier(Title3Black())

                VStack(alignment: .leading) {
                    Text("version").modifier(BodyBlack())

                    HStack {
                        Text("v").modifier(SubHeadLineGray()) // "v" を追加
                        Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown")
                            .modifier(SubHeadLineGray())
                    }
                }
                .padding(.vertical, 16)

                HStack {
                    Text("privacy_policy").modifier(BodyBlack())
                    Spacer()
                    Button(action: {
                        self.showPrivacyPolicy = true
                    }) {
                        Image(systemName: "chevron.forward")
                            .modifier(BodyBlack())
                            .sheet(isPresented: $showPrivacyPolicy, content: {
                                SafariView(url: URL(string: "https://www.ownd-project.com/wallet/privacy/index.html")!)
                            })
                    }
                }
                .padding(.vertical, 16)

                HStack {
                    Text("terms_of_use").modifier(BodyBlack())
                    Spacer()
                    Button(action: {
                        self.showTermsOfUse = true
                    }) {
                        Image(systemName: "chevron.forward")
                            .modifier(BodyBlack())
                            .sheet(isPresented: $showTermsOfUse, content: {
                                SafariView(url: URL(string: "https://www.ownd-project.com/wallet/tos/index.html")!)
                            })
                    }
                }
                .padding(.vertical, 16)

                Spacer() // これにより、コンテンツが上に寄せられます。
            }
            .padding(.vertical, 32)
            .padding(.horizontal, 16)
            .navigationBarTitle("Setting", displayMode: .inline)
        }
    }
}

#Preview {
    Setting()
}
