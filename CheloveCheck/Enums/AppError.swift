//
//  AppError.swift
//  CheloveCheck
//
//  Created by Sergey Ivanov on 04.02.2025.
//

enum AppError: Error {
    case unknown(Error)
    case invalidQRCode
    case unsupportedDomain
    case failedToSaveReceipt(Error)
    case failedToDeleteReceipt(Error)
    case networkError(Error)
    case failedToCloseScreen
    case locationNotFound
    case databaseError(Error)
    case searchError(Error)
    case placeNotFound(String)
    
    // Ошибки для работы с камерой
    case cameraAccessDenied
    case cameraUnavailable
    case cameraPermissionNotDetermined
    case cameraSessionFailed(Error)
    case flashlightError(Error)
    
    var message: String {
        switch self {
        case .unknown(let error):
            return "Неизвестная ошибка: \(error.localizedDescription)"
        case .invalidQRCode:
            return "Неверный QR-код"
        case .unsupportedDomain:
            return "Чеки от этого ОФД пока не поддержкиваются"
        case .failedToSaveReceipt(let error):
            return "Ошибка сохранения чека: \(error.localizedDescription)"
        case .networkError(let error):
            return "Ошибка сети: \(error.localizedDescription)"
        case .cameraAccessDenied:
            return "Доступ к камере запрещен. Разрешите доступ в настройках"
        case .cameraUnavailable:
            return "Камера недоступна на этом устройстве"
        case .cameraPermissionNotDetermined:
            return "Доступ к камере не запрошен"
        case .cameraSessionFailed(let error):
            return "Ошибка работы камеры: \(error.localizedDescription)"
        case .flashlightError(let error):
            return "Ошибка включения фонарика: \(error.localizedDescription)"
        case .failedToCloseScreen:
            return "Не удалось закрыть экран"
        case .locationNotFound:
            return "Не могу найти такой адрес"
        case .databaseError(let error):
            return "Ошибка загрузки данных: \(error.localizedDescription)"
        case .searchError(let error):
            return "Не удалось выполнить поиск: \(error.localizedDescription)"
        case .failedToDeleteReceipt(let error):
            return "Не удалось удалить чек: \(error.localizedDescription)"
        case .placeNotFound(let string):
            return "Местоположение не найдено: \(string)"
        }
    }
}
