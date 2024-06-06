//
//  SharingRequestViewModel.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2023/12/22.
//

import Foundation

struct AuthRequest {
    let clientId: String
}

enum SharingRequestIllegalStateException: Error {
    case illegalAccountState
    case illegalKeyRingState
    case illegalKeypairState
    case illegalKeyBindingState
    case illegalJwkThumbprintState
    case illegalSeedState
    case illegalState
}

@Observable
class SharingRequestViewModel {
    var isLoading = false
    var hasLoadedData = false
    var clientInfo: ClientInfo? = nil
    var presentationDefinition: PresentationDefinition? = nil
    var selectedCredential: Bool = false
    var openIdProvider: OpenIdProvider? = nil
    var seed: String?
    var account: Account?
    var showAlert = false
    var alertTitle = ""
    var alertMessage = ""

    func accessPairwiseAccountManager() async -> Bool {
        do {
            let dataStore = PreferencesDataStore.shared
            let seed = try await dataStore.getSeed()
            if seed != nil && !seed!.isEmpty {
                print("Accessed seed successfully")
                self.seed = seed
            }
            else {
                // 初回のシード生成
                guard let hdKeyRing = HDKeyRing() else {
                    throw SharingRequestIllegalStateException.illegalKeyRingState
                }
                guard let newSeed = hdKeyRing.getMnemonicString() else {
                    throw SharingRequestIllegalStateException.illegalSeedState
                }
                try dataStore.saveSeed(newSeed)
                self.seed = newSeed
            }
            return true
        }
        catch {
            // 生体認証のエラー処理
            print("Biometric Error: \(error)")
            return false
        }
    }

    func loadData(_ url: String, index: Int = -1) async {
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else {
            print("now previewing")
            return
        }
        guard !hasLoadedData else { return }
        isLoading = true
        print("load data..")
        openIdProvider = OpenIdProvider(ProviderOption())
        do {
            print("process SIOP Request")
            let result = await openIdProvider?.processSIOPRequest(url)
            switch result {
                case .success(let processedRequestData):
                    // gen client info
                    let clientMetadata = processedRequestData.clientMetadata
                    guard let clientId = clientMetadata.clientId ?? openIdProvider?.clientId else {
                        print(clientMetadata)
                        throw IllegalArgumentException.badParams
                    }
                    guard let url = URL(string: clientId), let schema = url.scheme,
                        let host = url.host
                    else {
                        throw SharingRequestIllegalStateException.illegalState
                    }
                    let clientUrl = "\(schema)://\(host)"
                    print("clientId: \(clientId)")
                    print("client url: \(clientUrl)")
                    let (cert, derCertificates) = extractFirstCertSubject(url: clientUrl)
                    // verify ov of rp
                    print("verify cert chain")
                    let b = try? SignatureUtil.validateCertificateChain(
                        derCertificates: derCertificates)
                    print("verified: \(b ?? false)")

                    guard let seed = self.seed else {
                        throw SharingRequestIllegalStateException.illegalSeedState
                    }

                    print("get account")
                    account = try getAccount(seed: seed, rp: clientId, index: index)

                    print("set client info")
                    clientInfo = ClientInfo(
                        name: clientMetadata.clientName ?? "",
                        logoUrl: clientMetadata.logoUri ?? "",
                        policyUrl: clientMetadata.policyUri ?? "",
                        tosUrl: clientMetadata.tosUri ?? "",
                        jwkThumbprint: account!.thumbprint,
                        certificateInfo: cert,
                        verified: b ?? false
                    )

                    print("set presentation request")
                    // set presentation def
                    presentationDefinition = processedRequestData.presentationDefinition
                    print("success")
                case .failure(let error):
                    print(error)
                    switch error {
                        case .authRequestInputError(let subError):
                            print(subError)
                            alertTitle = "Found wrong input. It needs to confirm client system."
                            alertMessage = subError.localizedDescription
                        case .authRequestClientError(let subError):
                            print(subError)
                            switch subError {
                                case .badRequest(let reason):
                                    alertTitle =
                                        "Sent Wrong request. It needs to confirm the request sent."
                                    alertMessage = reason
                                case .compliantError(let reason):
                                    alertTitle =
                                        "Client error occurred. It needs to confirm wallet app."
                                    alertMessage = reason
                            }
                        case .authRequestServerError(let subError):
                            print(subError)
                            alertTitle = "Unable to process request. Please try again."
                            alertMessage = subError.localizedDescription
                        case .unknown(let subError):
                            alertTitle = "Unable to process request."
                            if let subError = subError {
                                print(subError)
                                alertMessage = subError.localizedDescription
                            }
                    }
                    showAlert = true
                case .none:
                    print("none")
            }
        }
        catch {
            print(error)
        }
        isLoading = false
        hasLoadedData = true
        print("done")
    }

    func getAccount(seed: String, rp: String, index: Int) throws -> Account {
        print("getAccount by rp: \(rp)")
        guard let accountManager = PairwiseAccount(mnemonicWords: seed) else {
            throw SharingRequestIllegalStateException.illegalAccountState
        }
        let idTokenSharingHistories = getStoredAccounts()
        let accounts = idTokenSharingHistories.compactMap {
            accountManager.indexToAccount(index: Int($0.accountIndex), rp: $0.rp)
        }
        accountManager.accounts = accounts
        // TODO: 無効化アカウントのindexを除外する設計が必要(ストレージに保存しておき、そのindexが渡されたら-1(新規扱い)に差し替える
        var account = accountManager.getAccount(rp: rp, index: index)
        if account == nil {
            account = accountManager.nextAccount()
        }
        else {
            print("\(account!) is found")
        }
        return account!
    }

    func getStoredAccounts() -> [Datastore_IdTokenSharingHistory] {
        print("getStoredAccounts")
        let storeManager = IdTokenSharingHistoryManager(container: nil)
        let idTokenSharingHistories = storeManager.getAll()
        return idTokenSharingHistories
    }

    func shareIdToken() async -> Result<PostResult, Error> {
        print("share id token")
        guard let openIdProvider = openIdProvider,
            let account = account,
            let seed = seed,
            let accountManager = PairwiseAccount(mnemonicWords: seed)
        else {
            let errorState =
                openIdProvider == nil
                ? ShareIdTokenError.illegalOpenIdProviderState
                : account == nil
                    ? ShareIdTokenError.illegalAccountState
                    : seed == nil
                        ? ShareIdTokenError.illegalSeedState : ShareIdTokenError.accountManagerError
            print("\(errorState): Initialization Failed")
            return .failure(errorState)
        }

        let publicKey = accountManager.getPublicKey(index: account.index)
        let privateKey = accountManager.getPrivateKey(index: account.index)

        let keyPair = KeyPairData(publicKey: publicKey, privateKey: privateKey)
        openIdProvider.setSecp256k1KeyPair(keyPair: keyPair)

        let delegate = NoRedirectDelegate()
        let configuration = URLSessionConfiguration.default
        let session = URLSession(
            configuration: configuration, delegate: delegate, delegateQueue: nil)

        let result = await openIdProvider.respondSIOPResponse(using: session)
        switch result {
            case .success(let postResult):
                print("save history")
                let storeManager = IdTokenSharingHistoryManager(container: nil)
                var history = Datastore_IdTokenSharingHistory()
                history.rp = openIdProvider.clientId!
                // history.rp = openIdProvider.authRequestProcessedData?.clientMetadata.clientId ?? ""
                history.accountIndex = Int32(account.index)
                history.createdAt = Date().toGoogleTimestamp()
                storeManager.save(history: history)
                return .success(postResult)
            case .failure(let error):
                print("Response Error: \(error)")
                return .failure(error)
        }
    }

    func shareVpToken(credentials: [SubmissionCredential]) async -> Result<PostResult, Error> {
        print("share vp token")
        guard let openIdProvider = openIdProvider,
            let account = account,
            let _ = seed
        else {
            let errorState = SharingRequestIllegalStateException.illegalState
            print("\(errorState): Initialization Failed")
            return .failure(errorState)
        }
        print("get keypair")
        let keyBinding = KeyBindingImpl(keyAlias: Constants.Cryptography.KEY_BINDING)
        openIdProvider.setKeyBinding(keyBinding: keyBinding)

        let jwtVpJsonGenerator = JwtVpJsonGeneratorImpl(
            keyAlias: Constants.Cryptography.KEY_PAIR_ALIAS_FOR_KEY_JWT_VP_JSON)
        openIdProvider.setJwtVpJsonGenerator(jwtVpJsonGenerator: jwtVpJsonGenerator)

        let delegate = NoRedirectDelegate()
        let configuration = URLSessionConfiguration.default
        let session = URLSession(
            configuration: configuration, delegate: delegate, delegateQueue: nil)
        let result = await openIdProvider.respondVPResponse(
            credentials: credentials, using: session)
        switch result {
            case .success(let sharedResult):
                print("sharing sucess")
                let postResult = sharedResult.0
                let sharedContent = sharedResult.1
                let purposes = sharedResult.2
                let storeManager = CredentialSharingHistoryManager(container: nil)
                for (content, purpose) in zip(sharedContent, purposes) {
                    var history = Datastore_CredentialSharingHistory()
                    history.accountIndex = Int32(account.index)
                    history.createdAt = Date().toGoogleTimestamp()
                    history.credentialID = content.id
                    for (index, claim) in content.sharedClaims.enumerated() {
                        var claimInfo = Datastore_ClaimInfo()
                        claimInfo.claimKey = claim.name
                        claimInfo.claimValue = claim.value ?? ""
                        claimInfo.purpose = purpose ?? ""
                        history.claims.append(
                            claimInfo
                        )
                    }
                    let metadata = openIdProvider.authRequestProcessedData?.clientMetadata
                    history.rp = metadata?.clientId ?? ""
                    history.rpName = metadata?.clientName ?? ""
                    history.privacyPolicyURL = metadata?.policyUri ?? ""
                    history.logoURL = metadata?.logoUri ?? ""

                    storeManager.save(history: history)
                }
                return .success(postResult)
            case .failure(let error):
                print("Response Error: \(error)")
                return .failure(error)
        }
    }

    enum ShareIdTokenError: Error {
        case illegalOpenIdProviderState
        case illegalAccountState
        case illegalSeedState
        case accountManagerError
        case keyPairError
        case responseError
    }
}
