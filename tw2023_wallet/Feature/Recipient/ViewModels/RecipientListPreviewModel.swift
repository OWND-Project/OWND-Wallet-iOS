//
//  RecipientPreviewModel.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2024/02/01.
//

import Foundation

class RecipientListPreviewModel: RecipientListViewModel {
    override func loadSharingHistories() {
        guard !self.hasLoadedData else { return }
        self.isLoading = true
        let modelData = ModelData()
        modelData.loadSharingHistories()
        
        
        let groupedSharingHistories = Dictionary(grouping: modelData.sharingHistories, by: { $0.rp })
        let latestHistories = self.findLatest(groupedHistories: groupedSharingHistories)
        let sortedHistories = sortHistoriesByDate(histories: latestHistories)

        DispatchQueue.main.async {
            self.groupedSharingHistories = groupedSharingHistories
            self.sharingHistories = sortedHistories
            self.isLoading = false
            self.hasLoadedData = true
            print("RecipientPreviewModel done")
        }
    }
}
