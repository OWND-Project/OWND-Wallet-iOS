//
//  MetadataClient.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2023/12/26.
//

import Foundation

enum MetadataError: Error {
    // networking error
    case invalidIssuerUrl(issuer: String)
    case httpRequestError(url: URL)
    case httpResponseError(response: URLResponse)

    // data handling error
    case decodingError(data: Data)
    case missingAuthorizationEndpoint(authorizationServer: URL)
    case missingTokenEndpoint(authorizationServer: URL)

    case unexpectedError
}

func fetchMetadata<T: Decodable>(
    from url: URL, to type: T.Type, using session: URLSession = URLSession.shared
) async throws -> T {
    var data: Data
    var response: URLResponse

    do {
        (data, response) = try await session.data(for: URLRequest(url: url))
    }
    catch {
        throw MetadataError.httpRequestError(url: url)
    }

    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
        throw MetadataError.httpResponseError(response: response)
    }

    let decoder = JSONDecoder()

    do {
        let metaData = try decoder.decode(T.self, from: data)
        return metaData
    }
    catch {
        throw MetadataError.decodingError(data: data)
    }
}

func fetchCredentialIssuerMetadata(from url: URL, using session: URLSession = URLSession.shared)
    async throws -> CredentialIssuerMetadata
{
    return try await fetchMetadata(from: url, to: CredentialIssuerMetadata.self, using: session)
}

func fetchAuthServerMetadata(from url: URL, using session: URLSession = URLSession.shared)
    async throws -> AuthorizationServerMetadata
{
    return try await fetchMetadata(from: url, to: AuthorizationServerMetadata.self, using: session)
}

func retrieveAllMetadata(issuer: String, using session: URLSession = URLSession.shared)
    async
    throws -> Metadata
{
    guard let issuerUrl = URL(string: issuer) else {
        throw MetadataError.invalidIssuerUrl(issuer: issuer)
    }

    let credentialIssuerMetadataUrl =
        issuerUrl
        .appendingPathComponent(".well-known")
        .appendingPathComponent("openid-credential-issuer")

    let credentialIssuerMetadata = try await fetchCredentialIssuerMetadata(
        from: credentialIssuerMetadataUrl, using: session)

    var authorizationServerUrl: URL = issuerUrl
    if let authorizationServers = credentialIssuerMetadata.authorizationServers {
        for server in authorizationServers {
            if let tmpAuthorizationServerUrl = URL(string: server) {
                authorizationServerUrl = tmpAuthorizationServerUrl
                break
            }
        }
    }

    let authorizationServerMetadataUrl =
        authorizationServerUrl
        .appendingPathComponent(".well-known")
        .appendingPathComponent("oauth-authorization-server")

    let authorizationServerMetadata = try await fetchAuthServerMetadata(
        from: authorizationServerMetadataUrl, using: session)

    let grantTypesSupported = authorizationServerMetadata.grantTypesSupported
    let authorizationEndpoint = authorizationServerMetadata.authorizationEndpoint
    let tokenEndpoint = authorizationServerMetadata.tokenEndpoint

    if authorizationEndpoint == nil {
        // todo: Check the `grantTypes` and if all of them are types that do not use the
        //   Authorization Endpoint, there is no need to generate an error.
        throw
            MetadataError.missingAuthorizationEndpoint(authorizationServer: authorizationServerUrl)
    }

    if tokenEndpoint == nil {
        if grantTypesSupported == nil || grantTypesSupported != ["implicit"] {
            // If omitted, the default value is "["authorization_code", "implicit"]".
            throw
                MetadataError.missingTokenEndpoint(
                    authorizationServer: authorizationServerMetadataUrl)
        }
    }

    let result = Metadata(
        credentialIssuerMetadata: credentialIssuerMetadata,
        authorizationServerMetadata: authorizationServerMetadata)

    return result
}
