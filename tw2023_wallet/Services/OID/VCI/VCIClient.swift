//
//  TokenIssuer.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2023/12/26.
//

import Foundation

func postTokenRequest(to url: URL, with parameters: [String: String], using session: URLSession = URLSession.shared) async throws -> OAuthTokenResponse {
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    request.httpBody = parameters.map { "\($0)=\($1)" }.joined(separator: "&").data(using: .utf8)

    let (data, response) = try await session.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
        throw URLError(.badServerResponse)
    }

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return try decoder.decode(OAuthTokenResponse.self, from: data)
}

func postCredentialRequest(_ credentialRequest: CredentialRequest, to url: URL, accessToken: String, using session: URLSession = URLSession.shared) async throws -> CredentialResponse {
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

    // CredentialRequestをJSONにエンコード
    // todo: snake_case と camelCaseの混在を適切に扱うようにする
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    
    let encoded = try encoder.encode(credentialRequest)
    var payload: Data? = nil
    if let jsonString = String(data: encoded, encoding: .utf8) {
        // workaround
        let credSubWithCamelCase = jsonString.replacingOccurrences(of: "\"credential_subject\"", with: "\"credentialSubject\"")
        payload = credSubWithCamelCase.data(using: .utf8)
        print("JSON String: \(jsonString)")
    } else {
        print("Failed to convert Data to String")
    }
    request.httpBody = payload

    let (data, response) = try await session.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
        throw URLError(.badServerResponse)
    }

    // レスポンスデータをデコード
    let decoder = JSONDecoder()
    return try decoder.decode(CredentialResponse.self, from: data)
}


class VCIClient {
    private(set) var credentialOffer: CredentialOffer
    private var metadata: CredentialIssuerMetadata
    private var tokenEndpoint: String

    init(credentialOfferJson: String, using session: URLSession = URLSession.shared) async throws {
        let decoder = JSONDecoder()
        guard let jsonData = credentialOfferJson.data(using: .utf8) else {
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON"])
        }

        credentialOffer = try decoder.decode(CredentialOffer.self, from: jsonData)
        metadata = try await retrieveAllMetadata(issuer: credentialOffer.credentialIssuer, using: session)
        guard let unwrappedTokenEndpoint = metadata.tokenEndpoint else {
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Token endpoint URL is missing"])
        }
        tokenEndpoint = unwrappedTokenEndpoint
    }

    func issueToken(userPin: String?, using session: URLSession = URLSession.shared) async throws -> OAuthTokenResponse {
        let grants = credentialOffer.grants
        let parameters: [String: String] = [
            "grant_type": "urn:ietf:params:oauth:grant-type:pre-authorized_code",
            "pre-authorized_code": grants?.urnIetfParams?.preAuthorizedCode ?? "",
            "user_pin": userPin ?? ""
        ]
        return try await postTokenRequest(to: URL(string: tokenEndpoint)!, with: parameters, using: session)
    }
    
    func issueCredential(payload: CredentialRequest, accessToken: String, using session: URLSession = URLSession.shared) async throws -> CredentialResponse {
        guard let credentialEndpont = metadata.credentialEndpoint else {
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Credential endpoint URL is missing"])
        }
        let url = URL(string: credentialEndpont)!
        return try await postCredentialRequest(payload, to: url, accessToken: accessToken, using: session)
    }
}

protocol CredentialRequest: Encodable {
    var format: String { get }
    var proof: Proof? { get }
}

struct Proof: Encodable {
    let proofType: String
    let jwt: String

    enum CodingKeys: String, CodingKey {
        case proofType = "proof_type"
        case jwt
    }
}

struct CredentialRequestSdJwtVc: CredentialRequest {
    let format: String
    let proof: Proof?
    let credentialDefinition: [String: String]
}

struct CredentialRequestJwtVc: CredentialRequest {
    let format: String
    let proof: Proof?
    let credentialDefinition: CredentialDefinitionJwtVc
}

struct CredentialResponse: Codable {
    let format: String
    let credential: String
    let cNonce: String?
    let cNonceExpiresIn: Int?

    enum CodingKeys: String, CodingKey {
        case format
        case credential
        case cNonce = "c_nonce"
        case cNonceExpiresIn = "c_nonce_expires_in"
    }
}

struct CredentialDefinitionJwtVc: Encodable {
    let type: [String]
    let credentialSubject: [String: String]
}

func createCredentialRequest(formatValue: String, vctValue: String, proof: Proof?) -> CredentialRequest {
    if formatValue == "vc+sd-jwt" {
        return CredentialRequestSdJwtVc(
            format: formatValue,
            proof: proof,
            credentialDefinition: ["vct": vctValue]
        )
    } else {
        return CredentialRequestJwtVc(
            format: formatValue,
            proof: proof,
            credentialDefinition: CredentialDefinitionJwtVc(type: [vctValue], credentialSubject: [:])
        )
    }
}
