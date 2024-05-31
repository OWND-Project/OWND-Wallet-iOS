//
//  Enums.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2023/12/26.
//

import Foundation

enum ResponseMode: String, Codable {
    case fragment = "fragment"
    case fragmentJwt = "fragment.jwt"
    case directPost = "direct_post"
    case directPostJwt = "direct_post.jwt"
    case post = "post"
    case query = "query"
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        
        guard let responseMode = ResponseMode(rawValue: value) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid response mode value: \(value)")
        }
        
        self = responseMode
    }
}

enum Scope: String, Codable {
    case openid = "openid"
    case openidDidAuthn = "openid did_authn"
    case profile = "profile"
    case email = "email"
    case address = "address"
    case phone = "phone"
    case offlineAccess = "offline_access"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        
        guard let scope = Scope(rawValue: value) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid scope value: \(value)")
        }
        
        self = scope
    }
}

enum SubjectType: String, Codable {
    case publik = "public"
    case pairwise = "pairwise"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        
        guard let subjectType = SubjectType(rawValue: value) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid subject type value: \(value)")
        }
        
        self = subjectType
    }
}

enum SigningAlgo: String, Codable {
    case edDSA = "EdDSA"
    case rs256 = "RS256"
    case ps256 = "PS256"
    case es256 = "ES256"
    case es256K = "ES256K"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        
        guard let signingAlgo = SigningAlgo(rawValue: value) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid signing algorithm value: \(value)")
        }
        
        self = signingAlgo
    }
}

enum GrantType: String, Codable {
    case authorizationCode = "authorization_code"
    case implicit = "implicit"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        
        guard let grantType = GrantType(rawValue: value) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid grant type value: \(value)")
        }
        
        self = grantType
    }
}

enum AuthenticationContextReferences: String, Codable {
    case phr = "phr"
    case phrh = "phrh"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        
        guard let authContextRef = AuthenticationContextReferences(rawValue: value) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid authentication context reference value: \(value)")
        }
        
        self = authContextRef
    }
}

enum TokenEndpointAuthMethod: String, Codable {
    case clientSecretPost = "client_secret_post"
    case clientSecretBasic = "client_secret_basic"
    case clientSecretJwt = "client_secret_jwt"
    case privateKeyJwt = "private_key_jwt"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        
        guard let authMethod = TokenEndpointAuthMethod(rawValue: value) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid token endpoint authentication method value: \(value)")
        }
        
        self = authMethod
    }
}

enum ClaimType: String, Codable {
    case normal = "normal"
    case aggregated = "aggregated"
    case distributed = "distributed"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        
        guard let claimType = ClaimType(rawValue: value) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid claim type value: \(value)")
        }
        
        self = claimType
    }
}

enum Format: String, Codable {
    case jwt = "jwt"
    case jwtVc = "jwt_vc"
    case jwtVcJson = "jwt_vc_json"
    case jwtVp = "jwt_vp"
    case ldp = "ldp"
    case ldpVc = "ldp_vc"
    case ldpVp = "ldp_vp"

    // Codableプロトコルを適切に実装するための初期化関数
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        
        guard let format = Format(rawValue: value) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid format value: \(value)")
        }
        
        self = format
    }
}

