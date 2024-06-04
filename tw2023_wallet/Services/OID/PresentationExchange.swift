//
//  PresentationExchange.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2023/12/30.
//

import Foundation

enum LimitDisclosure: String, Codable {
    case required = "required"
    case preferred = "preferred"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)

        guard let limitDisclosure = LimitDisclosure(rawValue: value) else {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Invalid limitDisclosure type value: \(value)")
        }

        self = limitDisclosure
    }
}

enum Rule: String, Codable {
    case pick = "pick"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)

        guard let rule = Rule(rawValue: value) else {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Invalid rule type value: \(value)")
        }

        self = rule
    }
}

struct PresentationDefinition: Codable {
    let id: String
    let inputDescriptors: [InputDescriptor]
    let submissionRequirements: [SubmissionRequirement]?
}

struct ClaimFormat: Codable {
    let alg: [String]?
    let proof_type: [String]?
}

struct InputDescriptor: Codable {
    let id: String
    let name: String?
    let purpose: String?
    let format: [String: ClaimFormat]?
    let group: [String]?
    let constraints: InputDescriptorConstraints
}

struct InputDescriptorConstraints: Codable {
    let limitDisclosure: LimitDisclosure?
    let fields: [Field]?
}

struct JSONSchemaProperties: Codable {
    let type: [String: String]?
}

struct Filter: Codable {
    let type: String?
    let required: [String]?
    let properties: JSONSchemaProperties?
}

struct Field: Codable {
    let path: [String]
    let filter: Filter?
}

struct SubmissionRequirement: Codable {
    let name: String?
    let rule: Rule
    let count: Int?
    let from: String
}

struct Path: Codable {
    let format: String
    let path: String
}

// https://identity.foundation/presentation-exchange/spec/v2.0.0/#presentation-submission
struct DescriptorMap: Codable {
    let id: String
    let format: String
    let path: String
    let pathNested: Path?
}

struct PresentationSubmission: Codable {
    let id: String
    let definitionId: String
    let descriptorMap: [DescriptorMap]
}
