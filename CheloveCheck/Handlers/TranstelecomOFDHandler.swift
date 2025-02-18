//
//  TranstelecomOFDHandler.swift
//  CheloveCheck
//
//  Created by Sergey Ivanov on 05.01.2025.
//

import Foundation
import SwiftSoup

enum ParsingError: LocalizedError {
    case missingSymbol(String, String)
    case invalidStructure(String)

    var errorDescription: String? {
        switch self {
        case .missingSymbol(let symbol, let context):
            return "Ошибка парсинга: отсутствует символ '\(symbol)' в строке: \(context)"
        case .invalidStructure(let context):
            return "Ошибка структуры данных: \(context)"
        }
    }
}

final class TranstelecomOFDHandler: NSObject, OFDHandler {
    func fetchCheck(from initialURL: URL, completion: @escaping (Result<Receipt, Error>) -> Void) {
        print("Начало fetchCheck: URL = \(initialURL.absoluteString)")
        
        var request = URLRequest(url: initialURL)
        request.httpMethod = "GET"
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Ошибка при выполнении запроса: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                print("Ошибка: Некорректный HTTP-ответ")
                completion(.failure(NSError(domain: "InvalidResponse", code: 0, userInfo: nil)))
                return
            }
            
            print("HTTP-код ответа: \(response.statusCode)")
            
            guard let data = data, let html = String(data: data, encoding: .utf8) else {
                print("Ошибка: Нет данных или невозможно декодировать HTML")
                completion(.failure(NSError(domain: "NoData", code: 0, userInfo: nil)))
                return
            }
            
            print("Получен HTML-контент длиной \(html.count) символов")
            
            do {
                // Парсим HTML, используя SwiftSoup
                let document = try SwiftSoup.parse(html)
                print("HTML успешно разобран")
                
                // Преобразуем HTML в структуру Receipt
                let receipt = try self.convertHTMLToReceipt(document, url: initialURL)
                completion(.success(receipt))
                
            } catch {
                print("Ошибка при парсинге HTML: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    private func convertHTMLToReceipt(_ document: Document, url: URL) throws -> Receipt {
        // Извлечение данных из HTML
        let companyName = try extractCompanyName(from: document)
        let companyAddress = try document.select("div.ticket_header > div:contains(Адрес) > span").text()
        let iinBin = try document.select("div.ticket_header > div:contains(БИН) > span").text()
        let serialNumber = try document.select("div.ticket_header > div:contains(ЗНМ) > span").text()
        let kgdId = try document.select("div.ticket_header > div:contains(РНМ) > span").text()
        let fiscalSign = try document.select("div.ticket_footer > div:contains(Фискальный признак) > span").text()
        // Преобразуем текстовую дату в объект Date
        let dateTimeText = try document.select("div.ticket_header > div:contains(Дата и время) > span").text()
        print("Дата из чека: \(dateTimeText)")
        let numericDate = convertMonthToNumber(dateTimeText)
        
        let dateFormatter = DateFormatter()

        // Настраиваем форматтер
        dateFormatter.locale = Locale(identifier: "ru_RU")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = "dd MM yyyy, HH:mm"

        // Конвертируем строку в дату
        guard let dateTime = dateFormatter.date(from: numericDate) else {
            throw ParsingError.invalidStructure("Некорректный формат даты: \(dateTimeText)")
        }

        print(dateTime)
        let ofd = OfdEnum.transtelecom
        let typeOperation = try extractOperationType(from: document)
        
        // Извлечение товаров
        let itemsElements = try document.select("ol.ready_ticket__items_list > li")
        let items = try parseItems(from: itemsElements)

        // Итоги
        let totalType = try extractTotalType(from: document)
        let totalSum = Double(try document.select("div.total_sum > div > b > span").text()) ?? 0.0
        let change = try extractChange(from: document)
        
        // я думаю для ТТК сделать смостоятельный подсчет общего итога по налогам
        
        // Формируем Receipt
        return Receipt(
            companyName: companyName,
            certificateVAT: nil,
            iinBin: iinBin,
            companyAddress: companyAddress,
            serialNumber: serialNumber,
            kgdId: kgdId,
            dateTime: dateTime,
            fiscalSign: fiscalSign,
            ofd: ofd,
            typeOperation: typeOperation,
            items: items,
            url: url.absoluteString,
            taxsesType: nil,
            taxesSum: nil,
            taken: nil,
            change: change,
            totalType: totalType,
            totalSum: totalSum
        )
    }
    
    private func extractCompanyName(from document: Document) throws -> String {
        let companyName = try document.select("div.ticket_header > div > span").first()?.text() ?? ""
        return companyName
    }
    
    /// Преобразует названия месяцев в числовой формат (например, "февраля" -> "02", "фев." -> "02")
    private func convertMonthToNumber(_ dateText: String) -> String {
        let monthMapping: [String: String] = [
            "январь": "01", "января": "01", "Январь": "01", "Января": "01",
            "янв": "01", "янв.": "01", "Янв": "01", "Янв.": "01",

            "февраль": "02", "февраля": "02", "Февраль": "02", "Февраля": "02",
            "фев": "02", "фев.": "02", "Фев": "02", "Фев.": "02",

            "март": "03", "марта": "03", "Март": "03", "Марта": "03",
            "мар": "03", "мар.": "03", "Мар": "03", "Мар.": "03",

            "апрель": "04", "апреля": "04", "Апрель": "04", "Апреля": "04",
            "апр": "04", "апр.": "04", "Апр": "04", "Апр.": "04",

            "май": "05", "мая": "05", "Май": "05", "Мая": "05",

            "июнь": "06", "июня": "06", "Июнь": "06", "Июня": "06",
            "июн": "06", "июн.": "06", "Июн": "06", "Июн.": "06",

            "июль": "07", "июля": "07", "Июль": "07", "Июля": "07",
            "июл": "07", "июл.": "07", "Июл": "07", "Июл.": "07",

            "август": "08", "августа": "08", "Август": "08", "Августа": "08",
            "авг": "08", "авг.": "08", "Авг": "08", "Авг.": "08",

            "сентябрь": "09", "сентября": "09", "Сентябрь": "09", "Сентября": "09",
            "сент": "09", "сент.": "09", "Сент": "09", "Сент.": "09",

            "октябрь": "10", "октября": "10", "Октябрь": "10", "Октября": "10",
            "окт": "10", "окт.": "10", "Окт": "10", "Окт.": "10",

            "ноябрь": "11", "ноября": "11", "Ноябрь": "11", "Ноября": "11",
            "нояб": "11", "нояб.": "11", "Нояб": "11", "Нояб.": "11",

            "декабрь": "12", "декабря": "12", "Декабрь": "12", "Декабря": "12",
            "дек": "12", "дек.": "12", "Дек": "12", "Дек.": "12"
        ]

        var convertedText = dateText
        for (variant, number) in monthMapping {
            convertedText = convertedText.replacingOccurrences(of: variant, with: number)
        }
        return convertedText
    }
    
    // MARK: Парсим тип операции
    private func extractOperationType(from document: Document) throws -> OperationTypeEnum {
        // Извлекаем текст из HTML
        let operationTypeText = try document.select("div.ticket_header > div:contains(Кассалық чек / Кассовый чек) > span")
            .text()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Убираем всё до последнего "/" и оставляем только тип операции
        guard let operationType = operationTypeText.split(separator: "/").last?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            throw NSError(domain: "HTMLParsingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Не удалось извлечь тип операции из текста: \(operationTypeText)"])
        }

        // Сопоставляем с `OperationTypeEnum`
        return try mapOperationTypeToEnum(operationType)
    }

    private func mapOperationTypeToEnum(_ text: String) throws -> OperationTypeEnum {
        // Возможные значения для каждой операции
        let buyKeywords = ["Покупка", "Сатып алу", "Purchase", "Купить", "Покуп", "Buy"]
        let buyReturnKeywords = ["Возврат покупки", "Сатып алуды қайтару", "Purchase Return", "Возврат", "Return", "Refund"]
        let sellKeywords = ["Продажа", "Сату", "Sale", "Прода", "Продать", "Sell"]
        let sellReturnKeywords = ["Возврат продажи", "Сатуды қайтару", "Sale Return", "Возврат прод", "Возврат товар", "Return Sale"]

        let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        // Сравниваем текст с ключевыми словами
        if buyKeywords.contains(where: { cleanedText.contains($0.lowercased()) }) {
            return .buy
        }
        if buyReturnKeywords.contains(where: { cleanedText.contains($0.lowercased()) }) {
            return .buyReturn
        }
        if sellKeywords.contains(where: { cleanedText.contains($0.lowercased()) }) {
            return .sell
        }
        if sellReturnKeywords.contains(where: { cleanedText.contains($0.lowercased()) }) {
            return .sellReturn
        }

        // Если текст не совпал ни с одним из известных значений
        throw NSError(domain: "HTMLParsingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Неизвестный тип операции: \(text)"])
    }
    
    // MARK: - Private Methods
    private func parseItems(from elements: Elements) throws -> [Item] {
        return try elements.compactMap { element in
            do {
                // Извлекаем имя товара
                var name = try element.select("span.wb-all").text().trimmingCharacters(in: .whitespacesAndNewlines)
                var barcode: String? = nil

                // Проверяем на наличие 13 или 8 цифр в начале строки
                if let match = name.range(of: "^(\\d{13}|\\d{8})", options: .regularExpression) {
                    barcode = String(name[match])
                    name = name.replacingCharacters(in: match, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                }

                // Извлекаем строку с информацией о товаре
                let itemInfoDiv = try element.select("div.ready_ticket__item").first()
                guard let itemInfoDiv else {
                    throw ParsingError.invalidStructure("Не найден блок ready_ticket__item")
                }

                // Исключаем содержимое тега <b>
                try itemInfoDiv.select("b").remove()

                // Получаем текст без содержимого <b>
                let itemInfo = try itemInfoDiv.text()
                print("Обрабатывается строка itemInfo: \(itemInfo)")

                // Парсим информацию о цене, количестве и сумме
                guard let xIndex = itemInfo.firstIndex(of: "x") else {
                    throw ParsingError.missingSymbol("x", itemInfo)
                }

                guard let equalsIndex = itemInfo.firstIndex(of: "=") else {
                    throw ParsingError.missingSymbol("=", itemInfo)
                }

                // Парсим price
                let priceText = itemInfo[..<xIndex]
                    .replacingOccurrences(of: " ", with: "") // Удаляем пробелы
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                // Извлекаем count и unit
                let countAndUnit = itemInfo[itemInfo.index(after: xIndex)..<equalsIndex]
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                let components = countAndUnit.split(separator: " ").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

                var countText = ""
                var unitText = ""
                if components.count >= 2 {
                    if let last = components.last, last.allSatisfy({ $0.isLetter }) {
                        unitText = last
                        countText = components.dropLast().joined(separator: " ")
                    } else {
                        countText = components.first ?? ""
                        unitText = components.dropFirst().joined(separator: " ")
                    }
                } else if !components.isEmpty {
                    countText = components[0]
                } else {
                    throw ParsingError.invalidStructure("Пустая строка countAndUnit: \(countAndUnit)")
                }

                // Теперь преобразуем unitText в UnitOfMeasurementEnum
                let unitEnum = UnitOfMeasurementEnum.from(value: unitText)
                
                // Убираем пробелы и запятые в количестве
                countText = countText.replacingOccurrences(of: ",", with: ".").replacingOccurrences(of: " ", with: "")

                guard let count = Double(countText) else {
                    throw ParsingError.invalidStructure("Не удалось преобразовать count: \(countText)")
                }

                // Парсим sum
                let sumStart = itemInfo.index(after: equalsIndex)

                // Находим конец суммы, до подстроки "ҚҚС"
                guard let sumEnd = itemInfo[sumStart...].range(of: "ҚҚС")?.lowerBound else {
                    throw ParsingError.missingSymbol("ҚҚС", itemInfo)
                }

                // Извлекаем сумму
                let sumText = itemInfo[sumStart..<sumEnd]
                    .replacingOccurrences(of: ",", with: ".")
                    .replacingOccurrences(of: " ", with: "") // Удаляем пробелы
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                // Парсим taxType и taxSum
                let taxInfo = itemInfo[itemInfo.index(after: sumEnd)...]
                let taxParts = taxInfo.split(separator: ":").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                let taxType = taxParts.first
                let taxSumText = taxParts.last?
                    .replacingOccurrences(of: " ", with: "") // Удаляем пробелы

                guard let price = Double(priceText),
                      let sum = Double(sumText),
                      let taxSum = Double(taxSumText ?? "") else {
                    throw ParsingError.invalidStructure("Не удалось преобразовать данные (price: \(priceText), sum: \(sumText), taxSum: \(taxSumText ?? ""))")
                }

                // Формируем объект Item
                return Item(
                    barcode: barcode,
                    codeMark: nil,
                    name: name,
                    count: count,
                    price: price,
                    unit: unitEnum,
                    sum: sum,
                    taxType: taxType,
                    taxSum: taxSum
                )
            } catch let error as ParsingError {
                throw error
            } catch {
                throw error
            }
        }
    }
    
    private func extractTotalType(from document: Document) throws -> [Payment] {
        // Карта соответствий для типов оплаты
        let paymentTypeMapping: [PaymentTypeEnum: [String]] = [
            .cash: ["нал", "наличные", "cash"],
            .card: ["карт", "карта", "bank", "card"],
            .mobile: ["моб", "мобильные", "mobile"]
        ]

        // Найти блок <div> с классом "total_sum"
        guard let totalSumDiv = try document.select("div.total_sum").first() else {
            throw ParsingError.invalidStructure("Не найден блок <div> с классом 'total_sum'")
        }

        // Найти блок <ul> с классом "list-unstyled"
        guard let totalTypeUl = try totalSumDiv.select("ul.list-unstyled").first() else {
            throw ParsingError.invalidStructure("Не найден список <ul> с деталями оплаты")
        }

        // Извлечь все элементы <li> внутри <ul>
        let listItems = try totalTypeUl.select("li")

        // Создаём массив для totalType
        var totalType: [Payment] = []

        for listItem in listItems {
            // Извлекаем текст из <li>
            let listItemText = try listItem.text()
                .trimmingCharacters(in: .whitespacesAndNewlines)

            // Разделяем текст на тип оплаты и сумму
            guard let colonIndex = listItemText.firstIndex(of: ":") else {
                throw ParsingError.invalidStructure("Некорректная структура элемента <li>: \(listItemText)")
            }

            // Тип оплаты — текст до двоеточия
            let paymentTypeText = String(listItemText[..<colonIndex].trimmingCharacters(in: .whitespacesAndNewlines))

            // Сумма — текст после двоеточия
            let paymentAmountText = listItemText[listItemText.index(after: colonIndex)...]
                .replacingOccurrences(of: ",", with: ".")
                .replacingOccurrences(of: " ", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard let paymentAmount = Double(paymentAmountText) else {
                throw ParsingError.invalidStructure("Не удалось преобразовать сумму в число: \(paymentAmountText)")
            }

            // Сопоставление типа оплаты
            let paymentType: PaymentTypeEnum? = {
                // Проверяем текст на наличие ключевых слов для каждого типа оплаты
                for (type, keywords) in paymentTypeMapping {
                    if keywords.contains(where: { paymentTypeText.lowercased().contains($0.lowercased()) }) {
                        return type
                    }
                }
                // Если не найдено по тексту, пытаемся преобразовать в enum через идентификатор
                if let paymentTypeID = UInt(paymentTypeText), let enumType = PaymentTypeEnum(rawValue: UInt16(paymentTypeID)) {
                    return enumType
                }
                return nil
            }()

            // Если тип оплаты не удалось определить
            guard let validPaymentType = paymentType else {
                throw ParsingError.invalidStructure("Неизвестный тип оплаты: \(paymentTypeText)")
            }

            // Создаем объект Payment и добавляем в массив
            totalType.append(Payment(type: validPaymentType, sum: paymentAmount))
        }

        return totalType
    }

    private func extractChange(from document: Document) throws -> Double? {
        // Найти блок <div> с классом "total_sum"
        guard let totalSumDiv = try document.select("div.total_sum").first() else {
            throw ParsingError.invalidStructure("Не найден блок <div> с классом 'total_sum'")
        }
        print(totalSumDiv)

        // Найти <div>, содержащий текст "Тапсыру /  Сдача:"
        guard let changeDiv = try totalSumDiv.select("div:contains(Тапсыру /  Сдача:)").first() else {
            return nil // Сдачи может не быть
        }

        // Извлечь текст из найденного блока
        let changeText = try changeDiv.text()
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Найти двоеточие и извлечь сумму после него
        guard let colonIndex = changeText.firstIndex(of: ":") else {
            throw ParsingError.invalidStructure("Некорректная структура текста сдачи: \(changeText)")
        }

        // Текст после двоеточия — это сумма сдачи
        let changeAmountText = changeText[changeText.index(after: colonIndex)...]
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Преобразовать сумму в Double
        guard let changeAmount = Double(changeAmountText) else {
            throw ParsingError.invalidStructure("Не удалось преобразовать сумму сдачи в число: \(changeAmountText)")
        }

        return changeAmount
    }
}
