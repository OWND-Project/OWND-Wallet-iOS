//
//  CredentialListArgs.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2024/01/26.
//

import Foundation

@Observable
class CredentialSharingModel {
    var presentationDefinition: PresentationDefinition? = nil
    init(presentationDefinition: PresentationDefinition? = nil) {
        self.presentationDefinition = presentationDefinition
    }

    var type: String? = nil
    var data: SubmissionCredential? = nil
    var metadata: CredentialIssuerMetadata? = nil
    func setSelectedCredential(data: SubmissionCredential, metadata: CredentialIssuerMetadata) {
        self.data = data
        self.metadata = metadata
    }
}
