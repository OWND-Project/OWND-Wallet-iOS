//
//  TokenIssuer.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2023/12/26.
//

import Foundation

func postTokenRequest(
    to url: URL, with tokenRequest: OAuthTokenRequest, using session: URLSession = URLSession.shared
) async throws -> OAuthTokenResponse {
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

    let encoder = URLEncodedFormEncoder()
    request.httpBody = try encoder.encode(tokenRequest)

    let (data, response) = try await session.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
        throw URLError(.badServerResponse)
    }

    let decoder = JSONDecoder()
    // decoder.keyDecodingStrategy = .convertFromSnakeCase
    return try decoder.decode(OAuthTokenResponse.self, from: data)
}

func postCredentialRequest(
    _ credentialRequest: any CredentialRequest, to url: URL, accessToken: String,
    using session: URLSession = URLSession.shared
) async throws -> CredentialResponse {
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
        let credSubWithCamelCase = jsonString.replacingOccurrences(
            of: "\"credential_subject\"", with: "\"credentialSubject\"")
        payload = credSubWithCamelCase.data(using: .utf8)
        print("JSON String: \(jsonString)")
    }
    else {
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

enum VCIClientError: Error {
    case undecodableCredentialOffer(json: String)
    case retrieveMetaDataError(error: MetadataError)
    case tokenEndpointIsRequired
    case credentialEndpointIsRequiredG
    case unsupportedCredentialFormat(format: String)
    case credentialEndpointIsRequired
    case jwtProofRequired
}

class VCIClient {

    private var metadata: Metadata
    private var tokenEndpoint: URL
    private var credentialEndpoint: URL
    private(set) var credentialOffer: CredentialOffer

    init(credentialOffer: CredentialOffer, metaData: Metadata) async throws {
        // set `credentialOffer`
        self.credentialOffer = credentialOffer
        // set `metadata`
        self.metadata = metaData
        // set `tokenEndpoint`
        guard let tokenUrlString = metadata.authorizationServerMetadata.tokenEndpoint,
            let tokenUrl = URL(string: tokenUrlString)
        else {
            throw VCIClientError.tokenEndpointIsRequired
        }
        tokenEndpoint = tokenUrl
        // set `credentialEndpoint`
        guard
            let credentialEndpointUrl = URL(
                string: metadata.credentialIssuerMetadata.credentialEndpoint)
        else {
            throw VCIClientError.credentialEndpointIsRequired
        }
        credentialEndpoint = credentialEndpointUrl
    }

    func issueToken(txCode: String?, using session: URLSession = URLSession.shared) async throws
        -> OAuthTokenResponse
    {
        let grants = credentialOffer.grants

        let tokenRequest: OAuthTokenRequest = OAuthTokenRequest(
            grantType: "urn:ietf:params:oauth:grant-type:pre-authorized_code",
            code: nil,
            redirectUri: nil,
            clientId: nil,
            preAuthorizedCode: grants?.preAuthorizedCode?.preAuthorizedCode,
            txCode: txCode
        )

        return try await postTokenRequest(
            to: tokenEndpoint, with: tokenRequest, using: session)
    }

    func issueCredential(
        payload: any CredentialRequest, accessToken: String,
        using session: URLSession = URLSession.shared
    ) async throws -> CredentialResponse {
        return try await postCredentialRequest(
            payload, to: credentialEndpoint, accessToken: accessToken, using: session)
    }
}

struct CredentialRequestCredentialResponseEncryption: Codable {

    // todo: Add the JWK property with the appropriate data type.
    // let jwk: ...

    let alg: String
    let enc: String

    enum CodingKeys: String, CodingKey {
        case alg, enc
    }
}

struct LdpVpProofClaim: Codable {
    let domain: String

    // REQUIRED when the Credential Issuer has provided a c_nonce. It MUST NOT be used otherwise
    let challenge: String?

    enum CodingKeys: String, CodingKey {
        case domain, challenge
    }
}

struct LdpVp: Codable {
    // todo: improve type definition
    let holder: String
    let proof: [LdpVpProofClaim]
}

protocol Proofable: Codable {
    var proofType: String { get }
}

struct JwtProof: Proofable {
    let proofType: String
    let jwt: String

    enum CodingKeys: String, CodingKey {
        case proofType = "proof_type"
        case jwt
    }
}

struct CwtProof: Proofable {
    let proofType: String
    let cwt: String

    enum CodingKeys: String, CodingKey {
        case proofType = "proof_type"
        case cwt
    }
}

struct LdpVpProof: Proofable {
    let proofType: String
    let ldpVp: LdpVp
    enum CodingKeys: String, CodingKey {
        case proofType = "proof_type"
        case ldpVp = "ldp_vp"
    }
}

protocol CredentialRequest: Encodable {
    associatedtype ProofType: Proofable
    var format: String { get }
    var proof: ProofType? { get }

    // REQUIRED when credential_identifiers parameter was returned from the Token Response.
    // It MUST NOT be used otherwise
    var credentialIdentifier: String? { get }
    var credentialResponseEncryption: CredentialRequestCredentialResponseEncryption? { get }
}

struct CredentialRequestVcSdJwt: CredentialRequest {
    let format: String
    let proof: JwtProof?
    let credentialIdentifier: String?
    let credentialResponseEncryption: CredentialRequestCredentialResponseEncryption?

    // REQUIRED when the format parameter is present in the Credential Request. It MUST NOT be used otherwise
    let vct: String?
    let claims: [String: Claim]?
    enum CodingKeys: String, CodingKey {
        case format, proof, vct, claims
        case credentialIdentifier = "credential_identifier"
        case credentialResponseEncryption = "credential_response_encryption"
    }
}

struct CredentialRequestJwtVcJson: CredentialRequest {
    let format: String
    let proof: JwtProof?
    var credentialIdentifier: String?
    var credentialResponseEncryption: CredentialRequestCredentialResponseEncryption?

    // REQUIRED when the format parameter is present in the Credential Request.
    // It MUST NOT be used otherwise
    let credentialDefinition: CredentialDefinitionJwtVcJson?

    enum CodingKeys: String, CodingKey {
        case format, proof
        case credentialIdentifier = "credential_identifier"
        case credentialResponseEncryption = "credential_response_encryption"
        case credentialDefinition = "credential_definition"
    }
}

struct CredentialResponse: Codable {
    let credential: String
    let transactionId: String?
    let cNonce: String?
    let cNonceExpiresIn: Int?
    let notificationId: String?
    enum CodingKeys: String, CodingKey {
        case credential
        case transactionId = "transaction_id"
        case cNonce = "c_nonce"
        case cNonceExpiresIn = "c_nonce_expires_in"
        case notificationId = "notification_id"
    }
}

struct CredentialDefinitionJwtVcJson: Encodable {
    let type: [String]
    let credentialSubject: [String: ClaimOnlyMandatory]?
}

func createCredentialRequest(formatValue: String, credentialType: String, proofable: Proofable?)
    throws -> any CredentialRequest
{
    switch formatValue {
        case "vc+sd-jwt":
            // Proof is optional. Only if present, convert to the appropriate type.
            var proof: JwtProof? = nil
            if let someProof = proofable {
                guard let jwtProof = someProof as? JwtProof else {
                    throw VCIClientError.jwtProofRequired
                }
                proof = jwtProof
            }
            return CredentialRequestVcSdJwt(
                format: formatValue,
                proof: proof,
                credentialIdentifier: nil,
                credentialResponseEncryption: nil,
                vct: credentialType,
                claims: nil
            )
        case "jwt_vc_json":
            // Proof is optional. Only if present, convert to the appropriate type.
            var proof: JwtProof? = nil
            if let someProof = proofable {
                guard let jwtProof = someProof as? JwtProof else {
                    throw VCIClientError.jwtProofRequired
                }
                proof = jwtProof
            }
            return CredentialRequestJwtVcJson(
                format: formatValue,
                proof: proof,
                credentialDefinition:
                    CredentialDefinitionJwtVcJson(
                        type: [credentialType],
                        credentialSubject: nil)
            )
        default:
            throw VCIClientError.unsupportedCredentialFormat(format: formatValue)
    }
}
