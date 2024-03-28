//
//  QRReaderViewLauncher.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2024/02/13.
//

import SwiftUI

struct QRReaderViewLauncher: View {
    @Environment(SharingRequestModel.self) var sharingRequestModel
    @Environment(SharedArgs.self) var sharedArgs
    @Binding var selectedTab: String
    
    @State private var navigateToQRReaderView = false
    @State private var navigateToSharingRequest = false
    @State private var navigateToCredentialOffer = false
    @State private var navigateToRedirectView = false
    @State private var navigateToVerificationView = false
    @State var nextScreen: ScreensOnFullScreen = .root
    
    var body: some View {
        VStack {
            Text("")
                .fullScreenCover(isPresented: $navigateToQRReaderView,
                                 onDismiss: didDismissQRReader)
            {
                QRReaderView(nextScreen: $nextScreen)
            }
                .fullScreenCover(isPresented: $navigateToCredentialOffer,
                                 onDismiss: didDismiss)
                {
                    if let args = sharedArgs.credentialOfferArgs {
                        CredentialOfferView().environment(args)
                    } else {
                        EmptyView()
                    }
                }
                .fullScreenCover(isPresented: $navigateToSharingRequest,
                                 onDismiss: didDismissSharingRequest)
                {
                    if let args = sharedArgs.sharingCredentialArgs {
                        SharingRequest(args: args)
                    } else {
                        EmptyView()
                    }
                }
                .fullScreenCover(isPresented: $navigateToRedirectView,
                                 onDismiss: didDismiss)
                {
                    let (urlString, cookies) = getRedirectParameters()
                    NavigationView {
                        RedirectView(urlString: urlString, cookieStrings: cookies)
                            .navigationBarItems(trailing: Button("close") {
                                navigateToRedirectView = false
                        })
                       
                     }
                }
                .fullScreenCover(isPresented: $navigateToVerificationView,
                                 onDismiss: didDismiss)
                {
                    if let args = sharedArgs.verificationArgs {
                        Verification().environment(args)
                    } else {
                        EmptyView()
                    }
                }
        }
        .onAppear {
            navigateToQRReaderView = true
        }
    }

    func didDismiss() {
        selectedTab = "Credential"
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
    
    func didDismissQRReader() {
        // 次の遷移先を開く
        switch nextScreen {
        case .credentialOffer:
            print("credentialOffer")
            navigateToCredentialOffer.toggle()
        case .sharingRequest:
            print("sharingRequest")
            navigateToSharingRequest.toggle()
        case .verification:
            print("verification")
            navigateToVerificationView.toggle()
        default:
            selectedTab = "Credential"
        }
    }
    
    func didDismissSharingRequest() {
        if sharingRequestModel.postResult != nil {
            navigateToRedirectView.toggle()
        } else {
            selectedTab = "Credential"
        }
    }
}

#Preview {
    QRReaderViewLauncher(selectedTab: .constant("Reader"))
}
