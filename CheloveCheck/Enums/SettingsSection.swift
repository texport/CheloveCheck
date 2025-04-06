//
//  SettingsSection.swift
//  CheloveCheck
//
//  Created by Sergey Ivanov on 04.02.2025.
//

import Foundation

enum SettingsSection: Int, CaseIterable, Hashable {
    case support, team, about, navigation, theme, exportimport, sourceCode

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
        case .theme:
            return "Тема оформления"
        case .exportimport:
            return "Управление хранилищем"
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
                SettingsItem(title: "Pavel Michka (QA-инженер)", url: URL(string: "https://github.com/Shep0rt"), iconName: "github"),
                SettingsItem(title: "Gomar Melsov (UI/UX-дизайнер)", url: URL(string: "https://t.me/g_melsov"), iconName: "telegram")
            ]
        case .about:
            return [
                SettingsItem(title: "Версия приложения: 1.6.0_rc1", url: nil, iconName: "info.circle")
            ]
        case .navigation:
            let raw = UserDefaults.standard.string(forKey: "selectedMapProvider")
            let provider = MapProvider(rawValue: raw ?? "") ?? .apple
            return [
                SettingsItem(title: "Провайдер карт: \(provider.rawValue)", url: nil, iconName: "maps")
            ]
        case .theme:
            let selectedTheme = ThemeManager.current
            return [
                SettingsItem(title: selectedTheme.rawValue, url: nil, iconName: "theme")
            ]
        case .exportimport:
            return [
                SettingsItem(title: "Выгрузить чеки в файл", url: nil, iconName: "square.and.arrow.up"),
                SettingsItem(title: "Загрузить чеки из файла", url: nil, iconName: "square.and.arrow.down"),
                SettingsItem(title: "Удалить все чеки из базы", url: nil, iconName: "trash")
            ]
        case .sourceCode:
            return [SettingsItem(title: "Исходный код на GitHub", url: URL(string: "https://github.com/texport/CheloveCheck"), iconName: "github")]
        }
    }
}
