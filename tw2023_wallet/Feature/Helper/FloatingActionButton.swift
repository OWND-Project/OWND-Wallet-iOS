//
//  FloatingActionButton.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2023/12/21.
//

import SwiftUI

struct FloatingActionButton: View {
    var onButtonTap: () -> Void
    
    var body: some View {
        Button(action: onButtonTap) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.blue)
                .cornerRadius(28)
                .shadow(radius: 10)
        }
        .padding()
    }
}

#Preview {
    FloatingActionButton(onButtonTap: {
        print("tapped")
    })
}
