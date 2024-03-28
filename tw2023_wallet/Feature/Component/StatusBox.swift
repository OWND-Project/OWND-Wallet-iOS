//
//  ConfirmationBox.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2024/01/12.
//

import SwiftUI

enum BoxStatus {
    case success
    case error
    case warning
}

struct StatusBox: View {
    @Binding var displayText: String
    var status: BoxStatus

    var body: some View {
        HStack {
            Image(systemName: self.statusImage)
                .resizable()
                .frame(width: 24, height: 24)
                .modifier(StatusBoxForeground(status: status))

            Text(LocalizedStringKey(self.displayText))
                .padding(.leading, 10)
                .modifier(StatusBoxForeground(status: status))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .modifier(StatusBoxBackground(status: status))
        .cornerRadius(10)
    }

    private var statusImage: String {
        switch status {
        case .success:
            return "checkmark.circle"
        case .error:
            return "exclamationmark.circle"
        case .warning:
            return "questionmark.circle"
        }
    }
}

#Preview {
    Group {
        StatusBox(displayText: .constant("valid_certificate"), status: .success)
        StatusBox(displayText: .constant("no_certificate_selected"), status: .warning)
        StatusBox(displayText: .constant("invalid_certificate"), status: .error)
    }
}
