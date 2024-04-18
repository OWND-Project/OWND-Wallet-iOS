//
//  CredentialDetailModel.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2023/12/27.
//

import Foundation

@Observable
class CredentialDetailModel {
    var sharingHistories: [CredentialSharingHistory] = []
    var isLoading = false
    var hasLoadedData = false
}
