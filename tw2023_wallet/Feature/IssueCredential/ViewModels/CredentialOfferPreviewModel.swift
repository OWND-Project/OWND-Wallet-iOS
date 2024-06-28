//
//  CredentialOfferPreviewModel.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2023/12/30.
//

import Foundation

class CredentialOfferPreviewModel: CredentialOfferViewModel {
    override func loadData(_ credentialOffer: CredentialOffer) async {
        // mock data for preview
        dataModel.isLoading = true
        print("loading dummy data")

        dataModel.credentialOffer = credentialOffer

        let modelData = ModelData()
        modelData.loadIssuerMetaDataList()
        modelData.loadAuthorizationMetaDataList()

        let metaData = Metadata(
            credentialIssuerMetadata: modelData.issuerMetaDataList[2],
            authorizationServerMetadata: modelData.authorizationMetaDataList[0])

        dataModel.metaData = metaData

        print("load dummy data..")
        print("done")
        dataModel.isLoading = false
    }
}
