//
//  Verification.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2024/01/12.
//

import SwiftUI

struct Verification: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(VerificationArgs.self) var args
    var viewModel: VerificationViewModel

    init(
        viewModel: VerificationViewModel = VerificationViewModel()
    ) {
        self.viewModel = viewModel
    }

    var body: some View {
        Group {
            ScrollView {
                if viewModel.dataModel.isLoading {
                    ProgressView().progressViewStyle(CircularProgressViewStyle())
                } else {
                    HStack {
                        Button("Close") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 8)
                        Spacer()
                    }
                    if viewModel.dataModel.result {
                        VStack(alignment: .leading) {
                            StatusBox(displayText: .constant("valid_certificate"), status: .success)
                            Text("verification_result_description").modifier(BodyBlack())
                            if !viewModel.dataModel.claims.isEmpty {
                                ForEach(viewModel.dataModel.claims, id: \.0) { key, value in
                                    DisclosureLow(disclosure: (key: key, value: value))
                                        .padding(.vertical, 8)
                                }
                            }
                        }
                    } else {
                        VStack(alignment: .leading) {
                            StatusBox(displayText: .constant("invalid_certificate"), status: .error)
                            Image("verification_fail")
                                .padding(.vertical, 16)
                            Text("verification_error_message").modifier(BodyBlack())
                                .padding(.vertical, 16)
                        }
                    }
                }
                Spacer()
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .onAppear {
            Task {
                if let encryptedString = args.compressedString
                {
                    viewModel.parseArgs(compressedCredential: encryptedString)
                    await viewModel.verifyCredential()
                }
            }
        }
    }
}

#Preview("Success") {
    let args = VerificationArgs()
    args.compressedString = VerificationPreviewModel.dummyArgs()

    return Verification(
        viewModel: VerificationPreviewModel()
    )
    .environment(args)
}

#Preview("Error") {
    let args = VerificationArgs()
    args.compressedString = ""
    return Verification(
        viewModel: VerificationErrorPreviewModel()
    )
    .environment(VerificationArgs())
}
