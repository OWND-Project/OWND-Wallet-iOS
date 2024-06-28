//
//  UrlEncoder.swift
//  tw2023_wallet
//
//  Created by katsuyoshi ozaki on 2024/06/20.
//

import Foundation

// Helper encoder for application/x-www-form-urlencoded encoding
struct URLEncodedFormEncoder {
    var keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy = .useDefaultKeys

    func encode<T: Encodable>(_ value: T) throws -> Data {
        let encoder = URLEncoder(keyEncodingStrategy: keyEncodingStrategy)
        return try encoder.encode(value)
    }
}

struct URLEncoder {
    var keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy

    func encode<T: Encodable>(_ value: T) throws -> Data {
        let dictionary = try DictionaryEncoder(keyEncodingStrategy: keyEncodingStrategy).encode(
            value)
        let queryString = dictionary.map { "\($0)=\($1)" }.joined(separator: "&")
        return queryString.data(using: .utf8) ?? Data()
    }
}

struct DictionaryEncoder {
    private let encoder: JSONEncoder

    init(keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy) {
        self.encoder = JSONEncoder()
        self.encoder.keyEncodingStrategy = keyEncodingStrategy
    }

    func encode<T>(_ value: T) throws -> [String: String] where T: Encodable {
        let data = try encoder.encode(value)
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: .allowFragments)

        guard let dictionary = jsonObject as? [String: Any] else {
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: [], debugDescription: "Failed to encode object to dictionary"))
        }

        var stringDict = [String: String]()
        for (key, value) in dictionary {
            if let stringValue = value as? String {
                stringDict[key] = stringValue
            }
            else if let intValue = value as? Int {
                stringDict[key] = String(intValue)
            }
            else if let boolValue = value as? Bool {
                stringDict[key] = String(boolValue)
            }
            else {
                throw EncodingError.invalidValue(
                    value,
                    EncodingError.Context(
                        codingPath: [], debugDescription: "Unsupported value type"))
            }
        }

        return stringDict
    }
}
