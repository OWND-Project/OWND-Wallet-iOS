//
//  CredentialOfferPreviewModel.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2023/12/30.
//

import Foundation

class CredentialOfferPreviewModel: CredentialOfferViewModel {
    override func loadData() async {
        // mock data for preview
        dataModel.isLoading = true
        print("loading dummy data")

        let modelData = ModelData()
        modelData.loadIssuerMetaDataList()

        self.dataModel.metaData = modelData.issuerMetaDataList[2]

        print("load dummy data..")
        print("done")
        dataModel.isLoading = false
    }
}
