//
//  SettingsSection.swift
//  CheloveCheck
//
//  Created by Sergey Ivanov on 04.02.2025.
//

import Foundation

enum SettingsSection: Int, CaseIterable, Hashable {
    case support, team, sourceCode

    var title: String {
        switch self {
        case .support:
            return "Поддержка"
        case .team:
            return "Команда"
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
                SettingsItem(title: "Sergey Ivanov (Swift разработчик)", url: URL(string: "https://github.com/texport"), iconName: "github"),
                SettingsItem(title: "Pavel Michka (QA-тестировщик)", url: URL(string: "https://github.com/Shep0rt"), iconName: "github")
            ]
        case .sourceCode:
            return [SettingsItem(title: "Исходный код на GitHub", url: URL(string: "https://github.com/texport/CheloveCheck"), iconName: "github")]
        }
    }
}
