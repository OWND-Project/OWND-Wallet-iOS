//
//  VerificationPreviewModel.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2024/01/14.
//

import Foundation

class VerificationPreviewModel: VerificationViewModel {
    override func verifyCredential() async {
        self.dataModel.result = true
        self.dataModel.isInitDone = true
        
        let claims: [(String, String)] = [
            ("event_name", "Privacy by Design Conference 2024"),
            ("date_of_event", "2024年1月24日"),
            ("participation", "True"),
            ("issuer", "Privacy by Design Lab")
        ]
        let claimsMap = Dictionary(uniqueKeysWithValues: claims)
        self.dataModel.claims = self.transformCredentialSubjectIntoClaims(claimsMap)
    }
    
//    static func displayMapData() -> String {
//        let jsonString1 = """
//    { "name": "イベント名", "locale": "ja_JP" }
//    """
//        let jsonString2 = """
//    { "name": "イベント日付", "locale": "ja_JP" }
//    """
//        let jsonString3 = """
//    { "name": "参加", "locale": "ja_JP" }
//    """
//        let jsonString4 = """
//    { "name": "発行者", "locale": "ja_JP" }
//    """
//        let display1 = decodeDisplay(value: jsonString1)
//        let display2 = decodeDisplay(value: jsonString2)
//        let display3 = decodeDisplay(value: jsonString3)
//        let display4 = decodeDisplay(value: jsonString4)
//        let displayMap = [
//            "event_name": [display1],
//            "date_of_event": [display2],
//            "participation": [display3],
//            "issuer": [display4],
//        ]
//        return VCIMetadataUtil.serializeDisplayByClaimMap(displayMap: displayMap)
//    }
    
    static func dummyArgs() -> String? {
        // let display = displayMapData()
        let payload = """
        {
            "format": "jwt_vc_json",
            "credential": "dummy",
            "display": "{\\"event_name\\" :[{\\"name\\": \\"イベント名\\", \\"locale\\": \\"ja_JP\\"}], \\"date_of_event\\" :[{\\"name\\": \\"イベント日付\\", \\"locale\\": \\"ja_JP\\"}], \\"participation\\" :[{\\"name\\": \\"参加\\", \\"locale\\": \\"ja_JP\\"}], \\"issuer\\" :[{\\"name\\": \\"発行者\\", \\"locale\\": \\"ja_JP\\"}]}"
        }
        """
        return ZipUtil.compressString(input: payload)
    }
}


func decodeDisplay(value: String) -> Display {
    let decoder = JSONDecoder()
    let jsonData = value.data(using: .utf8)!
    return try! decoder.decode(Display.self, from: jsonData)
}

class VerificationErrorPreviewModel: VerificationViewModel {
    
    override func verifyCredential() async {
        print("verifyCredential")
        self.dataModel.result = false
        self.dataModel.isInitDone = true
    }
}
