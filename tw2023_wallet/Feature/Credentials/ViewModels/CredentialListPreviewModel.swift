//
//  CredentialListPreviewModel.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2023/12/22.
//

import Foundation

class PreviewModel: CredentialListViewModel {
    override func loadData(presentationDefinition: PresentationDefinition? = nil) {
        // mock data for preview
        dataModel.isLoading = true
        print("load dummy data..")
        // try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
        let modelData = ModelData()
        modelData.loadCredentials()
        self.dataModel.credentials = modelData.credentials
        print("done")
        dataModel.isLoading = false
    }
}
