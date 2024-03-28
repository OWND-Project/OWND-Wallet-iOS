//
//  CredentialDetailViewModel.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2023/12/27.
//

import Foundation

@Observable
class CredentialDetailViewModel {
    var claimsToDisclose: [Disclosure] = []
    var claimsNotToDisclosed: [Disclosure] = []
    var dataModel: CredentialDetailModel = .init()
    var inputDescriptor: InputDescriptor? = nil

    func loadData(credential: Credential) async {
        await loadData(credential: credential, presentationDefinition: nil)
    }
    
    func loadData(credential: Credential, presentationDefinition: PresentationDefinition? = nil) async {
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else {
            print("now previewing")
            return
        }
        guard !dataModel.hasLoadedData else { return }
        dataModel.isLoading = true
        print("load data..")
        dataModel.isLoading = false
        if let pd = presentationDefinition {
            switch credential.format {
            case "vc+sd-jwt":
                if let selected = selectDisclosure(sdJwt: credential.payload, presentationDefinition: pd) {
                    let (inputDescriptors, _disclosures) = selected
                    self.inputDescriptor = inputDescriptors
                    self.claimsToDisclose = _disclosures
                    
                    let allDisclosures = try! SDJwtUtil.decodeSDJwt(credential.payload)
                    self.claimsNotToDisclosed = allDisclosures.filter { disclosure in
                        !claimsToDisclose.contains { selected in
                            selected.disclosure == disclosure.disclosure
                        }
                    }
                }
            case "jwt_vc_json":
                inputDescriptor = pd.inputDescriptors[0] // 選択開示できないので先頭固定
                self.claimsNotToDisclosed = []
                
                let jwt = credential.payload
                self.claimsToDisclose = JWTUtil.convertJWTClaimsAsDisclosure(jwt: jwt)
            default:
                inputDescriptor = pd.inputDescriptors[0] // 選択開示できないので先頭固定
            }
        }
        dataModel.hasLoadedData = true
        print("done")
    }
    
    func getSubmissionCredential(credential: Credential) -> SubmissionCredential {
        let types = try! VCIMetadataUtil.extractTypes(format: credential.format, credential: credential.payload)
        let submissionCredential = SubmissionCredential(
            id: credential.id,
            format: credential.format,
            types: types,
            credential: credential.payload,
            inputDescriptor: self.inputDescriptor!
        )
        return submissionCredential
    }
}
