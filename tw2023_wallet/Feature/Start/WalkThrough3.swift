//
//  WalkThrough3.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2024/01/07.
//

import SwiftUI

struct WalkThrough3: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    Image("step3")
                        .frame(width: geometry.size.width * 0.6)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2) // 画面上下左右中央

                    Image("walkthrough3")
                        .imageScale(.large)
                        .foregroundStyle(.tint)
                        .frame(width: geometry.size.width * 0.6)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2 + 150)
                }
                VStack {
                    VStack {
                        Text("walkthrough_3_1")
                            .modifier(TitleBlack())
                            .padding(.vertical, 32)
                        Text("walkthrough_3_2")
                            .modifier(Title3Black())
                            .padding(.vertical, 32)
                    }
                    .padding(.vertical, 50)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)
                    Spacer() // 下部の余白

                    VStack {
                        HStack {
//                            NavigatiodnLink(destination: WalkThrough2(isNotFirstLaunch: $isNotFirstLaunch)) {
//                                Image(systemName: "chevron.backward")
//                                    .modifier(Title3Gray())
//                            }
                            Button(action: {
                                self.presentationMode.wrappedValue.dismiss()
                            }) {
                                Image(systemName: "chevron.backward")
                                    .modifier(Title3Gray())
                            }
                            Spacer() // 右寄せのためのスペーサー
                            NavigationLink(destination: WalkThrough4()) {
                                Image(systemName: "chevron.forward")
                                    .modifier(Title3Gray())
                            }
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
                        .padding(.bottom, geometry.size.height * 0.05) // 下部からの位置を調整
                    }
                }
            }
            .padding(.horizontal, 32)
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    WalkThrough3()
}
