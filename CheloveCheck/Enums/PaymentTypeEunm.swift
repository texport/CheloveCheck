//
//  PaymentTypeEunm.swift
//  Tandau
//
//  Created by Sergey Ivanov on 09.01.2025.
//

enum PaymentTypeEnum: UInt16, Encodable, CaseIterable {
    /// Наличные
    case cash = 0
    /// Банковская карта
    case card = 1
    /// Мобильные платежи
    case mobile = 4

    /// Возвращает строковый код типа оплаты для использования в протоколе.
    ///
    /// - Пример: Для `.cash` возвращается "PAYMENT_CASH".
    var paymentCode: String {
        switch self {
        case .cash:
            return "PAYMENT_CASH"
        case .card:
            return "PAYMENT_CARD"
        case .mobile:
            return "PAYMENT_MOBILE"
        }
    }

    /// Возвращает текстовое описание типа оплаты на указанном языке.
    ///
    /// - Parameter language: Язык описания (`"ru"`, `"kk"`, `"en"`).
    /// - Returns: Текстовое описание типа оплаты на указанном языке.
    func description(in language: String) -> String {
        switch (self, language) {
        case (.cash, "ru"):
            return "Наличные"
        case (.card, "ru"):
            return "Банковская карта"
        case (.mobile, "ru"):
            return "Мобильные платежи"
        case (.cash, "kk"):
            return "Қолма-қол"
        case (.card, "kk"):
            return "Банктік карта"
        case (.mobile, "kk"):
            return "Мобильді төлемдер"
        case (.cash, "en"):
            return "Cash"
        case (.card, "en"):
            return "Bank Card"
        case (.mobile, "en"):
            return "Mobile Payments"
        default:
            return "Unknown Payment Type"
        }
    }
}
