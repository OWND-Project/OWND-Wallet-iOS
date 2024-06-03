//
//  SharingHistory.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2023/12/27.
//

import Foundation
import SwiftUI

protocol History {
    var rp: String { get }
    var createdAt: String { get }
}

struct Histories {
    var histories: [History]

    func groupByRp() -> [String: [History]] {
        let grouped = Dictionary(grouping: self.histories, by: { $0.rp })
        return grouped.mapValues { value in
            return Histories.sortHistoriesByDate(histories: value)
        }
    }
    func latestByRp() -> [History] {
        let grouped = self.groupByRp()
        return grouped.compactMap { group -> History? in
            group.value.first
        }
    }
    static func sortHistoriesByDate(histories: [History]) -> [History] {
        return histories.sorted { lhs, rhs in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            let lhsDate = dateFormatter.date(from: lhs.createdAt) ?? Date.distantPast
            let rhsDate = dateFormatter.date(from: rhs.createdAt) ?? Date.distantPast
            return lhsDate > rhsDate
        }
    }

}

struct ClaimInfo: Codable {
    var claimKey: String
    var claimValue: String
    var purpose: String?

    enum CodingKeys: String, CodingKey {
        case claimKey
        case claimValue
        case purpose
    }

    static func == (lhs: ClaimInfo, rhs: ClaimInfo) -> Bool {
        // ここで比較ロジックを実装する
        return lhs.claimKey == rhs.claimKey && lhs.claimValue == rhs.claimValue
            && lhs.purpose == rhs.purpose
    }
}

struct CredentialSharingHistory: Codable, Hashable, History {
    let rp: String
    let accountIndex: Int
    let createdAt: String
    let credentialID: String
    var claims: [ClaimInfo]
    var rpName: String
    var privacyPolicyUrl: String
    var logoUrl: String

    static func == (lhs: CredentialSharingHistory, rhs: CredentialSharingHistory) -> Bool {
        for (lhsClaim, rhsClaim) in zip(lhs.claims, rhs.claims) {
            if !(lhsClaim == rhsClaim) {
                return false
            }
        }
        return lhs.rp == rhs.rp && lhs.accountIndex == rhs.accountIndex
            && lhs.createdAt == rhs.createdAt && lhs.credentialID == rhs.credentialID
            && lhs.rpName == rhs.rpName && lhs.privacyPolicyUrl == rhs.privacyPolicyUrl
            && lhs.logoUrl == rhs.logoUrl
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(rp)
        hasher.combine(accountIndex)
        hasher.combine(createdAt)
        hasher.combine(credentialID)

        for claim in claims {
            hasher.combine(claim.claimKey)
            hasher.combine(claim.claimValue)
            hasher.combine(claim.purpose)
        }

        hasher.combine(rpName)
        hasher.combine(privacyPolicyUrl)
        hasher.combine(logoUrl)
    }

    var logoImage: AnyView? {
        return ImageLoader.loadImage(from: logoUrl)
    }
}
