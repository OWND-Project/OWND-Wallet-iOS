//
//  CredentialOfferModel.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2023/12/28.
//

import Foundation

@Observable
class CredentialOfferModel {
    var metaData: Metadata? = nil
    var credentialOffer: CredentialOffer? = nil

    // The parameter `credentialConfigurationIds` is array.
    // todo: This variable should be an array as well.
    var targetCredentialId: String? = nil

    var isLoading = false
    var hasLoadedData = false
}
