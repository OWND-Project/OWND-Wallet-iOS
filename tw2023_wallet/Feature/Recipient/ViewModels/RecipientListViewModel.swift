//
//  RecipientViewModel.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2024/02/01.
//

import Combine
import Foundation

class RecipientListViewModel: ObservableObject {
    @Published var sharingHistories: [CredentialSharingHistory] = []
    @Published var groupedSharingHistories: [String : [CredentialSharingHistory]] = [:]
    @Published var hasLoadedData = false
    @Published var isLoading = false
    private var historyManager: CredentialSharingHistoryManager
    private var idTokenHistoryManager: IdTokenSharingHistoryManager

    init(historyManager: CredentialSharingHistoryManager = CredentialSharingHistoryManager(container: nil),
         idTokenHistoryManager: IdTokenSharingHistoryManager = IdTokenSharingHistoryManager(container: nil)) {
        self.historyManager = historyManager
        self.idTokenHistoryManager = idTokenHistoryManager
    }

    func loadSharingHistories() {
        guard !self.hasLoadedData else { return }
        self.isLoading = true

        let datastoreHistories = self.historyManager.getAll()
        let mappedHistories = datastoreHistories.map { datastoreHistory in
            datastoreHistory.toCredentialSharingHistory()
        }

        let groupedSharingHistories = Dictionary(grouping: mappedHistories, by: { $0.rp })
        let latestHistories = self.findLatest(groupedHistories: groupedSharingHistories)
        let sortedHistories = self.sortHistoriesByDate(histories: latestHistories)

        DispatchQueue.main.async {
            self.groupedSharingHistories = groupedSharingHistories
            self.sharingHistories = sortedHistories
            self.isLoading = false
            self.hasLoadedData = true
        }
    }

    func sortHistoriesByDate(histories: [CredentialSharingHistory]) -> [CredentialSharingHistory] {
        return histories.sorted { lhs, rhs in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            let lhsDate = dateFormatter.date(from: lhs.createdAt) ?? Date.distantPast
            let rhsDate = dateFormatter.date(from: rhs.createdAt) ?? Date.distantPast
            return lhsDate > rhsDate
        }
    }

    func findLatest(groupedHistories: [String : [CredentialSharingHistory]]) -> [CredentialSharingHistory] {
        return groupedHistories.compactMap { group -> CredentialSharingHistory? in
            group.value.last // 既にソートされているので、各グループの最初の要素が最新です。
        }
    }
}
