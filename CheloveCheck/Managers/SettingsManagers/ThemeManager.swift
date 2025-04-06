//
//  ThemeManager.swift
//  CheloveCheck
//
//  Created by Sergey Ivanov on 05.04.2025.
//

import UIKit

final class ThemeManager {
    private static let themeKey = "selectedTheme"

    enum AppTheme: String, CaseIterable {
        case defaultTheme = "Системная"
        case lightTheme = "Светлая"
        case darkTheme = "Темная"

        var interfaceStyle: UIUserInterfaceStyle {
            switch self {
            case .defaultTheme: return .unspecified
            case .lightTheme: return .light
            case .darkTheme: return .dark
            }
        }
    }
    
    static var current: AppTheme {
        let raw = UserDefaults.standard.string(forKey: themeKey)
        return AppTheme(rawValue: raw ?? "") ?? .defaultTheme
    }

    static func applyTheme(_ theme: AppTheme) {
        UserDefaults.standard.setValue(theme.rawValue, forKey: themeKey)
        apply(theme)
    }
    
    static func applyCurrentTheme() {
        apply(current)
    }
    
    private static func apply(_ theme: AppTheme) {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first else { return }

        window.overrideUserInterfaceStyle = theme.interfaceStyle
    }
}
