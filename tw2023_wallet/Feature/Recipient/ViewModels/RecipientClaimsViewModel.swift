//
//  RecipientClaimsViewModel.swift
//  tw2023_wallet
//
//  Created by katsuyoshi ozaki on 2024/02/19.
//

import Foundation




class RecipientClaimsViewModel: ObservableObject {
    @Published var title: String = "Unknown"
    @Published var rpName: String = "Unknown"
    @Published var claimsInfo: [ClaimInfo] = []
    @Published var hasLoadedData = false
    @Published var isLoading = false
    
    private var credentialManager: CredentialDataManager

    init(credentialManager: CredentialDataManager = CredentialDataManager(container: nil)) {
        self.credentialManager = credentialManager
    }

    func loadClaimsInfo(sharingHistory: History) {
        guard !self.hasLoadedData else { return }
        self.isLoading = true
        
        switch sharingHistory {
        case let credential as CredentialSharingHistory:
            let claims = credential.claims
            self.claimsInfo = claims
            self.title = String(format: NSLocalizedString("credential_sharing_time", comment: ""),
                                credential.createdAt)
            self.rpName = String(format: NSLocalizedString("credential_recipient", comment: ""),
                                 credential.rpName)
        case let idToken as IdTokenSharingHistory:
            self.claimsInfo = [
                ClaimInfo(claimKey: "key for id token", claimValue: "value for id token", purpose: "利用者を識別するために提供しました")
            ]
            self.title = String(format: NSLocalizedString("credential_sharing_time", comment: ""),
                                idToken.createdAt)
            self.rpName = String(format: NSLocalizedString("credential_recipient", comment: ""),
                                 idToken.rp)
        default:
            print("Unexpected history type")
        }
        
        self.isLoading = false
        self.hasLoadedData = true
    }
}
