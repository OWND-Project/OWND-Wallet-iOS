//
//  CredentialListViewModel.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2023/12/22.
//

import Foundation

class CredentialListViewModel {
    var dataModel: CredentialListModel = .init()

    private let credentialDataManager = CredentialDataManager(container: nil)

    func loadData(presentationDefinition: PresentationDefinition? = nil) {
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else {
            print("now previewing")
            return
        }
        guard !dataModel.hasLoadedData else { return }
        dataModel.isLoading = true
        print("load data..")

        var credentialList: [Credential] = []
        for rawCredential in credentialDataManager.getAllCredentials() {
            let converted = rawCredential.toCredential()
            if converted != nil {
                credentialList.append(converted!)
            }
            else {
                print("Malformed Credential Found")
            }
        }

        if let pd = presentationDefinition {
            dataModel.credentials = credentialList.filter { filterCredential($0, pd) }
        }
        else {
            dataModel.credentials = credentialList
        }

        dataModel.isLoading = false
        dataModel.hasLoadedData = true
        print("done")
    }

    func filterCredential(
        _ credential: Credential, _ presentationDefinition: PresentationDefinition
    ) -> Bool {
        let format = credential.format
        print("format: \(format)")
        do {
            if format == "vc+sd-jwt" {
                let ret = selectDisclosure(
                    sdJwt: credential.payload, presentationDefinition: presentationDefinition)
                if let (_, disclosures) = ret {
                    return 0 < disclosures.count
                }
                return false
            }
            else if format == "jwt_vc_json" {
                let (_, payload, _) = try JWTUtil.decodeJwt(jwt: credential.payload)
                print("satisfyConstrains?")
                return satisfyConstrains(
                    credential: payload, presentationDefinition: presentationDefinition)
            }
            else {
                // その他のフォーマットに対する処理が必要な場合、ここに追加
                return false
            }
        }
        catch {
            // JWTのデコードに失敗した場合の処理
            print("JWT decoding failed for credential with format: \(format)")
            return false
        }
    }

    func deleteCredential(credential: Credential) {
        print("delete: \(credential.id), \(credential.format)")
        credentialDataManager.deleteCredentialById(id: credential.id)
        dataModel.hasLoadedData = false
        loadData()
    }
}
