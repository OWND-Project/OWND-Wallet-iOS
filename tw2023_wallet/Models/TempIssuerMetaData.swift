//
//  TempIssuerMetaData.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2023/12/30.
//

import Foundation
import SwiftUI

struct TempIssuerMetaData: Codable {
    var credentialIssuer: String
    var issuerDisplayName: String
    var issuerDisplayLogoUrl: String?
    var credentialsSupportedDisplayName: String
    var credentialType: String
    var displayNames: [String]

    var issuerDisplayLogoImage: AnyView? {
        if let url = issuerDisplayLogoUrl {
            return ImageLoader.loadImage(from: url)
        }
        return nil
    }

}
