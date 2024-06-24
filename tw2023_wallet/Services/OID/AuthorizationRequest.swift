//
//  AuthorizationRequest.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2023/12/29.
//

import Foundation
import JOSESwift
import JWTDecode
import Security

enum IllegalArgumentException: Error {
    case badParams

    var message: String {
        switch self {
            case .badParams:
                return "Invalid parameters provided."
        }
    }
}

func decodeUriAsJson(uri: String) throws -> [String: Any] {
    if uri.isEmpty {
        throw IllegalArgumentException.badParams
    }

    guard let query = URLComponents(string: uri)?.query else {
        throw IllegalArgumentException.badParams
    }

    let params = query.components(separatedBy: "&").map { $0.components(separatedBy: "=") }
    var json = [String: Any]()

    for param in params {
        if param.count != 2 { continue }
        let key = param[0].removingPercentEncoding ?? ""
        let value = param[1].removingPercentEncoding ?? ""

        if let boolValue = Bool(value) {
            json[key] = boolValue
        }
        else if let intValue = Int(value) {
            json[key] = intValue
        }
        else if let data = value.data(using: .utf8),
            let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
            let jsonDict = jsonObject as? [String: Any]
        {
            json[key] = jsonDict
        }
        else {
            json[key] = value
        }
    }

    return json
}

func parse(uri: String) throws -> (String, AuthorizationRequestPayload) {
    guard let url = URL(string: uri), let scheme = url.scheme else {
        throw AuthorizationRequestError.authRequestInputError(
            reason: .compliantError(reason: "invalid url format"))
    }
    do {
        let json = try decodeUriAsJson(uri: uri)
        let ar = try AuthorizationRequestPayloadImpl(from: json)
        return (scheme, ar)
    }
    catch {
        print(error)
        throw AuthorizationRequestError.authRequestInputError(
            reason: .compliantError(reason: "failed to parse and decode url"))
    }
}

enum AuthorizationRequestInputError: Error {
    case compliantError(reason: String)
    case missingParameter(reason: String)
    case resourceNotFound(reason: String)
    case invalidJwt
}
enum AuthorizationRequestClientError: Error {
    case badRequest(reason: String)
    case compliantError(reason: String)
}
enum AuthorizationRequestServerError: Error {
    case serverError(reason: String)
}
enum AuthorizationRequestError: Error {
    case authRequestInputError(reason: AuthorizationRequestInputError)
    case authRequestClientError(reason: AuthorizationRequestClientError)
    case authRequestServerError(reason: AuthorizationRequestServerError)
    case unknown(reason: Error?)
}

enum AuthorizationError: Error {
    case parseError
    case badURL
    case badResponse
    case badClientMetadata
    case invalidJwtformat
    case parseRequestError
    case getRequestObjectFailure
    case getClientMetadataFailure
    case getPresentationDefinitionFailure
    case getJwksFailure
    case keyIdNotFoundInJwtHeader
    case validateJwtFailure(reason: JWTVerificationError)
    case serverError(statusCode: Int)
    case invalidData
    case invalidClientMetadata
    case invalidPresentationDefinition
}

func fetchJWT(from url: URL, using session: URLSession = URLSession.shared) async throws -> String {
    let (data, response) = try await session.data(from: url)

    guard let httpResponse = response as? HTTPURLResponse else {
        throw AuthorizationError.badResponse
    }

    print("status code: \(httpResponse)")
    if httpResponse.statusCode == 200 {
        print("get request object jwt sucess")
    }
    else if httpResponse.statusCode == 400 {
        throw AuthorizationRequestError.authRequestClientError(
            reason: .badRequest(reason: "request of `request object` is bad request."))
    }
    else if httpResponse.statusCode == 404 {
        throw AuthorizationRequestError.authRequestInputError(
            reason: .resourceNotFound(reason: "request object jwt"))
    }
    else {
        throw AuthorizationRequestError.unknown(reason: nil)
    }

    guard let jwtString = String(data: data, encoding: .utf8) else {
        throw AuthorizationRequestError.authRequestInputError(
            reason: .compliantError(reason: "invalid jwt string"))
    }

    return jwtString
}

func fetchJson(from url: URL, using session: URLSession = URLSession.shared) async throws
    -> [String: Any]
{
    let (data, response) = try await session.data(from: url)

    guard let httpResponse = response as? HTTPURLResponse else {
        throw AuthorizationError.badResponse
    }

    guard httpResponse.statusCode == 200 else {
        throw AuthorizationError.serverError(statusCode: httpResponse.statusCode)
    }

    guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
        let jsonDict = jsonObject as? [String: Any]
    else {
        throw AuthorizationError.invalidData
    }
    return jsonDict
}

func fetchData(from url: URL, using session: URLSession = URLSession.shared) async throws -> Data {
    let (data, response) = try await session.data(from: url)

    guard let httpResponse = response as? HTTPURLResponse else {
        throw AuthorizationError.badResponse
    }

    guard httpResponse.statusCode == 200 else {
        throw AuthorizationError.serverError(statusCode: httpResponse.statusCode)
    }
    return data
}

func processRequestObject(
    _ authorizationRequest: AuthorizationRequestPayload,
    using session: URLSession = URLSession.shared
) async throws -> (String, RequestObjectPayload) {

    if let requestJWT = authorizationRequest.request {
        let decodedJWT = try decodeJWTPayload(jwt: requestJWT)
        let ro = try RequestObjectPayloadImpl(from: decodedJWT)
        return (requestJWT, ro)
    }
    else if let requestUriString = authorizationRequest.requestUri,
        let requestUri = URL(string: requestUriString)
    {
        print("requestUri: \(requestUri)")
        let jwtString = try await fetchJWT(from: requestUri, using: session)
        let decodedJWT = try decodeJWTPayload(jwt: jwtString)
        let ro = try RequestObjectPayloadImpl(from: decodedJWT)
        return (jwtString, ro)
    }
    else {
        throw AuthorizationError.invalidData
    }
}

func processClientMetadata(
    _ authorizationRequest: AuthorizationRequestPayload, _ requestObject: RequestObjectPayload,
    using session: URLSession = URLSession.shared
) async throws -> RPRegistrationMetadataPayload {

    if let clientMetadata = requestObject.clientMetadata ?? authorizationRequest.clientMetadata {
        return clientMetadata
    }
    else {
        let clientMetadataUri =
            requestObject.clientMetadataUri ?? authorizationRequest.clientMetadataUri
        if let uri = clientMetadataUri, let requestUri = URL(string: uri) {
            let json = try await fetchJson(from: requestUri, using: session)
            return try RPRegistrationMetadataPayload(from: json)
        }
        else {
            throw AuthorizationError.invalidClientMetadata
        }
    }
}

func processPresentationDefinition(
    _ authorizationRequest: AuthorizationRequestPayload, _ requestObject: RequestObjectPayload,
    using session: URLSession = URLSession.shared
) async throws -> PresentationDefinition? {

    if let presentationDefinition = requestObject.presentationDefinition
        ?? authorizationRequest.presentationDefinition
    {
        return presentationDefinition
    }
    else {
        let presentationDefinitionUri =
            requestObject.presentationDefinitionUri
            ?? authorizationRequest.presentationDefinitionUri
        if let uri = presentationDefinitionUri, let requestUri = URL(string: uri) {
            do {
                let data = try await fetchData(from: requestUri, using: session)
                let decoder = JSONDecoder()
                return try decoder.decode(PresentationDefinition.self, from: data)
            }
            catch {
                throw AuthorizationError.invalidClientMetadata
            }
        }
        else {
            return nil
        }
    }
}

func parseAndResolve(from uri: String, using session: URLSession = URLSession.shared) async
    -> Result<ProcessedRequestData, AuthorizationRequestError>
{
    do {
        print("parse")
        let (_, authorizationRequest) = try parse(uri: uri)

        print("process request object")
        let (jwt, requestObject) = try await processRequestObject(
            authorizationRequest, using: session)
        print(requestObject)

        print("process client metadata")
        let clientMetadata = try await processClientMetadata(
            authorizationRequest, requestObject, using: session)

        print("process presentation definition")
        let presentationDefinition = try await processPresentationDefinition(
            authorizationRequest, requestObject, using: session)

        return .success(
            ProcessedRequestData(
                authorizationRequest: authorizationRequest,
                requestObjectJwt: jwt,
                requestObject: requestObject,
                clientMetadata: clientMetadata,
                presentationDefinition: presentationDefinition,
                requestIsSigned: jwt.split(separator: ".").count == 3
            )
        )
    }
    catch {
        print(error)
        if error is AuthorizationRequestError {
            return .failure(error as! AuthorizationRequestError)
        }
        else {
            return .failure(.unknown(reason: error))
        }
    }
}

struct ProcessedRequestData {
    var authorizationRequest: AuthorizationRequestPayload
    var requestObjectJwt: String
    var requestObject: RequestObjectPayload
    var clientMetadata: RPRegistrationMetadataPayload
    var presentationDefinition: PresentationDefinition?
    var requestIsSigned: Bool
}

enum JWTError: Error {
    case invalidFormat
    case invalidPayload
    case decodingFailed
}

func decodeJWTPayload(jwt: String) throws -> [String: Any] {
    let segments = jwt.components(separatedBy: ".")
    guard segments.count >= 2 else {
        throw JWTError.invalidFormat
    }

    let payloadSegment = segments[1]
    guard let payloadData = base64UrlDecode(payloadSegment) else {
        throw JWTError.invalidPayload
    }

    let jsonObject = try JSONSerialization.jsonObject(with: payloadData, options: [])
    guard let payload = jsonObject as? [String: Any] else {
        throw JWTError.decodingFailed
    }

    return payload
}

func base64UrlDecode(_ value: String) -> Data? {
    var base64 =
        value
        .replacingOccurrences(of: "-", with: "+")
        .replacingOccurrences(of: "_", with: "/")

    // パディングを追加
    let length = Double(base64.lengthOfBytes(using: .utf8))
    let requiredLength = 4 * ceil(length / 4.0)
    let paddingLength = requiredLength - length
    if paddingLength > 0 {
        let padding = "".padding(toLength: Int(paddingLength), withPad: "=", startingAt: 0)
        base64 += padding
    }

    return Data(base64Encoded: base64)
}

func fetchAndConvertJWK(
    from url: URL, withKeyId keyId: String, using session: URLSession = URLSession.shared
) async throws -> SecKey? {
    // TODO: 一時的なネットワーク障害の場合はそれとわかるように戻り値のシグネチャを変更する
    let (data, _) = try await session.data(from: url)
    let jwkSet = try JSONDecoder().decode(JWKSet.self, from: data)

    for jwk in jwkSet.keys {
        guard let jsonData = jwk.jsonData() else { continue }
        if let keyDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
            let currentKeyId = keyDict["kid"] as? String, currentKeyId == keyId
        {
            switch jwk.keyType {
                case .RSA:
                    let rsaKey = try RSAPublicKey(data: jsonData)
                    return try rsaKey.converted(to: SecKey.self)
                case .EC:
                    let ecKey = try ECPublicKey(data: jsonData)
                    return try ecKey.converted(to: SecKey.self)
                default:
                    continue
            }
        }
    }
    return nil
}

func extractKeyIdFromJwt(header: [String: Any]) -> String? {
    //    let (header, _, _) = try JWTUtil.decodeJwt(jwt: jwt)
    guard let keyId = header["kid"] as? String else {
        print("kid does not exist in jwt header")
        return nil
    }
    return keyId
}

func verifyRequestObject(
    jwt: String, clientMetadata: RPRegistrationMetadataPayload,
    using session: URLSession = URLSession.shared
) async -> Result<JWT, AuthorizationRequestError> {
    guard let jwksUrl = clientMetadata.jwksUri else {
        // 今は`jwsk_uri`のみをサポートするが、将来的には`jwks`にも対応する
        return .failure(.authRequestInputError(reason: .missingParameter(reason: "jwskUri")))
    }
    guard let decoded = try? JWTUtil.decodeJwt(jwt: jwt) else {
        print(jwt)
        return .failure(
            .authRequestInputError(reason: .compliantError(reason: "can not decode jwt")))
    }
    let (header, _, _) = decoded
    guard let keyId = extractKeyIdFromJwt(header: header) else {
        return .failure(
            .authRequestInputError(reason: .compliantError(reason: "can not find kid in header")))
    }
    do {
        guard
            let key = try await fetchAndConvertJWK(
                from: URL(string: jwksUrl)!, withKeyId: keyId, using: session)
        else {
            return .failure(
                .authRequestInputError(
                    reason: .compliantError(reason: "can not get public key from jwks url")))
        }
        print("!!!! JWT")
        print(jwt)
        print(key)
        print("")
        let result = JWTUtil.verifyJwt(jwt: jwt, publicKey: key)
        switch result {
            case .success(let jwt):
                return .success(jwt)
            case .failure(let error):
                print(error)
                return .failure(
                    .authRequestInputError(
                        reason: .compliantError(reason: "failed to validate jwt")))
        }
    }
    catch {
        return .failure(
            .authRequestInputError(
                reason: .compliantError(reason: "can not get public key from jwks url")))
    }
}
