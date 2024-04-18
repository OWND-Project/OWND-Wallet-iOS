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
        
        let histories = Histories(histories: modelData.sharingHistories)
        
        
        let groupedSharingHistories = histories.groupByRp()
        let latestHistories = histories.latestByRp()
        let sortedHistories = Histories.sortHistoriesByDate(histories: latestHistories)

        DispatchQueue.main.async {
            self.groupedSharingHistories = groupedSharingHistories
            self.sharingHistories = sortedHistories
            self.isLoading = false
            self.hasLoadedData = true
            print("RecipientPreviewModel done")
        }
    }
}
