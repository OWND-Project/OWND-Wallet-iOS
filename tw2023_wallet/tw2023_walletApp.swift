//
//  tw2023_walletApp.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2023/12/21.
//

import CoreData
import LocalAuthentication
import SwiftUI

func createCredentialOfferArgs(value: String) -> CredentialOfferArgs {
    let args = CredentialOfferArgs()
    args.credentialOffer = value
    return args
}

func createOpenID4VPArgs(value: String) -> SharingCredentialArgs {
    let args = SharingCredentialArgs()
    args.url = value
    return args
}

extension String: Identifiable {
    public var id: String { return self }
}

@main
struct tw2023_walletApp: App {
    @State private var credentialOffer: String? = nil
    @State private var openID4VP: String? = nil
    @State private var navigateToRedirectView = false

    @State private var sharingRequestModel = SharingRequestModel()

    private var authenticationManager = AuthenticationManager()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            if self.authenticationManager.isUnlocked {
                ContentView()
                    .onOpenURL(perform: { url in
                        handleIncomingURL(url)
                    })
                    .fullScreenCover(
                        item: $credentialOffer,
                        onDismiss: {
                            credentialOffer = nil
                        }
                    ) { value in
                        CredentialOfferView().environment(
                            createCredentialOfferArgs(value: value))
                    }
                    .fullScreenCover(
                        item: $openID4VP,
                        onDismiss: {
                            openID4VP = nil
                            if let postResult = sharingRequestModel.postResult,
                                let location = postResult.location
                            {
                                navigateToRedirectView.toggle()
                            }
                        }
                    ) { value in
                        SharingRequest(args: createOpenID4VPArgs(value: value)).environment(
                            sharingRequestModel)
                    }
                    .fullScreenCover(
                        isPresented: $navigateToRedirectView,
                        onDismiss: {
                            navigateToRedirectView = false
                        }
                    ) {
                        // let (urlString, cookies) = getRedirectParameters()
                        if let postResult = sharingRequestModel.postResult,
                            let urlString = postResult.location
                        {
                            NavigationView {
                                RedirectView(urlString: urlString, cookieStrings: [])
                                    .navigationBarItems(
                                        trailing: Button("close") {
                                            navigateToRedirectView = false
                                        }
                                    )
                            }
                        }
                        else {
                            EmptyView()
                        }
                    }
            }
            else {
                AuthenticationView(authenticationManager: self.authenticationManager).onOpenURL(
                    perform: { url in
                        handleIncomingURL(url)
                    })
            }
        }
        .environment(authenticationManager)
        .onChange(of: scenePhase) {
            handleScenePhaseChange(scenePhase)
        }
    }

    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
            case .active:
                print("App is active")
            case .inactive:
                print("App is inactive")
            case .background:
                print("App is in background")
                if self.authenticationManager.shouldLock() {
                    self.authenticationManager.isUnlocked = false
                    credentialOffer = nil
                    openID4VP = nil
                }
            @unknown default:
                break
        }
    }

    private func handleIncomingURL(_ url: URL) {
        print("handling url : \(url)")
        if url.scheme == "openid4vp" {
            handleVp(url)
        }
        else if url.scheme == "openid-credential-offer" {
            handleOffer(url)
        }
        else if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            if let queryItems = components.queryItems {
                let credentialOfferParam = queryItems.first { $0.name == "credential_offer" }?.value
                if credentialOfferParam != nil {
                    handleOffer(url)
                }
                else {
                    handleVp(url)
                }
            }
            else {
                print("query not found")
            }
        }
    }

    private func handleOffer(_ url: URL) {
        print("credential offer")
        credentialOffer = url.absoluteString
    }

    private func handleVp(_ url: URL) {
        print("vp")
        openID4VP = url.absoluteString
    }

}

enum ApplicatoinError: Error {
    case illegalState(message: String? = nil)
}
