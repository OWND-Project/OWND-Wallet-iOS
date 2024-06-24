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
    let grantTypesSupported: [String]?
    let responseMode: ResponseMode?
    enum CodingKeys: String, CodingKey {
        case issuer
        case authorizationEndpoint = "authorization_endpoint"
        case tokenEndpoint = "token_endpoint"
        case grantTypesSupported = "grant_types_supported"
        case responseMode = "response_mode"
    }
}
