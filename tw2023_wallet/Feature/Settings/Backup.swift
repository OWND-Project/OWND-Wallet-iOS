//
//  Backup.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2024/02/16.
//

import SwiftUI

struct Backup: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var isExporting = false
//    @State private var document = TextFileDocument(text: "")
    @State private var zipData = Data()
    @State private var defaultFileName = ""
    @State var showAlert = false
    @State var alertTitle = ""
    
    var viewModel = BackupViewModel()
    
    var body: some View {
        VStack {
            Text("backup_description")
                .modifier(BodyGray())
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
            ActionButtonBlack(title: "create_backup_file", action: {
                let now = Date()
                let formatter = DateFormatterFactory.gmtDateFormatter(withoutTime: true)
                defaultFileName = "owned_wallet_\(formatter.string(from: now))"
                if let backupData = viewModel.generateBackupData() {
                    zipData = backupData
                }
                isExporting = true
            })
            .padding(.horizontal, 16)
            HStack {
                if let date = viewModel.lastCreatedAt {
                    Text("last_backup_date").modifier(SubHeadLineGray())
                    Text(date).modifier(SubHeadLineGray())
                }
            }
        }
        .fileExporter(
            isPresented: $isExporting,
            document: ZipFileDocument(data: zipData),
            contentType: .zip,
            defaultFilename: defaultFileName,
            onCompletion: { result in
                switch result {
                case .success(let url):
                    print("ファイルが保存されました: \(url)")
                    viewModel.updateLastBackupDate()
                    showAlert = true
                    alertTitle = String(localized: "backup_done")
                case .failure(let error):
                    print("エクスポートエラー: \(error)")
                }
            }
        )
        .navigationTitle("backup")
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            print("onAppear@Backup")
            viewModel.loadData()
            Task {
                print("accessPairwiseAccountManager")
                let b = await viewModel.accessPairwiseAccountManager()
                if (!b) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

#Preview("1") {
    Backup()
}

#Preview("2") {
    Backup(viewModel: BackupPreviewModel())
}
