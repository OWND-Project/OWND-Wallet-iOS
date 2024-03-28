//
//  CredentialListModel.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2023/12/22.
//

import Foundation

@Observable
class CredentialListModel {
    var credentials: [Credential] = []
    var isLoading = false
    var hasLoadedData = false
}
