//
//  VerificationModel.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2024/01/14.
//

import Foundation

@Observable
class VerificationModel {
    var isLoading = false
    var hasLoadedData = false
    var claims: [(String, String)] = []
    var isInitDone: Bool = false
    var result: Bool = false
}
