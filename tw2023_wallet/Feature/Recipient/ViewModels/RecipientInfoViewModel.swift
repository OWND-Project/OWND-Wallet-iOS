//
//  RecipientInfoViewModel.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2024/02/02.
//

import Foundation

class RecipientInfoViewModel: ObservableObject {
    @Published var certificateInfo: CertificateInfo?
    @Published var hasLoadedData = false
    @Published var isLoading = false

    func loadCertificateInfo(for url: String) {
        guard !self.hasLoadedData else { return }
        self.isLoading = true

        DispatchQueue.global(qos: .userInitiated).async {
            if (url != "") {
                let (certificateInfo, _) = extractFirstCertSubject(url: url)
                DispatchQueue.main.async {
                    self.certificateInfo = certificateInfo
                }
            }
        }
        self.isLoading = false
        self.hasLoadedData = true
    }
}
