//
//  MetadataClient.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2023/12/26.
//

import Foundation

func fetchCredentialIssuerMetadata(from url: URL, using session: URLSession = URLSession.shared)
    async throws -> CredentialIssuerMetadata
{
    let (data, response) = try await session.data(for: URLRequest(url: url))

    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
        throw URLError(.badServerResponse)
    }

    let decoder = JSONDecoder()
    return try decoder.decode(CredentialIssuerMetadata.self, from: data)
}

func fetchAuthServerMetadata(from url: URL, using session: URLSession = URLSession.shared)
    async throws -> AuthorizationServerMetadata
{
    let (data, response) = try await session.data(for: URLRequest(url: url))

    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
        throw URLError(.badServerResponse)
    }

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return try decoder.decode(AuthorizationServerMetadata.self, from: data)
}

enum MetadataError: Error {
    case separateAuthorizationServerError(issuer: String, authorizationServer: String)
    case missingAuthorizationEndpoint(authorizationServer: String)
    case missingTokenEndpoint(authorizationServer: String)
}

func retrieveAllMetadata(issuer: String, using session: URLSession = URLSession.shared) async throws
    -> CredentialIssuerMetadata
{
    let url =
        "\(issuer.hasSuffix("/") ? String(issuer.dropLast()) : issuer)/.well-known/openid-credential-issuer"

    var authorizationServer: String = issuer
    var credentialIssuerMetadata: CredentialIssuerMetadata =
        try await fetchCredentialIssuerMetadata(from: URL(string: url)!, using: session)

    if let az = credentialIssuerMetadata.authorizationServers?.first {
        authorizationServer = az
    }

    let authUrl =
        "\(authorizationServer.hasSuffix("/") ? String(authorizationServer.dropLast()) : authorizationServer)/.well-known/oauth-authorization-server"
    let authMetadata = try await fetchAuthServerMetadata(
        from: URL(string: authUrl)!, using: session)
    if authMetadata.authorizationEndpoint == nil {
        throw MetadataError.missingAuthorizationEndpoint(authorizationServer: authorizationServer)
    }
    if issuer != authorizationServer {
        throw MetadataError.separateAuthorizationServerError(
            issuer: issuer, authorizationServer: authorizationServer)
    }

    if let tokenEndpoint = authMetadata.tokenEndpoint {
        credentialIssuerMetadata.tokenEndpoint = tokenEndpoint
    }
    else {
        throw MetadataError.missingTokenEndpoint(authorizationServer: authorizationServer)
    }

    return credentialIssuerMetadata
}
