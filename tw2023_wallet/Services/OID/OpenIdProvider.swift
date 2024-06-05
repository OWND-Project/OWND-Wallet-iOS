//
//  OpenIdProvider.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2024/01/03.
//

import Foundation
import JOSESwift

struct ProviderOption {
    let signingCurve: String = "secp256k1"
    let signingAlgo: String = "ES256K"
    let expiresIn: Int64 = 600
}

enum OpenIdProviderRequestException: Error {
    case badAuthRequest
    // already consumed request, failed to get client additinal info(request jwt, client metada, etc), etc
    case unavailableAuthRequest
    case validateRequestJwtFailure
}

enum OpenIdProviderIllegalInputException: Error {
    case illegalClientIdInput
    case illegalJsonInputInput
    case illegalResponseTypeInput
    case illegalResponseModeInput
    case illegalNonceInput
    case illegalPresentationDefinitionInput
    case illegalRedirectUriInput
    case illegalDisclosureInput
    case illegalCredentialInput
}

enum OpenIdProviderIllegalStateException: Error {
    case illegalAuthRequestProcessedDataState
    case illegalClientIdState
    case illegalResponseModeState
    case illegalNonceState
    case illegalPresentationDefinitionState
    case illegalRedirectUriState
    case illegalKeypairState
    case illegalKeyBindingState
    case illegalJwkThumbprintState
    case illegalJsonState
    case illegalState
}

class OpenIdProvider {
    private var option: ProviderOption
    private var keyPair: KeyPair?  // for proof of posession for jwt_vc_json presentation
    private var secp256k1KeyPair: KeyPairData?  // for sub of id_token
    private var keyBinding: KeyBinding?
    private var jwtVpJsonGenerator: JwtVpJsonGenerator?
    var authRequestProcessedData: ProcessedRequestData?
    var clientId: String?
    var responseType: String?
    var responseMode: ResponseMode?
    var nonce: String?
    var state: String?
    var redirectUri: String?
    var presentationDefinition: PresentationDefinition?

    init(_ option: ProviderOption) {
        self.option = option
    }

    func setKeyPair(keyPair: KeyPair) {
        self.keyPair = keyPair
    }

    func setSecp256k1KeyPair(keyPair: KeyPairData) {
        self.secp256k1KeyPair = keyPair
    }

    func setKeyBinding(keyBinding: KeyBinding) {
        self.keyBinding = keyBinding
    }

    func setJwtVpJsonGenerator(jwtVpJsonGenerator: JwtVpJsonGenerator) {
        self.jwtVpJsonGenerator = jwtVpJsonGenerator
    }

    func processSIOPRequest(_ url: String, using session: URLSession = URLSession.shared) async
        -> Result<ProcessedRequestData, AuthorizationRequestError>
    {
        print("parseAndResolve")
        let processedRequestDataResult = await parseAndResolve(from: url)
        switch processedRequestDataResult {
            case .success(let processedRequestData):
                if processedRequestData.requestIsSigned {
                    print("verify request jwt")
                    let jwt = processedRequestData.requestObjectJwt
                    let clientMetadata = processedRequestData.clientMetadata
                    let result = await verifyRequestObject(jwt: jwt, clientMetadata: clientMetadata)
                    switch result {
                        case .success:
                            print("verify request jwt success")
                        case .failure(let error):
                            return .failure(error)
                    }
                }

                let authRequest = processedRequestData.authorizationRequest
                let requestObj = processedRequestData.requestObject
                guard let _clientId = requestObj.clientId ?? authRequest.clientId else {
                    return .failure(
                        .authRequestInputError(
                            reason: .compliantError(reason: "can not get client id")))
                }
                clientId = _clientId

                let clientScheme = requestObj.clientIdScheme ?? authRequest.clientIdScheme
                if clientScheme == "redirect_uri" {
                    let responseUri = requestObj.responseUri ?? authRequest.responseUri
                    if clientId != responseUri {
                        return .failure(
                            .authRequestInputError(
                                reason: .compliantError(reason: "Invalid client_id or response_uri")
                            ))
                    }
                }

                guard let responseType = requestObj.responseType ?? authRequest.responseType else {
                    return .failure(
                        .authRequestInputError(
                            reason: .compliantError(reason: "can not get response type")))
                }
                // https://openid.net/specs/openid-4-verifiable-presentations-1_0.html#section-5-11.6
                // response_mode:
                // OPTIONAL. Defined in [OAuth.Responses]. This parameter is used (through the new Response Mode direct_post) to ask the Wallet to send the response to the Verifier via an HTTPS connection (see Section 6.2 for more details). It is also used to request signing and encrypting (see Section 6.3 for more details). If the parameter is not present, the default value is fragment.
                if let _responseMode = requestObj.responseMode ?? authRequest.responseMode {
                    responseMode = _responseMode
                }
                else {
                    responseMode = ResponseMode.fragment
                }
                guard let _nonce = requestObj.nonce ?? authRequest.nonce else {
                    return .failure(
                        .authRequestInputError(reason: .compliantError(reason: "can not get nonce"))
                    )
                }
                nonce = _nonce
                state = requestObj.state ?? authRequest.state ?? ""
                if responseType.contains("vp_token") {
                    guard let _presentationDefinition = processedRequestData.presentationDefinition
                    else {
                        return .failure(
                            .authRequestInputError(
                                reason: .compliantError(
                                    reason: "can not get presentation definition")))
                    }
                    presentationDefinition = _presentationDefinition
                }
                guard let _redirectUri = requestObj.redirectUri ?? authRequest.requestUri else {
                    return .failure(
                        .authRequestInputError(
                            reason: .compliantError(reason: "can not get redirect uri")))
                }
                redirectUri = _redirectUri
                self.authRequestProcessedData = processedRequestData
                return .success(processedRequestData)
            case .failure(let error):
                return .failure(error)
        }
    }

    func respondSIOPResponse(using session: URLSession = URLSession.shared) async -> Result<
        PostResult, Error
    > {
        guard let authRequestProcessedData = self.authRequestProcessedData else {
            return .failure(
                OpenIdProviderIllegalStateException.illegalAuthRequestProcessedDataState)
        }
        let authRequest = authRequestProcessedData.authorizationRequest
        let requestObj = authRequestProcessedData.requestObject
        guard let clientId = requestObj.clientId ?? authRequest.clientId else {
            return .failure(OpenIdProviderIllegalStateException.illegalClientIdState)
        }
        guard let nonce = requestObj.nonce ?? authRequest.nonce else {
            return .failure(OpenIdProviderIllegalStateException.illegalNonceState)
        }
        guard let redirectUri = requestObj.redirectUri ?? authRequest.requestUri else {
            return .failure(OpenIdProviderIllegalStateException.illegalRedirectUriState)
        }

        let prefix = "urn:ietf:params:oauth:jwk-thumbprint:sha-256"
        // TODO: ProviderOptionのアルゴリズムで分岐可能にする
        guard let keyPair = secp256k1KeyPair else {
            return .failure(OpenIdProviderIllegalStateException.illegalKeypairState)
        }
        let x = keyPair.publicKey.0.base64URLEncodedString()
        let y = keyPair.publicKey.1.base64URLEncodedString()
        let jwk = ECPublicJwk(kty: "EC", crv: "secp256k1", x: x, y: y)
        guard let jwkThumbprint = SignatureUtil.toJwkThumbprint(jwk: jwk) else {
            return .failure(OpenIdProviderIllegalStateException.illegalJwkThumbprintState)
        }
        let sub = "\(prefix):\(jwkThumbprint)"
        let currentMilliseconds = Int64(Date().timeIntervalSince1970 * 1000)

        let idTokenPayload = IDTokenPayloadImpl(
            iss: sub,
            sub: sub,
            aud: clientId,
            iat: currentMilliseconds / 1000,
            exp: (currentMilliseconds / 1000) + option.expiresIn,
            nonce: nonce,
            subJwk: [
                "crv": jwk.crv,
                "kty": jwk.kty,
                "x": jwk.x,
                "y": jwk.y,
            ]
        )
        do {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            let jsonData = try encoder.encode(idTokenPayload)
            let payload = String(data: jsonData, encoding: .utf8)!
            let idToken = try ES256K.createJws(key: keyPair.privateKey, payload: payload)
            // TODO: support redirect response when response_mode is not `direct_post`
            let formData = ["id_token": idToken]
            print("url: \(redirectUri)")
            print(formData)
            let postResult = try await sendRequest(
                formData: formData,
                url: URL(string: redirectUri)!,
                responseMode: ResponseMode.directPost,  // todo: change to appropriate value.
                convert: convertIdTokenResponseResponse,
                using: session
            )
            print("status code: \(postResult.statusCode)")
            if let location = postResult.location {
                print("location: \(location)")
            }
            return .success(postResult)
        }
        catch {
            return .failure(error)
        }
    }

    func convertIdTokenResponseResponse(data: Data, response: HTTPURLResponse, requestURL: URL)
        throws -> PostResult
    {
        //        print("response body of siop response: \(String(data: data, encoding: .utf8) ?? "no utf string value")")
        var cookies: [String]? = nil
        if let setCookieHeader = response.allHeaderFields["Set-Cookie"] as? String {
            // 単一のクッキーを配列に格納
            cookies = [setCookieHeader]
        }
        else if let setCookieHeaders = response.allHeaderFields["Set-Cookie"] as? [String] {
            // 複数のクッキーがある場合はそのまま使用
            cookies = setCookieHeaders
        }
        if response.statusCode == 302 {
            if let locationHeader = response.allHeaderFields["Location"] as? String {
                print("Location Header: \(locationHeader)")
                // `Location`ヘッダーの値が絶対URLかどうかを確認
                let location: String
                if locationHeader.starts(with: "http://") || locationHeader.starts(with: "https://")
                {
                    // 絶対URLの場合はそのまま使用
                    location = locationHeader
                }
                else {
                    // パスのみの場合はスキーム、ホスト、ポート情報を補完
                    let scheme = requestURL.scheme ?? "http"
                    let host = requestURL.host ?? ""
                    let port = requestURL.port.map { ":\($0)" } ?? ""
                    location = "\(scheme)://\(host)\(port)\(locationHeader)"
                    //                    // パスのみの場合はホスト情報を補完
                    //                    guard let base = requestURL.baseURL else {
                    //                        // `requestURL`からベースURLを取得できない場合は`requestURL`自体を使用
                    //                        location = requestURL.scheme! + "://" + requestURL.host! + locationHeader
                    //                        return PostResult(statusCode: response.statusCode, location: location)
                    //                    }
                    //                    // ベースURLを使用して補完
                    //                    location = base.absoluteString + locationHeader
                }
                return PostResult(
                    statusCode: response.statusCode, location: location, cookies: cookies)
            }
            else {
                // `Location`ヘッダーが見つからなかった場合の処理
                throw NetworkError.invalidResponse  // 適切なエラー処理を行う
            }
        }
        else {
            return PostResult(statusCode: response.statusCode, location: nil, cookies: cookies)
        }
    }

    func convertVpTokenResponseResponse(data: Data, response: HTTPURLResponse, requestURL: URL)
        throws -> PostResult
    {
        let statusCode = response.statusCode
        if statusCode == 200 {
            if let contentType = response.allHeaderFields["Content-Type"] as? String {
                if contentType == "application/json" {
                    guard
                        let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
                        let jsonDict = jsonObject as? [String: Any]
                    else {
                        throw AuthorizationError.invalidData
                    }
                    let location = jsonDict["redirect_uri"] as? String
                    return PostResult(statusCode: statusCode, location: location, cookies: nil)
                }
                else {
                    return PostResult(statusCode: statusCode, location: nil, cookies: nil)
                }
            }
            else {
                return PostResult(statusCode: statusCode, location: nil, cookies: nil)
            }
        }
        else {
            return PostResult(statusCode: statusCode, location: nil, cookies: nil)
        }
    }

    func respondVPResponse(
        credentials: [SubmissionCredential], using session: URLSession = URLSession.shared
    ) async -> Result<(PostResult, [SharedContent], [String?]), Error> {
        //        guard let authRequestProcessedData = self.authRequestProcessedData else {
        //            throw OpenIdProviderIllegalStateException.illegalAuthRequestProcessedDataState
        //        }
        //        let authRequest = authRequestProcessedData.authorizationRequest
        //        let requestObj = authRequestProcessedData.requestObject
        guard let clientId = clientId,
            let responseMode = responseMode,
            let nonce = nonce,
            let presentationDefinition = presentationDefinition,
            let responseUri = authRequestProcessedData?.requestObject.responseUri
        else {
            return .failure(OpenIdProviderIllegalStateException.illegalState)
        }

        let vpTokens = try! credentials.compactMap {
            credential -> (String, (String, DescriptorMap, [DisclosedClaim], String?))? in
            switch credential.format {
                case "vc+sd-jwt":
                    return (
                        credential.id,
                        try createPresentationSubmissionSdJwtVc(
                            credential: credential,
                            presentationDefinition: presentationDefinition,
                            clientId: clientId,
                            nonce: nonce
                        )
                    )

                case "jwt_vc_json":
                    return (
                        credential.id,
                        try createPresentationSubmissionJwtVc(
                            credential: credential,
                            presentationDefinition: presentationDefinition,
                            clientId: clientId,
                            nonce: nonce
                        )
                    )

                default:
                    throw IllegalArgumentException.badParams
            }
        }

        let vpTokenValue: String
        if vpTokens.count == 1 {
            vpTokenValue = vpTokens[0].1.0
        }
        else if !vpTokens.isEmpty {
            let tokens = vpTokens.map { $0.1.0 }
            let jsonEncoder = JSONEncoder()
            if let jsonData = try? jsonEncoder.encode(tokens),
                let jsonString = String(data: jsonData, encoding: .utf8)
            {
                vpTokenValue = jsonString
            }
            else {
                return .failure(OpenIdProviderIllegalStateException.illegalJsonState)
            }
        }
        else {
            vpTokenValue = ""  // 0件の場合はブランク
        }

        let presentationSubmission = PresentationSubmission(
            id: UUID().uuidString,
            definitionId: presentationDefinition.id,
            descriptorMap: vpTokens.map { $0.1.1 }
        )

        let jsonEncoder = JSONEncoder()
        jsonEncoder.keyEncodingStrategy = .convertToSnakeCase

        // オブジェクトをJSON文字列にエンコード
        let jsonData = try! jsonEncoder.encode(presentationSubmission)
        let jsonString = String(data: jsonData, encoding: .utf8)!

        do {
            var formData = ["vp_token": vpTokenValue, "presentation_submission": jsonString]
            if let state = state {
                formData["state"] = state
            }
            print("url: \(responseUri)")
            let postResult = try await sendRequest(
                formData: formData,
                url: URL(string: responseUri)!,
                responseMode: responseMode,
                convert: convertVpTokenResponseResponse,
                using: session
            )
            let sharedContents = vpTokens.map { SharedContent(id: $0.0, sharedClaims: $0.1.2) }
            let purposes = vpTokens.map { $0.1.3 }
            return .success((postResult, sharedContents, purposes))
        }
        catch {
            return .failure(error)
        }
    }
    func createPresentationSubmissionSdJwtVc(
        credential: SubmissionCredential,
        presentationDefinition: PresentationDefinition,
        clientId: String,
        nonce: String
    ) throws -> (String, DescriptorMap, [DisclosedClaim], String?) {
        // ここに実装を追加します
        let sdJwt = credential.credential

        // selectDisclosure関数の使用
        guard
            let (inputDescriptor, selectedDisclosures) = selectDisclosure(
                sdJwt: sdJwt, presentationDefinition: presentationDefinition)
        else {
            // TODO: エラーハンドリングかダミーの戻り値
            return (
                "Dummy",
                DescriptorMap(
                    id: "dummyId", format: "dummyFormat", path: "dummyPath",
                    pathNested: Path(format: "dummyFormat", path: "dummyPath")), [DisclosedClaim](),
                "dummyPurpose"
            )
        }
        print(String(describing: inputDescriptor))
        guard let keyBinding = keyBinding else {
            throw OpenIdProviderIllegalStateException.illegalKeyBindingState
        }
        let keyBindingJwt = try keyBinding.generateJwt(
            sdJwt: sdJwt, selectedDisclosures: selectedDisclosures, aud: clientId, nonce: nonce)

        let parts = sdJwt.split(separator: "~").map(String.init)
        guard let issuerSignedJwt = parts.first else {
            return (
                "Error",
                DescriptorMap(
                    id: "error", format: "error", path: "error",
                    pathNested: Path(format: "error", path: "error")), [DisclosedClaim](),
                "dummyPurpose"
            )
        }

        let hasNilValue = selectedDisclosures.contains { disclosure in
            disclosure.disclosure == nil
        }

        if hasNilValue {
            throw OpenIdProviderIllegalInputException.illegalDisclosureInput
        }

        let vpToken =
            issuerSignedJwt + "~"
            + selectedDisclosures.map { $0.disclosure! }.joined(separator: "~") + "~"
            + keyBindingJwt

        let dm = DescriptorMap(
            id: credential.inputDescriptor.id,
            format: credential.format,
            path: "$",
            pathNested: nil
        )

        let disclosedClaims = selectedDisclosures.compactMap { disclosure -> DisclosedClaim? in
            guard let key = disclosure.key else { return nil }
            return DisclosedClaim(
                id: credential.id, types: credential.types, name: key, value: disclosure.value)
        }

        return (vpToken, dm, disclosedClaims, inputDescriptor.purpose)
    }

    func createPresentationSubmissionJwtVc(
        credential: SubmissionCredential,
        presentationDefinition: PresentationDefinition,
        clientId: String, nonce: String
    ) throws -> (String, DescriptorMap, [DisclosedClaim], String?) {
        do {
            let (_, payload, _) = try JWTUtil.decodeJwt(jwt: credential.credential)
            if let vcDictionary = payload["vc"] as? [String: Any],
                let credentialSubject = vcDictionary["credentialSubject"] as? [String: Any]
            {
                let disclosedClaims = credentialSubject.map { key, value in
                    return DisclosedClaim(
                        id: credential.id, types: credential.types, name: key,
                        value: value as? String)
                }
                guard
                    let vpToken = self.jwtVpJsonGenerator?.generateJwt(
                        vcJwt: credential.credential, headerOptions: HeaderOptions(),
                        payloadOptions: JwtVpJsonPayloadOptions(aud: clientId, nonce: nonce))
                else {
                    throw OpenIdProviderIllegalInputException.illegalCredentialInput
                }

                let descriptorMap = JwtVpJsonPresentation.genDescriptorMap(
                    inputDescriptorId: credential.inputDescriptor.id)
                return (
                    vpToken,
                    descriptorMap,
                    disclosedClaims,
                    nil
                )
            }
            else {
                throw OpenIdProviderIllegalInputException.illegalCredentialInput
            }
        }
        catch {
            print("Error: \(error)")
            throw error
        }
    }
}

enum NetworkError: Error {
    case invalidResponse
    case statusCodeNotSuccessful(Int)
    case decodingError
    case other(Error)
}

func sendRequest<T: Decodable>(
    formData: [String: String],
    url: URL,
    responseMode: ResponseMode,
    convert: ((Data, HTTPURLResponse, URL) throws -> T)? = nil,
    using session: URLSession = URLSession.shared
) async throws -> T {

    var request: URLRequest

    switch responseMode {
        case .directPost:
            request = URLRequest(url: url)
            request.httpMethod = "POST"

            let formBody = formData.map { key, value in
                let encodedKey =
                    key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                let encodedValue =
                    value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                return "\(encodedKey)=\(encodedValue.replacingOccurrences(of: "+", with: "%2B"))"
            }.joined(separator: "&")

            request.httpBody = formBody.data(using: .utf8)
            request.setValue(
                "application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        default:
            print("Unsupported responseMode : \(responseMode)")
            throw OpenIdProviderIllegalStateException.illegalResponseModeState
    }

    do {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200...399).contains(httpResponse.statusCode) else {
            throw NetworkError.statusCodeNotSuccessful(httpResponse.statusCode)
        }

        if let convert = convert {
            return try convert(data, httpResponse, url)
        }
        else {
            return data as! T
        }
    }
    catch {
        throw NetworkError.other(error)
    }
}

class NoRedirectDelegate: NSObject, URLSessionTaskDelegate {
    func urlSession(
        _ session: URLSession, task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        // リダイレクトを停止する
        completionHandler(nil)
    }
}

//enum IllegalStateException: Error {
//    case illegalState
//
//    var message: String {
//        switch self {
//        case .illegalState:
//            return "Illegal state occurred."
//        }
//    }
//}

struct SubmissionCredential: Codable, Equatable {
    let id: String
    let format: String
    let types: [String]
    let credential: String
    let inputDescriptor: InputDescriptor

    static func == (lhs: SubmissionCredential, rhs: SubmissionCredential) -> Bool {
        return lhs.id == rhs.id
    }
}

struct DisclosedClaim: Codable {
    let id: String  // credential identifier
    let types: [String]
    let name: String
    let value: String?
    // let path: String   // when nested claim is supported, it may be needed
}

struct SharedContent: Codable {
    let id: String
    let sharedClaims: [DisclosedClaim]
}

struct Triple<A, B, C> {
    let first: A
    let second: B
    let third: C
}

func satisfyConstrains(credential: [String: Any], presentationDefinition: PresentationDefinition)
    -> Bool
{
    // TODO: 暫定で固定パス(vc.credentialSubject)のクレデンシャルをサポートする
    guard let vc = credential["vc"] as? [String: Any] else {
        print("unsupported format")
        print(credential)
        return false
    }
    guard let credentialSubject: [String: Any] = vc["credentialSubject"] as? [String: Any] else {
        print("unsupported format")
        print(credential)
        return false
    }
    let inputDescriptors = presentationDefinition.inputDescriptors

    var matchingFieldsCount = 0

    for inputDescriptor in inputDescriptors {
        guard let fields = inputDescriptor.constraints.fields else { continue }

        for field in fields {
            let isFieldMatched = field.path.contains { jsonPath -> Bool in
                let pathComponents = jsonPath.components(separatedBy: ".")
                if let lastComponent = pathComponents.last, lastComponent != "$" {
                    let key = lastComponent.replacingOccurrences(of: "vc.", with: "")
                    // credentialのキーとして含まれているか判定
                    return credentialSubject.keys.contains(key)
                }
                return false
            }

            if isFieldMatched {
                matchingFieldsCount += 1
                break  // pathのいずれかがマッチしたら、そのfieldは条件を満たしていると見なす
            }
        }
    }

    print("match count: \(matchingFieldsCount)")
    // 元のfieldsの件数と該当したfieldの件数が一致するか判定
    return matchingFieldsCount == inputDescriptors.compactMap({ $0.constraints.fields }).count
}

func selectDisclosure(sdJwt: String, presentationDefinition: PresentationDefinition) -> (
    InputDescriptor, [Disclosure]
)? {
    let parts = sdJwt.split(separator: "~").map(String.init)
    let newList = parts.count > 2 ? Array(parts.dropFirst().dropLast()) : []

    // [Disclosure]
    let disclosures = decodeDisclosureFunction(newList)
    /*
     example of source payload
         {
           "claim1": "foo",
           "claim2": "bar"
         }
     */
    let sourcePayload = Dictionary(uniqueKeysWithValues: disclosures.map { ($0.key, $0.value) })

    for inputDescriptor in presentationDefinition.inputDescriptors {
        let matchingDisclosures: [Disclosure] = presentationDefinition.inputDescriptors.compactMap {
            inputDescriptor in
            /*
             array of string values filtered by `inputDescriptor.constraints.fields.path`

             example of input_descriptors
                 "input_descriptors": [
                   {
                     "constraints": {
                       "fields": [
                         {
                           "path": ["$.claim1"], ここが配列になっている理由はformat毎に異なるpathを指定するため
                         }
                       ]
                     }
                   }
                 ]
             */
            let fieldKeys = inputDescriptor.constraints.fields?.flatMap { field in
                // field.pathからfieldkeysを抽出
                field.path.compactMap { jsonPath in
                    let key = String(jsonPath.dropFirst(2))  // "$."を削除
                    if sourcePayload.keys.contains(key) {
                        return key
                    }
                    else {
                        return nil
                    }
                }
            }

            // disclosuresをfieldKeysに基づいてフィルタリング
            return fieldKeys.flatMap { fieldKey in
                disclosures.filter { disclosure in
                    if let disclosureKey = disclosure.key {
                        return fieldKey.contains(disclosureKey)
                    }
                    else {
                        return false
                    }
                }
            } ?? []
        }.flatMap { $0 }

        if !matchingDisclosures.isEmpty {
            return (inputDescriptor, matchingDisclosures)
        }
    }
    return nil
}

var decodeDisclosureFunction: ([String]) -> [Disclosure] = SDJwtUtil.decodeDisclosure

protocol KeyBinding {
    func generateJwt(sdJwt: String, selectedDisclosures: [Disclosure], aud: String, nonce: String)
        throws -> String
}

protocol JwtVpJsonGenerator {
    func generateJwt(
        vcJwt: String, headerOptions: HeaderOptions, payloadOptions: JwtVpJsonPayloadOptions
    ) -> String
    func getJwk() -> [String: String]
}

struct SIOPLoginResponseData: Decodable {
    let Location: String
}

struct PostResult: Decodable {
    let statusCode: Int
    let location: String?
    let cookies: [String]?
}

struct HeaderOptions: Codable {
    var alg: String = "ES256"
    var typ: String = "JWT"
    var jwk: String? = nil
}

struct JwtVpJsonPayloadOptions: Codable {
    var iss: String? = nil
    var jti: String? = nil
    var aud: String
    var nbf: Int64? = nil
    var iat: Int64? = nil
    var exp: Int64? = nil
    var nonce: String
}

struct VpJwtPayload: Codable {
    var iss: String?
    var jti: String?
    var aud: String?
    var nbf: Int64?
    var iat: Int64?
    var exp: Int64?
    var nonce: String?
    var vp: [String: Any]

    enum CodingKeys: String, CodingKey {
        case iss, jti, aud, nbf, iat, exp, nonce, vp
    }

    init(
        iss: String?, jti: String?, aud: String?, nbf: Int64?, iat: Int64?, exp: Int64?,
        nonce: String?, vp: [String: Any]
    ) {
        self.iss = iss
        self.jti = jti
        self.aud = aud
        self.nbf = nbf
        self.iat = iat
        self.exp = exp
        self.nonce = nonce
        self.vp = vp
    }

    // Custom encoding to handle [String: Any] in vp
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(iss, forKey: .iss)
        try container.encodeIfPresent(jti, forKey: .jti)
        try container.encodeIfPresent(aud, forKey: .aud)
        try container.encodeIfPresent(nbf, forKey: .nbf)
        try container.encodeIfPresent(iat, forKey: .iat)
        try container.encodeIfPresent(exp, forKey: .exp)
        try container.encodeIfPresent(nonce, forKey: .nonce)

        let vpData = try JSONSerialization.data(withJSONObject: vp, options: [])
        let vpString = String(data: vpData, encoding: .utf8)
        try container.encodeIfPresent(vpString, forKey: .vp)
    }

    // Custom decoding to handle [String: Any] in vp
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        iss = try container.decodeIfPresent(String.self, forKey: .iss)
        jti = try container.decodeIfPresent(String.self, forKey: .jti)
        aud = try container.decodeIfPresent(String.self, forKey: .aud)
        nbf = try container.decodeIfPresent(Int64.self, forKey: .nbf)
        iat = try container.decodeIfPresent(Int64.self, forKey: .iat)
        exp = try container.decodeIfPresent(Int64.self, forKey: .exp)
        nonce = try container.decodeIfPresent(String.self, forKey: .nonce)

        let vpString = try container.decodeIfPresent(String.self, forKey: .vp)
        if let vpString = vpString, let vpData = vpString.data(using: .utf8) {
            vp =
                (try JSONSerialization.jsonObject(with: vpData, options: []) as? [String: Any])
                ?? [:]
        }
        else {
            vp = [:]
        }
    }
}
