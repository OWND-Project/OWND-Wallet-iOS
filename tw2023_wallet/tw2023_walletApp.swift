//
//  tw2023_walletApp.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2023/12/21.
//

import SwiftUI
import CoreData
import LocalAuthentication


func createCredentialOfferArgs(value: String) -> CredentialOfferArgs{
    let args = CredentialOfferArgs()
    args.credentialOffer = value
    return args
}


func createOpenID4VPArgs(value: String) -> SharingCredentialArgs {
    let args = SharingCredentialArgs()
    args.url = value
    return args
}


@main
struct tw2023_walletApp: App {
    @State private var isShowingCredentialOffer = false
    @State private var credentialOffer: String? = nil
    @State private var isShowingOpenID4VP = false
    @State private var openID4VP: String? = nil
    
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
                    .fullScreenCover(isPresented: $isShowingCredentialOffer, onDismiss: {
                        credentialOffer = nil
                    }) {
                        if let value = credentialOffer {
                            CredentialOfferView().environment(createCredentialOfferArgs(value: value))
                        } else {
                            EmptyView()
                        }
                    }
                    .fullScreenCover(isPresented: $isShowingOpenID4VP, onDismiss: {
                        openID4VP = nil
                    }) {
                        if let value = openID4VP {
                            SharingRequest(args: createOpenID4VPArgs(value: value)).environment(sharingRequestModel)
                        } else {
                            EmptyView()
                        }
                    }
            } else {
                AuthenticationView(authenticationManager: self.authenticationManager)
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
                if credentialOffer != nil {
                    credentialOffer = nil
                }
            }
        @unknown default:
            break
        }
    }
    
    private func handleIncomingURL(_ url: URL) {
        print("handling url : \(url)")
        if url.scheme == "openid4vp" {
            handleVp(url)
        } else if url.scheme == "openid-credential-offer" {
            handleOffer(url)
        } else if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            if let queryItems = components.queryItems {
                let credentialOfferParam = queryItems.first { $0.name == "credential_offer" }?.value
                if credentialOfferParam != nil {
                    handleOffer(url)
                } else {
                    handleVp(url)
                }
            } else {
                print("query not found")
            }
        }
    }

    private func handleOffer(_ url: URL) {
        print("credential offer")
        credentialOffer = url.absoluteString
        isShowingCredentialOffer = true
    }

    private func handleVp(_ url: URL) {
        print("vp")
        openID4VP = url.absoluteString
        isShowingOpenID4VP = true
    }
    
}

enum ApplicatoinError: Error {
    case illegalState(message: String? = nil)
}

/*
class AppDelegate: NSObject, UIApplicationDelegate {
    @Environment(AuthenticationManager.self) private var authenticationManager
    var window: UIWindow?
    
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // custom schemeが呼び出された場合の処理をここに記述します
        print(url)
        if url.scheme == "openid-credential-offer" {
            // ここに必要な処理を追加
            // 例: 他の画面を表示したり、データを処理したりします
            print("Custom schemeが呼び出されました。")
            return true
        }else{
            print("想定するスキームではありません")
        }
        
        // 他のURL schemeに反応する場合は、それに対する処理を追加することもできます
        
        return false
    }
    
}
 */
//class AppDelegate: NSObject, UIApplicationDelegate {
//    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIResponder]?) -> Void) -> Bool {
//        if let incomingURL = userActivity.webpageURL {
//            // URL処理のロジック
//            print("Incoming URL is \(incomingURL)")
//        }
//        return true
//    }
//}
//class AppDelegate2: NSObject, UIApplicationDelegate {
//    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
//        print("Your code here")
//        return true
//    }
//}
