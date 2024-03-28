//
//  SharingTo.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2023/12/21.
//

import SwiftUI

struct SharingTo: View {
    
    var viewModel: SharingToViewModel
    
    init(viewModel: SharingToViewModel = SharingToViewModel()) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        NavigationStack {
            if (viewModel.dataModel.isLoading){
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }else{
                Group {
                List(viewModel.dataModel.sharingHistories, id: \.self) { history in
                    SharingToRow(sharingHistory: history).listRowSeparator(.hidden)
                }
                .scrollContentBackground(.hidden)
                 .background(Color.clear)
            }
            }
        }
    }
}

#Preview {
    SharingTo()
}
