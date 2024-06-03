//
//  ScreensOnFullScreen.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2024/02/01.
//

import Foundation

enum ScreensOnFullScreen: Identifiable, Hashable {
    case root
    case credentialList
    case credentialDetail(Credential)
    case credentialOffer
    case sharingRequest
    case verification

    var id: Int {
        switch self {
            case .root: return 0
            case .credentialList: return 1
            case .credentialDetail: return 2
            case .credentialOffer: return 3
            case .sharingRequest: return 4
            case .verification: return 5
        }
    }
}
