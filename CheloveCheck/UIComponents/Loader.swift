//
//  Loader.swift
//  CheloveCheck
//
//  Created by Sergey Ivanov on 05.01.2025.
//

import UIKit
import ProgressHUD

final class Loader {
    
    // MARK: - Настройка стиля (вызывается один раз при старте приложения)
    static func configure() {
        ProgressHUD.animationType = .circleStrokeSpin
        ProgressHUD.colorHUD = .white
        ProgressHUD.colorBackground = .loaderBackgound
        ProgressHUD.colorAnimation = .loaderHud
        ProgressHUD.fontStatus = .systemFont(ofSize: 16, weight: .medium) // Шрифт текста
    }
    
    // MARK: - Показ индикатора
    static func show() {
        ProgressHUD.animate()
    }
    
    // MARK: - Скрытие индикатора
    static func dismiss() {
        ProgressHUD.dismiss()
    }
}
