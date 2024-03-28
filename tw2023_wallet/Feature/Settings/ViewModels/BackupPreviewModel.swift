//
//  BackupPreviewModel.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2024/02/16.
//

import Foundation

class BackupPreviewModel: BackupViewModel {
    
    override func loadData() {
        guard !hasLoadedData else { return }
        isLoading = true
        print("load data..")
        
        let now = Date()
        let gmtFormatter = DateFormatterFactory.gmtDateFormatter()
        let gmtString = gmtFormatter.string(from: now)
        guard let gmtDate = gmtFormatter.date(from: gmtString) else {
            return
        }
        
        let localFormatter = DateFormatterFactory.localDateFormatter()
        
        lastCreatedAt = localFormatter.string(from: gmtDate)
        
        isLoading = false
        hasLoadedData = true
        print("done")
    }
}
