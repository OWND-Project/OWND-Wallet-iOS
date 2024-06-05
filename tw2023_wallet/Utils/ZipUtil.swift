//
//  ZipUtil.swift
//  tw2023_wallet
//
//  Created by katsuyoshi ozaki on 2023/12/26.
//

import Foundation
import Gzip
import Zip

class ZipUtil {
    static func compressString(input: String) -> String? {
        guard let inputData = input.data(using: .utf8) else { return nil }
        guard let compressedData = try? inputData.gzipped() else { return nil }
        return compressedData.base64EncodedString()
    }

    static func decompressString(compressed: String) -> String? {
        guard let decodedData = Data(base64Encoded: compressed) else { return nil }
        guard let decompressedData = try? decodedData.gunzipped() else { return nil }
        return String(data: decompressedData, encoding: .utf8)
    }

    static func createZip(with content: String) -> Data? {
        let fileManager = FileManager.default
        do {
            // 一時ディレクトリのパスを取得
            let tempDirectory = FileManager.default.temporaryDirectory
            let originalFilePath = tempDirectory.appendingPathComponent("backup.txt")

            // 文字列を一時ファイルに書き込む
            try content.write(to: originalFilePath, atomically: true, encoding: .utf8)

            // ZIPファイルのパスを設定
            let zipFilePath = tempDirectory.appendingPathComponent("backup.zip")

            // 一時ファイルをZIP圧縮
            try Zip.zipFiles(
                paths: [originalFilePath], zipFilePath: zipFilePath, password: nil, progress: nil)

            // ZIPファイルのデータを読み込む
            let zipData = try Data(contentsOf: zipFilePath)

            // 一時ファイルとZIPファイルを削除
            try fileManager.removeItem(at: originalFilePath)
            try fileManager.removeItem(at: zipFilePath)

            return zipData
        }
        catch {
            print("エラーが発生しました: \(error)")
            return nil
        }
    }

    static func unzipAndReadContent(from zipData: Data) throws -> String {
        let fileManager = FileManager.default
        // 一時ディレクトリを作成
        let tempDirectoryURL = fileManager.temporaryDirectory.appendingPathComponent(
            UUID().uuidString)

        // deferブロックを使用して、関数終了時に一時ディレクトリを削除
        defer {
            try? fileManager.removeItem(at: tempDirectoryURL)
        }

        // 一時ディレクトリを作成
        try fileManager.createDirectory(
            at: tempDirectoryURL, withIntermediateDirectories: true, attributes: nil)

        
        let tempFileName = "tempZipFile.zip"
        // 一時ZIPファイルのパスを生成
        let tempZipFilePath = tempDirectoryURL.appendingPathComponent(tempFileName)

        // ZIPデータを一時ファイルに書き込む
        try zipData.write(to: tempZipFilePath)

        // ZIPファイルを解凍
        try Zip.unzipFile(
            tempZipFilePath, destination: tempDirectoryURL, overwrite: true, password: nil)

        // 解凍したファイルの一覧を取得
        let unzippedFiles = try fileManager.contentsOfDirectory(
            at: tempDirectoryURL, includingPropertiesForKeys: nil, options: [])

        if let targetFileURL = unzippedFiles.first(where: { $0.lastPathComponent != tempFileName }){
            let content = try String(contentsOf: targetFileURL, encoding: .utf8)
            return content
        }
        else {
            throw NSError(
                domain: "UnzipError", code: 0,
                userInfo: [NSLocalizedDescriptionKey: "ZIPファイルに含まれるテキストファイルが一つではないか、見つかりません。"])
        }
    }
}
