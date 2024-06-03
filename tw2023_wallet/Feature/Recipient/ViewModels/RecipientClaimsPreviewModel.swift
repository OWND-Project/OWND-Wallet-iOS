//
//  RecipientClaimsPreviewModel.swift
//  tw2023_wallet
//
//  Created by katsuyoshi ozaki on 2024/02/19.
//

import Foundation

class RecipientClaimsPreviewModel: RecipientClaimsViewModel {
    override func loadClaimsInfo(sharingHistory: History) {
        guard !self.hasLoadedData else { return }
        self.isLoading = true
        print("RecipientClaimsPreviewModel load dummy data..")

        // Todo: Set appropriate values using sharingHistory.claims and sharingHistory.credentialID
        let tmp = [
            ("デジタル 花子", "〇〇のために氏名を提供しました"),
            ("13歳以上であること", "〇〇のために年齢確認情報を提供しました"),
        ]

        let claimsInfo = [
            ClaimInfo(claimKey: "name", claimValue: tmp[0].0, purpose: tmp[0].1),
            ClaimInfo(claimKey: "is_older_than_13", claimValue: tmp[1].0, purpose: tmp[1].1),
        ]
        let rpName = "株式会社Example"
        let title = "2023/07/18 14:05の情報提供"

        DispatchQueue.main.async {
            self.title = title
            self.rpName = rpName
            self.claimsInfo = claimsInfo
            self.isLoading = false
            self.hasLoadedData = true
            print("RecipientPreviewModel done")
        }
    }
}
