//
//  CredentialOfferModel.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2023/12/28.
//

import Foundation

@Observable
class CredentialOfferModel {
    var metaData: CredentialIssuerMetadata? = nil
    var isLoading = false
    var hasLoadedData = false
}
