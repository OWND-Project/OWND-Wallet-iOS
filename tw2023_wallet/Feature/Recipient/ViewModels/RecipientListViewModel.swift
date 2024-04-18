//
//  RecipientViewModel.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2024/02/01.
//

import Combine
import Foundation

class RecipientListViewModel: ObservableObject {
    @Published var sharingHistories: [History] = []
    @Published var groupedSharingHistories: [String : [History]] = [:]
    @Published var hasLoadedData = false
    @Published var isLoading = false
    private var credentialHistoryManager: CredentialSharingHistoryManager
    private var idTokenHistoryManager: IdTokenSharingHistoryManager

    init(credentialHistoryManager: CredentialSharingHistoryManager = CredentialSharingHistoryManager(container: nil),
         idTokenHistoryManager: IdTokenSharingHistoryManager = IdTokenSharingHistoryManager(container: nil)) {
        self.credentialHistoryManager = credentialHistoryManager
        self.idTokenHistoryManager = idTokenHistoryManager
    }

    func loadSharingHistories() {
        guard !self.hasLoadedData else { return }
        self.isLoading = true

        let credentialHistories = self.credentialHistoryManager.getAll()
        let mappedCredentialHistories = credentialHistories.map { datastoreHistory in
            datastoreHistory.toCredentialSharingHistory()
        }
        
        let idTokenSharingHistories = self.idTokenHistoryManager.getAll()
        let mappedIdTokenSharingHistories = idTokenSharingHistories.map { datastoreHistory in
            datastoreHistory.toIdTokenSharingHistory()
        }
        
        let histories = Histories(histories: mappedCredentialHistories + mappedIdTokenSharingHistories)

        let groupedSharingHistories = histories.groupByRp()
        let latestHistories = histories.latestByRp()
        let sortedHistories = Histories.sortHistoriesByDate(histories: latestHistories)

        DispatchQueue.main.async {
            self.groupedSharingHistories = groupedSharingHistories
            self.sharingHistories = sortedHistories
            self.isLoading = false
            self.hasLoadedData = true
        }
    }
}
