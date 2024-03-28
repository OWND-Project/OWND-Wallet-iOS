//
//  SerializeUtil.swift
//  tw2023_wallet
//
//  Created by katsuyoshi ozaki on 2023/12/26.
//

import Foundation

class EnumDeserializer<T: RawRepresentable>: JSONDecoder {
    typealias EnumType = T

    init(enumType: EnumType.Type) {
        self.enumType = enumType
        super.init()
    }

    private let enumType: EnumType.Type

    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }

    func deserialize(rawValue: String) -> EnumType? {
        return enumType.init(rawValue: rawValue as! T.RawValue)
    }
}
