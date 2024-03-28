//
//  Types.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2024/01/13.
//

import Foundation

typealias KeyPair = (publicKey: SecKey, privateKey: SecKey)
typealias KeyPairData = (publicKey: (Data, Data), privateKey: Data)
