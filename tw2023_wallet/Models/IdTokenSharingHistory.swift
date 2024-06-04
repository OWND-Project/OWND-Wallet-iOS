//
//  IdTokenSharingHistory.swift
//  tw2023_wallet
//
//  Created by katsuyoshi ozaki on 2024/04/16.
//

import Foundation

struct IdTokenSharingHistory: Codable, Hashable, History {
    let rp: String
    let accountIndex: Int
    let createdAt: String
}
