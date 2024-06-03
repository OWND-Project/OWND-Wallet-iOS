//
//  AddCertificates.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2024/01/05.
//

import SwiftUI

@Observable
class SharedArgs {
    var credentialOfferArgs: CredentialOfferArgs?
    var sharingCredentialArgs: SharingCredentialArgs?
    var verificationArgs: VerificationArgs?
}

struct AddCertificates: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.presentationMode) var presentationMode
    @Environment(SharedArgs.self) var sharedArgs
    @Environment(SharingRequestModel.self) var sharingRequestModel

    @State private var navigateToAddMyNumberCard = false
    @State private var navigateToAddOtherCredential = false
    @State private var navigateToSharingRequest = false
    @State private var navigateToCredentialOffer = false
    @State private var navigateToRedirectView = false
    @State private var isTabBarHidden = true
    @State var nextScreen: ScreensOnFullScreen = .root

    @State private var sharingCredentialArgs: SharingCredentialArgs? = nil

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack {
                    //                    Image("add_mynumber")
                    //                        .resizable()
                    //                        .aspectRatio(2.55, contentMode: .fit)
                    //                        .frame(width: geometry.size.width * 0.9) // 画面幅の90%に設定
                    //                        .padding(.vertical, 8)
                    //                        .onTapGesture {
                    //                            navigateToAddMyNumberCard = true // 遷移をトリガー
                    //                        }

                    Image("add_other")
                        .resizable()
                        .aspectRatio(2.55, contentMode: .fit)
                        .frame(width: geometry.size.width * 0.9)  // 画面幅の90%に設定
                        .padding(.vertical, 8)
                        .onTapGesture {
                            navigateToAddOtherCredential = true  // 遷移をトリガー
                        }
                }
                .padding(.vertical, 128)
                .padding(.horizontal, 24)
                //            .navigationBarTitle("add_certificate", displayMode: .inline)
                .fullScreenCover(
                    isPresented: $navigateToAddMyNumberCard,
                    onDismiss: didDismissAddMyNumberCard
                ) {
                    MyNumberCard()
                }
                .fullScreenCover(
                    isPresented: $navigateToAddOtherCredential,
                    onDismiss: didDismissQRReader
                ) {
                    QRReaderView(nextScreen: $nextScreen)
                }
                .fullScreenCover(
                    isPresented: $navigateToCredentialOffer,
                    onDismiss: didDismissCredentialOffer
                ) {
                    if let args = sharedArgs.credentialOfferArgs {
                        CredentialOfferView().environment(args)
                    }
                    else {
                        EmptyView()
                    }
                }
                .fullScreenCover(
                    isPresented: $navigateToSharingRequest,
                    onDismiss: didDismissSharingRequest
                ) {
                    if let args = sharedArgs.sharingCredentialArgs {
                        SharingRequest(args: args)
                    }
                    else {
                        EmptyView()
                    }
                }
                .fullScreenCover(
                    isPresented: $navigateToRedirectView,
                    onDismiss: didDismissRedirectView
                ) {
                    let (urlString, cookies) = getRedirectParameters()
                    RedirectView(urlString: urlString, cookieStrings: cookies)
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("cancel") {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
        }
    }

    func getRedirectParameters() -> (String, [String]) {
        guard let postResult = sharingRequestModel.postResult else {
            print("illegal state error: postResult is nil")
            return ("illegal redirect params", [])
        }
        guard let urlString = postResult.location else {
            print("illegal state error: location is nil")
            return ("illegal redirect params", [])
        }
        return (urlString, postResult.cookies ?? [])
    }

    func didDismissAddMyNumberCard() {
        dismiss()
    }

    func didDismissCredentialOffer() {
        dismiss()
    }

    func didDismissQRReader() {
        // 次の遷移先を開く
        switch nextScreen {
            case .credentialOffer:
                print("credentialOffer")
                navigateToCredentialOffer.toggle()
            case .sharingRequest:
                print("sharingRequest")
                navigateToSharingRequest.toggle()
            default:
                dismiss()
        }
    }

    func didDismissSharingRequest() {
        if sharingRequestModel.postResult != nil {
            navigateToRedirectView.toggle()
        }
        else {
            dismiss()
        }
    }

    func didDismissRedirectView() {
        dismiss()
    }
}

#Preview {
    AddCertificates()
        .environment(SharedArgs())
        .environment(SharingRequestModel())
}
