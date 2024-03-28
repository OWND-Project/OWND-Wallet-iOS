//
//  SharingToModel.swift
//  tw2023_wallet
//
//  Created by katsuyoshi ozaki on 2024/02/16.
//

import Foundation

@Observable
class SharingToModel {
    var isLoading: Bool = false
    var hasLoadedData: Bool = false
    var sharingHistories: [SharingHistory] = []
}
