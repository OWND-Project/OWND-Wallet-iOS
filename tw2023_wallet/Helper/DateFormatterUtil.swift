//
//  DateFormatterUtil.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2024/01/30.
//

import Foundation
import SwiftProtobuf

enum DateFormatterUtil {
    static func formatDate(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        inputFormatter.locale = Locale(identifier: "en_US_POSIX")

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "yyyy/MM/dd H:mm"

        if let date = inputFormatter.date(from: dateString) {
            return outputFormatter.string(from: date)
        } else {
            return dateString // 変換に失敗した場合、元の文字列を返す
        }
    }
}

class DateFormatterFactory {
    static func gmtDateFormatter(withoutTime: Bool = false) -> DateFormatter {
        let formatter = DateFormatter()
        if (withoutTime) {
            formatter.dateFormat = "yyyy-MM-dd"
        } else {
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        }
        formatter.timeZone = TimeZone(abbreviation: "GMT")
        return formatter
    }
    
    static func localDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        formatter.locale = Locale.current
        return formatter
    }
}

extension Google_Protobuf_Timestamp {
    /// `Google_Protobuf_Timestamp`を`Date`に変換します。
    func toDate() -> Date {
        return Date(timeIntervalSince1970: TimeInterval(self.seconds) + TimeInterval(self.nanos) / 1_000_000_000)
    }
}

extension Date {
    /// `Date`をISO 8601形式の文字列に変換します。
    func toISO8601String() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(abbreviation: "GMT")
        return formatter.string(from: self)
    }
    
    func toGoogleTimestamp() -> Google_Protobuf_Timestamp {
        var timestamp = Google_Protobuf_Timestamp()
        timestamp.seconds = Int64(timeIntervalSince1970)
        timestamp.nanos = Int32((timeIntervalSince1970 * 1_000_000_000).truncatingRemainder(dividingBy: 1_000_000_000))
        return timestamp
    }
}

extension String {
    /// ISO 8601形式の文字列を`Date`に変換します。
    func toDateFromISO8601() -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(abbreviation: "GMT")
        return formatter.date(from: self)
    }
}
