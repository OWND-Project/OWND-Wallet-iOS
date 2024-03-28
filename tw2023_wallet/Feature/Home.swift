//
//  Home.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2023/12/21.
//

import SwiftUI

struct Home: View {
    @State private var selectedTab: String = "Credential"
    @State private var sharedArgs = SharedArgs()
    @State private var sharingRequestModel = SharingRequestModel()

    var body: some View {
        TabView(selection: $selectedTab) {
            CredentialList()
                .tabItem {
                    Label("Credential", systemImage: "person.text.rectangle")
                }
                .tag("Credential")
                .environment(sharedArgs)
                .environment(sharingRequestModel)
//            RecipientList()
//                .tabItem {
//                    Label("SharingTo", systemImage: "house.fill")
//                }
//                .tag("Recipient")
            QRReaderViewLauncher(selectedTab: $selectedTab)
                .tabItem {
                    Label("Reader", systemImage: "qrcode.viewfinder")
                }
                .tag("Reader")
                .environment(sharedArgs)
                .environment(sharingRequestModel)
            Setting()
                .tabItem {
                    Label("Setting", systemImage: "line.3.horizontal")
                }
                .tag("Setting")
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    Home()
}
