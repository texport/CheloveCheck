//
//  SettingsSection.swift
//  CheloveCheck
//
//  Created by Sergey Ivanov on 04.02.2025.
//

import Foundation

enum SettingsSection: Int, CaseIterable, Hashable {
    case support, team, about, navigation, sourceCode

    var title: String {
        switch self {
        case .support:
            return "Поддержка"
        case .team:
            return "Команда"
        case .about:
            return "О Программе"
        case .navigation:
            return "Навигация"
        case .sourceCode:
            return "Исходный код"
        }
    }
    
    var items: [SettingsItem] {
        switch self {
        case .support:
            return [SettingsItem(title: "Чат поддержки в Telegram", url: URL(string: "https://t.me/chelovecheck_com"), iconName: "telegram")]
        case .team:
            return [
                SettingsItem(title: "Sergey Ivanov (Swift-разработчик)", url: URL(string: "https://github.com/texport"), iconName: "github"),
                SettingsItem(title: "Pavel Michka (QA-инженер)", url: URL(string: "https://github.com/Shep0rt"), iconName: "github")
            ]
        case .about:
            return [
                SettingsItem(title: "Версия приложения: 1.6.0", url: nil, iconName: "about")
            ]
        case .navigation:
            let raw = UserDefaults.standard.string(forKey: "selectedMapProvider")
            let provider = MapProvider(rawValue: raw ?? "") ?? .apple
            return [
                SettingsItem(title: "Провайдер карт: \(provider.rawValue)", url: nil, iconName: "map")
            ]
        case .sourceCode:
            return [SettingsItem(title: "Исходный код на GitHub", url: URL(string: "https://github.com/texport/CheloveCheck"), iconName: "github")]
        }
    }
}
