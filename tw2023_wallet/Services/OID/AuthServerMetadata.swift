//
//  AuthServerMetadata.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2023/12/26.
//

import Foundation

struct AuthorizationServerMetadata: Codable {
    let issuer: String?
    let authorizationEndpoint: String?
    let tokenEndpoint: String?
    let responseMode: ResponseMode?
}
