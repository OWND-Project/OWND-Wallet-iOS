//
//  Credential.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2023/12/21.
//

import Foundation
import SwiftUI

struct Credential: Codable, Identifiable, Hashable {
    var id: String
    var format: String
    var payload: String
    var issuer: String
    let issuerDisplayName: String
    var issuedAt: String
    var logoUrl: String?
    var backgroundColor: String?
    var backgroundImageUrl: String?
    var textColor: String?
    var credentialType: CredentialType
    // var disclosure: Dictionary<String, String>?以下は同様の意味
    var disclosure: [String: String]?
    var certificates: [Certificate?]?
    var qrDisplay: String
    var metaData: CredentialIssuerMetadata

    var backgroundImage: AnyView? {
        if let url = backgroundImageUrl {
            return ImageLoader.loadImage(from: url)
        }
        return nil
    }

    var logoImage: AnyView? {
        if let url = logoUrl {
            return ImageLoader.loadImage(from: url)
        }
        return nil
    }

    struct Certificate: Codable {
        var CN: String
        var O: String
        var ST: String
        var L: String?
        var STREET: String?
        var C: String
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func ==(lhs: Credential, rhs: Credential) -> Bool {
        return lhs.id == rhs.id
    }
}

enum CredentialType: String, Codable {
    case identityCredential = "IdentityCredential"
    case employeeIdentificationCredential = "EmployeeIdentificationCredential"
    case participationCertificate = "ParticipationCertificate"
}
