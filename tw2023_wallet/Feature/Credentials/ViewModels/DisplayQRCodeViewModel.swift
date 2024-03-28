//
//  DisplayQRCodeViewModel.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2024/01/17.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import SwiftUI

class DisplayQRCodeViewModel: ObservableObject {
    @Published var credential: Credential

    init(credential: Credential) {
        self.credential = credential
    }

    func decodeJwtHeader(_ jwt: String) -> String? {
        let parts = jwt.split(separator: ".").map(String.init)

        guard parts.count > 0 else { return nil }
        let headerPart = parts[0]

        guard let decodedData = decodeBase64URLSafeString(headerPart) else { return nil }
        return String(data: decodedData, encoding: .utf8)
    }

    private func decodeBase64URLSafeString(_ base64URLSafeString: String) -> Data? {
        var base64String = base64URLSafeString
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        // パディングを調整
        while base64String.count % 4 != 0 {
            base64String.append("=")
        }

        return Data(base64Encoded: base64String)
    }

    var jwtHeader: String? {
        decodeJwtHeader(credential.payload)
    }

    var hasX5u: Bool {
        if let header = jwtHeader,
           let data = header.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        {
            return json["x5u"] != nil
        }
        return false
    }

    func generateCompressedJwt(_ credential: Credential) -> String? {
//        guard let displayData = credential.qrDisplay.data(using: .utf8),
//              let displayDict = try? JSONSerialization.jsonObject(with: displayData) as? [String: Any]
//        else {
//            return nil
//        }
        let jsonDict = [
            "format": credential.format,
            "credential": credential.payload,
            "display": credential.qrDisplay
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonDict, options: []),
              let jsonString = String(data: jsonData, encoding: .utf8)
        else {
            return nil
        }

        return ZipUtil.compressString(input: jsonString)
    }

    var compressedJwt: String? {
        generateCompressedJwt(credential)
    }

    var qrCodeImage: Image? {
        if let compressedJwt = compressedJwt {
            return QRCodeGenerator.generate(from: compressedJwt)
        }
        return nil
    }
}
