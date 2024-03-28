//
//  Start.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2023/12/22.
//

import SwiftUI

struct WalkThrough1: View {
    @Binding var isNotFirstLaunch: Bool

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    Image("step1")
                        .frame(width: geometry.size.width * 0.6)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2) // 画面上下左右中央
                    Image("walkthrough1")
                        .imageScale(.large)
                        .foregroundStyle(.tint)
                        .frame(width: geometry.size.width * 0.6)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2 + 150)

                    VStack {
                        VStack {
                            Text("walkthrough_1_1")
                                .modifier(TitleBlack())
                                .padding(.vertical, 32)
                            Text("walkthrough_1_2")
                                .modifier(TitleBlack())
                                .padding(.vertical, 32)
                        }
                        .padding(.vertical, 50)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                        Spacer() // 下部の余白

                        // 下部のボタンとスキップリンク
                        VStack {
                            HStack {
                                Spacer() // 右寄せのためのスペーサー
                                NavigationLink(destination: WalkThrough2()) {
                                    Image(systemName: "chevron.forward").modifier(Title3Gray())
                                }
                            }
                            .padding(.bottom, geometry.size.height * 0.2) // 下部からの位置を調整

                            HStack {
                                Spacer() // 右寄せのためのスペーサー
                                NavigationLink(destination: WalkThrough4()) {
                                    Text("skip")
                                        .underline()
                                        .modifier(BodyGray())
                                }
                            }
                            .padding(.bottom, geometry.size.height * 0.05) // 下部からの位置を調整
                        }
                    }
                }
            }
            .padding(.horizontal, 32)
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    WalkThrough1(isNotFirstLaunch: .constant(true))
}
