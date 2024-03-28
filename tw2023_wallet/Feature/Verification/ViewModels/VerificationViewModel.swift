//
//  VerificationViewModel.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2024/01/14.
//

import Foundation

class DecompressedVerificationArgs: Codable {
    let format: String?
    let credential: String?
    let display: String?
}

class VerificationViewModel {
    var dataModel: VerificationModel = .init()
    var displayMap: [String: [Display]]? = nil
    var format: String = ""
    var credential: String = ""

    func setDisplayMap(displayMapString: String) {
        displayMap = VCIMetadataUtil.deserializeDisplayByClaimMap(displayMapString: displayMapString)
    }
    
    func parseArgs(compressedCredential: String) {
        print("parseArgs")
        let decompressed = ZipUtil.decompressString(compressed: compressedCredential)
        if let jsonString = decompressed, let data = jsonString.data(using: .utf8) {
            do {
                print(jsonString)
                let decodedData = try JSONDecoder().decode(DecompressedVerificationArgs.self, from: data)
                if let format = decodedData.format,
                   let credential = decodedData.credential,
                   let display = decodedData.display {
                    self.format = format
                    self.credential = credential
                    self.displayMap = VCIMetadataUtil.deserializeDisplayByClaimMap(displayMapString: display)
                }
            } catch {
                print("JSONの解析に失敗しました: \(error)")
            }
        }
    }
    
    func verifyCredential() async {
        let verificationResult = JWTUtil.verifyJwtByX5U(jwt: credential)
        
        switch verificationResult {
        case .failure(let error):
            // TODO: Error handling
            print("error: \(error)")
            DispatchQueue.main.async {
                self.dataModel.result = false
                self.dataModel.isInitDone = true
            }
            
        case .success(let decodedJWT):
            if format == "jwt_vc_json" {
                if let vc = decodedJWT.body["vc"] as? [String: Any],
                   let credentialSubject = vc["credentialSubject"] as? [String: String] {
                    print("vc: \(vc)")
                    print("credentialSubject: \(credentialSubject)")
                    
                    DispatchQueue.main.async {
                        // self.dataModel.claims = credentialSubject.map { ($0.key, $0.value) }
                        self.dataModel.claims = self.transformCredentialSubjectIntoClaims(credentialSubject)
                        self.dataModel.result = true
                        self.dataModel.isInitDone = true
                    }
                }
            } else if format == "vc+sd-jwt" {
                // TODO: Implement
            } else {
                // TODO: Implement
            }
        }
    }
    
    func transformCredentialSubjectIntoClaims(_ credentialSubject: [String: String]) -> [(String, String)] {
        return credentialSubject.compactMap { key, value in
            if let displayList = self.displayMap?[key], !displayList.isEmpty {
                return (displayList[0].name ?? "Display Name is not set", value)
            }
            return nil
        }
    }
}
