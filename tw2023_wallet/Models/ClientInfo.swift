//
//  ClientInfo.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2024/01/10.
//

import Foundation
import SwiftUI

struct ClientInfo: Codable, Equatable {
    var name: String
    var logoUrl: String?
    var policyUrl: String
    var tosUrl: String
    var jwkThumbprint: String
    var certificateInfo: CertificateInfo?
    var verified: Bool = true

    var logoImage: AnyView? {
        if let url = logoUrl {
            return ImageLoader.loadImage(from: url)
        }
        return nil
    }

    static func == (lhs: ClientInfo, rhs: ClientInfo) -> Bool {
        return lhs.name == rhs.name
    }
}
