//
//  OperationsTypeEnum.swift
//  Tandau
//
//  Created by Sergey Ivanov on 08.01.2025.
//

enum OperationTypeEnum: UInt16, Encodable {
    /// Покупка
    case buy = 0
    /// Возврат покупки
    case buyReturn = 1
    /// Продажа
    case sell = 2
    /// Возврат продажи
    case sellReturn = 3

    /// Возвращает строковый код операции для использования в протоколе.
    ///
    /// - Пример: Для `.buy` возвращается "OPERATION_BUY".
    var operationCode: String {
        switch self {
        case .buy:
            return "OPERATION_BUY"
        case .buyReturn:
            return "OPERATION_BUY_RETURN"
        case .sell:
            return "OPERATION_SELL"
        case .sellReturn:
            return "OPERATION_SELL_RETURN"
        }
    }

    /// Возвращает текстовое описание операции на указанном языке.
    ///
    /// - Parameter language: Язык описания (`"ru"`, `"kk"`, `"en"`).
    /// - Returns: Текстовое описание операции на указанном языке.
    func description(in language: String) -> String {
        switch (self, language) {
        case (.buy, "ru"):
            return "Покупка"
        case (.buyReturn, "ru"):
            return "Возврат покупки"
        case (.sell, "ru"):
            return "Продажа"
        case (.sellReturn, "ru"):
            return "Возврат продажи"
        case (.buy, "kk"):
            return "Сатып алу"
        case (.buyReturn, "kk"):
            return "Сатып алуды қайтару"
        case (.sell, "kk"):
            return "Сату"
        case (.sellReturn, "kk"):
            return "Сатуды қайтару"
        case (.buy, "en"):
            return "Purchase"
        case (.buyReturn, "en"):
            return "Purchase Return"
        case (.sell, "en"):
            return "Sale"
        case (.sellReturn, "en"):
            return "Sale Return"
        default:
            return "Unknown Operation"
        }
    }
}
