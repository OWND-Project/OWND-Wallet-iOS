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

    func loadClaimsInfo(sharingHistory: CredentialSharingHistory) {
        guard !self.hasLoadedData else { return }
        self.isLoading = true
        
        let claims = sharingHistory.claims
        
        self.claimsInfo = sharingHistory.claims
        self.title = String(format: NSLocalizedString("credential_sharing_time", comment: ""),
                            sharingHistory.createdAt)
        self.rpName = String(format: NSLocalizedString("credential_recipient", comment: ""),
                             sharingHistory.rpName)
        
        self.isLoading = false
        self.hasLoadedData = true
    }
}
