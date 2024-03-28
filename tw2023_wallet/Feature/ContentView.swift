//
//  ContentView.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2023/12/21.
//

import SwiftUI

struct ContentView: View {
    @State private var isNotFirstLaunch = UserDefaults.standard.bool(forKey: "isNotFirstLaunch")
    
    var body: some View {
        if isNotFirstLaunch {
            Home()
        } else {
            WalkThrough1(isNotFirstLaunch: $isNotFirstLaunch)
        }
    }
}

#Preview {
    ContentView()
}
