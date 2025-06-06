//
//  Loader.swift
//  CheloveCheck
//
//  Created by Sergey Ivanov on 05.01.2025.
//

import UIKit
import ProgressHUD

final class Loader {
    private static var blockerView: UIControl?
    
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
        blockUI()
        ProgressHUD.animate()
    }
    
    static func showProgress(message: String, progress: Float) {
        blockUI()
        ProgressHUD.progress(message, CGFloat(progress))
    }
    
    // MARK: - Скрытие индикатора
    static func dismiss() {
        ProgressHUD.dismiss()
        unblockUI()
    }
    
    private static func blockUI() {
        guard blockerView == nil,
              let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow }) else { return }

        let blocker = UIControl(frame: window.bounds)
        blocker.backgroundColor = UIColor.clear
        blocker.isUserInteractionEnabled = true
        blocker.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        window.addSubview(blocker)
        blockerView = blocker
    }

    private static func unblockUI() {
        blockerView?.removeFromSuperview()
        blockerView = nil
    }
}
