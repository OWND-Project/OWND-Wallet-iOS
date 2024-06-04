//
//  Styles.swift
//  tw2023_wallet
//
//  Created by SadamuMatsuoka on 2023/12/28.
//

import Foundation
import SwiftUI

func colorFromHex(_ hex: String) -> Color {
    var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

    var rgb: UInt64 = 0

    Scanner(string: hexSanitized).scanHexInt64(&rgb)

    let red = Double((rgb & 0xFF0000) >> 16) / 255.0
    let green = Double((rgb & 0x00FF00) >> 8) / 255.0
    let blue = Double(rgb & 0x0000FF) / 255.0

    return Color(red: red, green: green, blue: blue)
}

struct LargeTitleBlack: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.largeTitle)
            .foregroundColor(Color("textColorPrimary"))
            .lineSpacing(4)
    }
}

// <style name="text_text">
struct LargeTitleGray: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.largeTitle)
            .foregroundColor(Color("textColorSecondary"))
            .lineSpacing(4)
    }
}

struct TitleBlack: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.title)
            .foregroundColor(Color("textColorPrimary"))
            .lineSpacing(4)
    }
}

struct TitleGray: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.title)
            .foregroundColor(Color("textColorSecondary"))
            .lineSpacing(4)
    }
}

struct Title2Black: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.title2)
            .foregroundColor(Color("textColorPrimary"))
            .lineSpacing(4)
    }
}

struct Title2Gray: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.title2)
            .foregroundColor(Color("textColorSecondary"))
            .lineSpacing(4)
    }
}

struct Title3Black: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.title3)
            .foregroundColor(Color("textColorPrimary"))
            .lineSpacing(4)
    }
}

struct Title3Gray: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.title3)
            .foregroundColor(Color("textColorSecondary"))
            .lineSpacing(4)
    }
}

// <style name="text_label_m">16sp#1A1A1C
struct BodyBlack: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.body)
            .foregroundColor(Color("textColorPrimary"))
            .lineSpacing(4)
    }
}

// <style name="text_text">16sp#626264
struct BodyGray: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.body)
            .foregroundColor(Color("textColorSecondary"))
            .lineSpacing(4)
    }
}

struct BodyWhite: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.body)
            .foregroundColor(Color("filledButtonTextColor"))
            .lineSpacing(4)
    }
}

struct SubHeadLineBlack: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline)
            .foregroundColor(Color("textColorPrimary"))
            .lineSpacing(4)
    }
}

// <style name="text_sub_text">
struct SubHeadLineGray: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline)
            .foregroundColor(Color("textColorSecondary"))
            .lineSpacing(4)
    }
}

struct StatusSuccess: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundColor(Color("status_success"))
    }
}

struct StatusWarning: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundColor(Color("status_warning"))
    }
}

struct StatusError: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundColor(Color("status_error"))
    }
}

struct InfoBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color("infoBackground"))
    }
}

struct WarnBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color("warnBackground"))
    }
}

struct ErrorBackground: ViewModifier {
    let color: Color = colorFromHex("#FFE7E6")
    func body(content: Content) -> some View {
        content
            .background(Color("errorBackground"))
    }
}

struct StatusBoxForeground: ViewModifier {
    let status: BoxStatus

    func body(content: Content) -> some View {
        content
            .foregroundColor(foregroundColor)
    }

    private var foregroundColor: Color {
        switch status {
            case .success:
                return Color("status_success")
            case .warning:
                return Color("status_warning")
            case .error:
                return Color("status_error")
        }
    }
}

struct StatusBoxBackground: ViewModifier {
    let status: BoxStatus

    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
    }

    private var backgroundColor: Color {
        switch status {
            case .success:
                return Color("infoBackground")
            case .warning:
                return Color("warnBackground")
            case .error:
                return Color("errorBackground")
        }
    }
}
