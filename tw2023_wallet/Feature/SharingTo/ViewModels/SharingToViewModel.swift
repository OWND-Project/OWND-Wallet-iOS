//
//  SharingToViewModel.swift
//  tw2023_wallet
//
//  Created by katsuyoshi ozaki on 2024/02/16.
//

import Foundation

class SharingToViewModel {
    
    var dataModel: SharingToModel = .init()
    private let historyManager = CredentialSharingHistoryManager(container: nil)
    
    func loadData() async {
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else {
            print("now previewing")
            return
        }
        guard !dataModel.hasLoadedData else { return }
        dataModel.isLoading = true
        print("load data..")
        
        var histories: [CredentialSharingHistory] = []
        historyManager.getAll().forEach{rawHistory in
            let converted = rawHistory.toSharingHistory()
            histories.append(converted)
        }
        
        dataModel.sharingHistories = histories
        dataModel.isLoading = false
        dataModel.hasLoadedData = true
        print("done")
    }
    
}
