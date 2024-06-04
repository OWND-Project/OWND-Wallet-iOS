//
//  CredentialRow.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2023/12/21.
//

import SwiftUI

struct CredentialRow: View {
    var credential: Credential

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // backgroundImageが存在する場合、それを表示
                if let backgroundImageView = credential.backgroundImage {
                    backgroundImageView
                        .frame(height: geometry.size.width / 1.6)
                        .shadow(radius: 8)
                }
                else {
                    // backgroundImageが存在しない場合、RoundedRectangleを表示
                    RoundedRectangle(cornerRadius: 16)
                        .fill(credential.backgroundColor.map { colorFromHex($0) } ?? Color.white)
                        .shadow(radius: 8)
                        .frame(height: geometry.size.width / 1.6)
                }
                HStack {
                    Group {
                        if let logoView = credential.logoImage {
                            logoView
                        }
                        else if credential.backgroundImage == nil {
                            Image("logo_ownd")  // デフォルトのロゴ画像、backgroundImageがnilの場合のみ表示
                        }
                    }
                    .frame(width: 60, height: 60)
                    .padding([.top, .leading], 16)

                    Spacer()  // スペースを作る

                    if credential.backgroundImage == nil {
                        Text(credential.issuerDisplayName)
                            .font(.system(size: 16))
                            .foregroundColor(
                                credential.textColor.map { colorFromHex($0) } ?? .black
                            )
                            .padding(.trailing, 16)
                    }
                }
                .padding(.top, 16)
            }
        }
        .padding(.horizontal, 16)
    }
}

#Preview("single row") {
    let modelData = ModelData()
    modelData.loadCredentials()
    return CredentialRow(credential: modelData.credentials[0])
}

#Preview("multi row") {
    let modelData = ModelData()
    modelData.loadCredentials()
    return Group {
        CredentialRow(credential: modelData.credentials[0])
        CredentialRow(credential: modelData.credentials[1])
        CredentialRow(credential: modelData.credentials[2])
    }
}
