//
//  SharingCredentialArgs.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2024/01/23.
//

import Foundation

@Observable
class SharingCredentialArgs: Hashable {
    var url: String?

    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }

    static func == (lhs: SharingCredentialArgs, rhs: SharingCredentialArgs) -> Bool {
        return lhs.url == rhs.url
    }
}
