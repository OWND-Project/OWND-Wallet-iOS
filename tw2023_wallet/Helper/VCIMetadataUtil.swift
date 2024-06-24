//
//  VCIMetadataUtil.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2023/12/27.
//

import Foundation

struct SDJwtParts {
    let issuerSignedJwt: String
    let disclosures: [String]
    let keyBindingJwt: String?
}

class VCIMetadataUtil {
    static func divideSDJwt(sdJwt: String) -> SDJwtParts {
        let parts = sdJwt.split(separator: "~").map(String.init)
        guard !parts.isEmpty else {
            fatalError("Invalid SD-JWT: No parts found")
        }

        let issuerSignedJwt = parts.first!
        let disclosures = Array(parts[1..<parts.count - 1])
        let keyBindingJwt = parts.last!.isEmpty ? nil : parts.last

        return SDJwtParts(
            issuerSignedJwt: issuerSignedJwt, disclosures: disclosures, keyBindingJwt: keyBindingJwt
        )
    }

    static func extractTypes(format: String, credential: String) throws -> [String] {
        var types: [String] = []

        switch format {
            case "vc+sd-jwt":
                let jwt = divideSDJwt(sdJwt: credential).issuerSignedJwt
                let decoded = try decodeJWTPayload(jwt: jwt)
                let vct = decoded["vct"] as! String
                types = [vct]
            case "jwt_vc_json":
                let decoded = try decodeJWTPayload(jwt: credential)
                print(decoded)
                let vc = decoded["vc"] as! [String: Any]
                let typeList = vc["type"] as! [String]
                types = typeList
            default:
                print("Unsupported Credential Format: \(format)")
        }

        return types
    }

    static func findMatchingCredentials(
        format: String,
        types: [String],
        metadata: CredentialIssuerMetadata
    ) -> CredentialConfiguration? {
        return metadata.credentialConfigurationsSupported.first {
            (_, credentialSupported) -> Bool in
            switch credentialSupported {
                case let credentialSupported as CredentialSupportedVcSdJwt:
                    // VcSdJwtの場合、vctとtypesの最初の要素を比較
                    return format == "vc+sd-jwt"
                        && types.first == credentialSupported.vct

                case let credentialSupported as CredentialSupportedJwtVcJson:
                    // JwtVcJsonの場合、typesとcredentialDefinition.typeを両方ソートして比較
                    return format == "jwt_vc_json"
                        && containsAllElements(credentialSupported.credentialDefinition.type, types)

                default:
                    return false
            }
        }?.value
    }

    static func containsAllElements<T: Hashable>(_ array1: [T], _ array2: [T]) -> Bool {
        let set1 = Set(array1)
        let set2 = Set(array2)
        return set1.isSuperset(of: set2)
    }

    static func extractDisplayByClaim(credentialsSupported: CredentialConfiguration) -> [String:
        [ClaimDisplay]]
    {
        var displayMap = [String: [ClaimDisplay]]()

        switch credentialsSupported {
            case let credentialsSupported as CredentialSupportedJwtVcJson:
                if let credentialSubject = credentialsSupported.credentialDefinition
                    .credentialSubject
                {
                    for (k, v) in credentialSubject {
                        if let display = v.display {
                            displayMap[k] = display
                        }
                    }
                }

            case let credentialsSupported as CredentialSupportedVcSdJwt:
                if let credentialSubject = credentialsSupported.claims {
                    for (k, v) in credentialSubject {
                        if let display = v.display {
                            displayMap[k] = display
                        }
                    }
                }

            default:
                print("not implemented yet")
        }

        return displayMap
    }

    static func serializeDisplayByClaimMap(displayMap: [String: [ClaimDisplay]]) -> String {
        let encoder = JSONEncoder()
        do {
            let jsonData = try encoder.encode(displayMap)
            return String(data: jsonData, encoding: .utf8) ?? ""
        }
        catch {
            print("Error serializing display map: \(error)")
            return ""
        }
    }

    static func deserializeDisplayByClaimMap(displayMapString: String) -> [String: [ClaimDisplay]] {
        let decoder = JSONDecoder()
        do {
            let data = Data(displayMapString.utf8)
            return try decoder.decode([String: [ClaimDisplay]].self, from: data)
        }
        catch {
            print("Error deserializing display map: \(error)")
            return [:]
        }
    }
}
