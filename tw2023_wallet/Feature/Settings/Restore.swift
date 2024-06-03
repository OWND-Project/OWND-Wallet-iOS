//
//  Restore.swift
//  tw2023_wallet
//
//  Created by 若葉良介 on 2024/02/16.
//

import SwiftUI

struct Restore: View {
    @State private var navigateToCredentialList = false  // 追加
    @State private var isImporterPresented = false
    @State var showAlert = false
    @State var alertTitle = ""
    @State var success = false
    //    @State private var importedDocumentUrl: String?
    @State private var importedContents: String?

    var viewModel = RestoreViewModel()
    var body: some View {
        VStack {
            Text("read_backup_file")
                .modifier(Title2Black())
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
            if let url = viewModel.importedDocumentUrl {
                // ファイル選択状態
                Image(systemName: "doc")
                    .modifier(TitleGray())
                Text(url.lastPathComponent)
                    .modifier(BodyGray())
                    .padding(.bottom, 16)
                // リストア実行ボタン
                ActionButtonBlack(
                    title: "load_backup_file",
                    action: {
                        print("restore")
                        let result = viewModel.selectFile()
                        switch result {
                            case .success:
                                success = true
                                showAlert = true
                                alertTitle = String(localized: "restored data")
                            case .failure(let error):
                                switch error {
                                    case RestoreError.invalidBackupFile:
                                        showAlert = true
                                        alertTitle = String(localized: "select_invalid_backup_file")
                                    default:
                                        showAlert = true
                                        alertTitle = String(localized: "unable_to_process_request")
                                        print(error)
                                }
                        }
                    }
                )
                .padding(.horizontal, 16)
                Text("change_credential")
                    .modifier(BodyBlack())
                    .underline()
                    .padding(.vertical, 8)
                    .onTapGesture {
                        print("change file")
                        viewModel.importedDocumentUrl = nil
                        importedContents = nil
                    }
            }
            else {
                // ファイル未選択
                StatusBox(displayText: .constant("no_file_selected"), status: .warning)
                    .padding(.horizontal, 16)
                // ファイル選択ボタン
                ActionButtonBlack(
                    title: "select_backup_file",
                    action: {
                        print("select file")
                        isImporterPresented = true
                    }
                )
                .padding(.horizontal, 16)

                VStack {
                    Text("notation_of_filename1").modifier(SubHeadLineGray())
                    HStack {
                        Text("notation_of_filename2").modifier(SubHeadLineGray())
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
            }
        }
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [.zip],
            allowsMultipleSelection: false
        ) { result in
            switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    viewModel.importedDocumentUrl = url
                case .failure(let error):
                    showAlert = true
                    alertTitle = "Import Error"
                    print("インポートエラー: \(error)")
            }
        }
        .navigationTitle("restore_from_backup_file")
        .navigationDestination(isPresented: $navigateToCredentialList) {
            Home()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                dismissButton: .default(Text("OK")) {
                    if success {
                        self.navigateToCredentialList = true
                    }
                }
            )
        }
        .onAppear {
            print("onAppear@Backup")
        }
    }
}

#Preview("1") {
    Restore()
}

#Preview("2") {
    let viewModel = RestorePreviewModel1()
    viewModel.importedDocumentUrl = URL(string: "/path/to/dummy.zip")
    return Restore(viewModel: viewModel)
}
