//
//  IssuerDetailPreiewModel.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2024/01/17.
//

import Foundation

class IssuerDetailPreviewModel: IssuerDetailViewModel {
    override func loadData(credential: Credential?) async {
        // mock data for preview
        isLoading = true
        print("load dummy data..")
        let issuer = CertificateInfo(
            domain: "ca.example.com",
            organization: "Sample CA Org",
            locality: "Shibuya City",
            state: "Tokyo",
            country: "JP",
            street: nil,
            email: nil,
            issuer: nil
        )
        certInfo = CertificateInfo(
            domain: "ownd-project.com",
            organization: "OWND Project",
            locality: "Shibuya City",
            state: "Tokyo",
            country: "JP",
            street: "1-1-1",
            email: nil,
            issuer: issuer
        )
        print("done")
        isLoading = false
    }
}

class IssuerDetailPreviewModel2: IssuerDetailViewModel {
    override func loadData(credential: Credential?) async {
        // mock data for preview
        isLoading = true
        print("load dummy data..")
        certInfo = CertificateInfo(
            domain: "ownd-project.com",
            organization: nil,
            locality: nil,
            state: nil,
            country: nil,
            street: nil,
            email: nil,
            issuer: nil
        )
        print("done")
        isLoading = false
    }
}

/*
class IssuerDetailPreviewModel3: IssuerDetailViewModel {
    override func loadData(credential: Credential?) async {
        // mock data for preview
        isLoading = true
        print("load dummy data..")
        await super.processCredentialData(url: url!)
        print("done")
        isLoading = false
    }
}
*/
