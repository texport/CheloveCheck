//
//  JusanOFDHandler.swift
//  CheloveCheck
//
//  Created by Sergey Ivanov on 07.02.2025.
//

import Foundation

final class JusanOFDHandler: NSObject, OFDHandler {

    func fetchCheck(from initialURL: URL, completion: @escaping (Result<Receipt, Error>) -> Void) {
        print("Ссылка на чек: \(initialURL.absoluteString)")

        guard let components = URLComponents(url: initialURL, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            completion(.failure(NSError(domain: "InvalidURL", code: 0, userInfo: [NSLocalizedDescriptionKey: "Неверный формат URL"])))
            return
        }

        guard let ticketNumber = queryItems.first(where: { $0.name == "i" })?.value,
              let registrationNumber = queryItems.first(where: { $0.name == "f" })?.value,
              let rawDate = queryItems.first(where: { $0.name == "t" })?.value else {
            completion(.failure(NSError(domain: "InvalidURLParams", code: 1, userInfo: [NSLocalizedDescriptionKey: "Отсутствуют обязательные параметры в URL"])))
            return
        }

        let ticketDate = convertDateFormat(rawDate)

        let apiURLString = "https://cabinet.kofd.kz/api/tickets?registrationNumber=\(registrationNumber)&ticketNumber=\(ticketNumber)&ticketDate=\(ticketDate)"

        guard let apiURL = URL(string: apiURLString) else {
            completion(.failure(NSError(domain: "InvalidAPIURL", code: 2, userInfo: nil)))
            return
        }

        var request = URLRequest(url: apiURL)
        request.httpMethod = "GET"
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/97.0.4692.71 Safari/537.36", forHTTPHeaderField: "User-Agent")

        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                completion(.failure(NSError(domain: "HTTPError", code: 3, userInfo: nil)))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "NoData", code: 4, userInfo: nil)))
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                let receipt = try self.convertToReceipt(from: json, url: initialURL.absoluteString)
                completion(.success(receipt))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    private func convertDateFormat(_ dateStr: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyyMMdd'T'HHmmss"
        inputFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "yyyy-MM-dd"
        outputFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        if let date = inputFormatter.date(from: dateStr) {
            return outputFormatter.string(from: date)
        } else {
            return dateStr
        }
    }
    
    private func convertToReceipt(from json: [String: Any]?, url: String) throws -> Receipt {
        guard let data = json?["data"] as? [String: Any],
              let ticketArray = data["ticket"] as? [[String: Any]] else {
            throw NSError(domain: "InvalidJSON", code: 5, userInfo: [NSLocalizedDescriptionKey: "Некорректная структура JSON"])
        }
        
        var items: [Item] = []
        var payments: [Payment] = []
        
        let companyName = extractCompanyName(from: ticketArray)
        let iinBin = extractIinBin(from: ticketArray)
        let typeOperation = extractTypeOperation(from: ticketArray)
        let fiscalSign = extractFiscalSign(from: ticketArray)
        let dateTime = extractDateTime(from: ticketArray)
        let serialNumber = extractSerialNumber(from: ticketArray)
        let kgdId = extractKgdId(from: ticketArray)
        
        let (parsedItems, _) = extractItems(from: ticketArray)
        items.append(contentsOf: parsedItems)
        
        let (taken, parsedPayments, change, taxsesType, taxesSum, totalSum) = extractTotals(from: ticketArray)
        payments.append(contentsOf: parsedPayments)
        
        let reciept = Receipt(
            companyName: companyName,
            certificateVAT: nil,
            iinBin: iinBin,
            companyAddress: "",
            serialNumber: serialNumber,
            kgdId: kgdId,
            dateTime: dateTime,
            fiscalSign: fiscalSign,
            ofd: OfdEnum.kofd,
            typeOperation: typeOperation,
            items: items,
            url: url,
            taxsesType: taxsesType,
            taxesSum: taxesSum,
            taken: taken,
            change: change,
            totalType: payments,
            totalSum: totalSum
        )
        
        print("====== ЧЕК ======")
        print("📌 Компания: \(reciept.companyName)")
        print("📌 БИН/ИИН: \(reciept.iinBin)")
        print("📌 Адрес: \(reciept.companyAddress)")
        print("📌 Дата и время: \(reciept.dateTime)")
        print("📌 Фискальный признак: \(reciept.fiscalSign)")
        print("📌 Серийный номер ККМ: \(reciept.serialNumber)")
        print("📌 Регистрационный номер в КГД: \(reciept.kgdId)")
        print("📌 ИТОГО: \(reciept.totalSum) ₸")
        print("📌 Оплата: \(reciept.totalType.map { "\($0.type) - \($0.sum) ₸" }.joined(separator: ", "))")
        print("=================\n")
        
        print("🛒 ТОВАРЫ:")
        reciept.items.forEach { item in
            print("\(item.name): \(item.count) \(item.unit.rawValue) x \(item.price)₸ = \(item.sum)₸")
        }
        print("=================\n")
        
        print("💳 ОПЛАТА:")
        reciept.totalType.forEach { payment in
            print("\(payment.type): \(payment.sum)₸")
        }
        print("=================\n")
        
        print("📊 НАЛОГИ:")
        if let taxType = reciept.taxsesType, let taxSum = reciept.taxesSum {
            print("\(taxType): \(taxSum)₸")
        } else {
            print("Нет налога")
        }
        print("=================\n")
        
        return reciept
    }
    
    private func extractCompanyName(from ticketArray: [[String: Any]]) -> String {
        var companyNameLines: [String] = []
        
        for entry in ticketArray {
            guard let text = entry["text"] as? String else { continue }
            
            if text.contains("БСН/БИН") || text.contains("ИИН") {
                break
            }
            
            companyNameLines.append(text)
        }
        
        return companyNameLines.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func extractIinBin(from ticketArray: [[String: Any]]) -> String {
        for entry in ticketArray {
            guard let text = entry["text"] as? String else { continue }
            
            if text.contains("БСН/БИН") || text.contains("ИИН") {
                return text.replacingOccurrences(of: "БСН/БИН", with: "")
                           .replacingOccurrences(of: "ИИН", with: "")
                           .trimmingCharacters(in: .whitespaces)
            }
        }
        return "Неизвестно"
    }
    
    private func extractTypeOperation(from ticketArray: [[String: Any]]) -> OperationTypeEnum {
        var foundIinBin = false
        
        for entry in ticketArray {
            guard let text = entry["text"] as? String else { continue }

            if foundIinBin {
                let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmedText.isEmpty {
                    continue
                }
                
                switch text {
                case "Продажа":
                    return .sell
                case "Возврат", "Возврат продажи":
                    return .sellReturn
                case "Покупка":
                    return .buy
                case "Возврат покупки":
                    return .buyReturn
                default:
                    return .sell
                }
            }
            
            if text.contains("БСН/БИН") || text.contains("ИИН") {
                foundIinBin = true
            }
        }
        
        return .sell
    }
    
    private func extractFiscalSign(from ticketArray: [[String: Any]]) -> String {
        for entry in ticketArray {
            guard let text = entry["text"] as? String else { continue }

            if text.contains("ФИСКАЛЬНЫЙ ПРИЗНАК") {
                return text.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) ?? ""
            }
        }
        return "Неизвестно"
    }
    
    private func extractDateTime(from ticketArray: [[String: Any]]) -> Date {
        let dateKeywords = ["Время", "Дата", "ДАТА", "ВРЕМЯ"]
        
        for entry in ticketArray {
            guard let text = entry["text"] as? String else { continue }
            
            if dateKeywords.contains(where: { text.contains($0) }) {
                let rawDate = text.components(separatedBy: ":").dropFirst().joined(separator: ":")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                return convertDate(rawDate)
            }
        }
        return Date()
    }
    
    private func extractSerialNumber(from ticketArray: [[String: Any]]) -> String {
        for entry in ticketArray {
            guard let text = entry["text"] as? String else { continue }

            if text.contains("КЗН/ЗНМ") {
                let afterKZN = text.components(separatedBy: "КЗН/ЗНМ").last ?? ""

                if afterKZN.contains("КСН/ИНК") {
                    return afterKZN.components(separatedBy: "КСН/ИНК").first?
                        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                } else {
                    return afterKZN.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        return "Неизвестно"
    }
    
    private func extractKgdId(from ticketArray: [[String: Any]]) -> String {
        for entry in ticketArray {
            guard let text = entry["text"] as? String else { continue }

            if text.contains("КТН/РНМ") {
                return text.components(separatedBy: "КТН/РНМ").last?.trimmingCharacters(in: .whitespaces) ?? ""
            }
        }
        return "Неизвестно"
    }
    
    private func extractItems(from ticketArray: [[String: Any]]) -> ([Item], Int) {
        var items: [Item] = []
        var index = 0

        // Извлекаем сырые строки товаров в отдельный массив
        let itemsRawData = extractRawItemsData(from: ticketArray, index: &index)
        
        // Создаём массив массивов (структурируем сырые данные)
        let structuredItems: [[String]] = extractItemsAndDiscounts(from: itemsRawData)
        
        // Передаём данные в parseItem
        structuredItems.forEach { itemData in
            let name = itemData[0]
            let countPriceSumText = itemData[1]
            let taxText = itemData[2].isEmpty ? nil : itemData[2]

            let item = parseItem(name: name, countPriceSumText: countPriceSumText, taxText: taxText ?? "")
            items.append(item)
        }

        return (items, index)
    }
    
    // MARK: Достаем сырые позиции
    private func extractRawItemsData(from ticketArray: [[String: Any]], index: inout Int) -> [String] {
        var itemsRawData: [String] = []

        while index < ticketArray.count, let text = ticketArray[index]["text"] as? String {
            if text.contains("***********************************************") {
                index += 1
                break
            }
            index += 1
        }

        while index < ticketArray.count, let text = ticketArray[index]["text"] as? String {
            if text == "------------------------------------------------" {
                index += 1
                break
            }
            itemsRawData.append(text)
            index += 1
        }

        return itemsRawData
    }
    
    private func extractItemsAndDiscounts(from itemsRawData: [String]) -> [[String]]{
        var structuredItems: [[String]] = []
        var index = 0

        while index < itemsRawData.count {
            let firstLine = itemsRawData[index].trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Если нашли "ЖЕҢІЛДІК" или "СКИДКА" — это скидки, выходим из цикла
            if firstLine.contains("ЖЕҢІЛДІК/СКИДКА") || firstLine.contains("НАЦЕНКА") {
                break
            }
            
            var itemNameLines: [String] = []
            
            // Первая строка всегда часть названия товара
            itemNameLines.append(itemsRawData[index].trimmingCharacters(in: .whitespacesAndNewlines))
            index += 1

            // Определяем, где заканчивается название товара
            while index < itemsRawData.count {
                let line = itemsRawData[index].trimmingCharacters(in: .whitespacesAndNewlines)
                
                if isQuantityPriceSumLine(line) {
                    break
                }

                itemNameLines.append(line)
                index += 1
            }

            let cleanedItemName = cleanItemName(itemNameLines.joined(separator: " "))
            
            // Нашли строку с количеством/ценой
            let countPriceSumText = index < itemsRawData.count ? itemsRawData[index] : ""
            index += 1

            // Ищем строку с НДС
//            var taxText: String = ""
//            while index < itemsRawData.count {
//                let taxLine = itemsRawData[index].trimmingCharacters(in: .whitespacesAndNewlines)
//                
//                if taxLine.contains("НДС") {
//                    taxText = taxLine
//                    index += 1
//                    break
//                }
//                index += 1
//            }
            
            // Проверяем, есть ли НДС (может отсутствовать)
            var taxText: String? = nil
            if index < itemsRawData.count {
                let taxLine = itemsRawData[index].trimmingCharacters(in: .whitespacesAndNewlines)
                
                if taxLine.contains("НДС") {
                    taxText = taxLine
                    index += 1
                }
            }
            
            // Добавляем найденную позицию в массив
            structuredItems.append([
                cleanedItemName,
                countPriceSumText,
                taxText ?? ""
            ])
        }
        print(structuredItems)
        return structuredItems
    }
    
    private func isQuantityPriceSumLine(_ text: String) -> Bool {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Должны присутствовать "x" и "₸" и строка должна начинаться с цифры
        return trimmedText.contains("x") && trimmedText.contains("₸") && trimmedText.first?.isNumber == true
    }
    
    private func cleanItemName(_ name: String) -> String {
        let cleanedName = name
            .replacingOccurrences(of: #"\"#, with: "")  // Удаляем все слэши `\`
            .replacingOccurrences(of: #"\""#, with: "") // Удаляем двойные кавычки `"`
            .replacingOccurrences(of: "|", with: "")    // Убираем разделители `|`
            .replacingOccurrences(of: "*", with: "")    // Убираем звездочки `*`
            .replacingOccurrences(of: "_", with: "")    // Убираем нижние подчеркивания `_`
            .replacingOccurrences(of: "~", with: "")    // Убираем тильды `~`
            .trimmingCharacters(in: .whitespacesAndNewlines) // Очищаем от лишних пробелов

        return cleanedName
    }
    
    private func extractTotals(from ticketArray: [[String: Any]]) -> (Double?, [Payment], Double?, String?, Double?, Double) {
        var totalsRawData: [String] = []
        var index = 0

        // Извлекаем все строки итогов
        while index < ticketArray.count, let text = ticketArray[index]["text"] as? String {
            if text == "------------------------------------------------" {
                index += 1
                break
            }
            index += 1
        }

        while index < ticketArray.count, let text = ticketArray[index]["text"] as? String {
            if text == "------------------------------------------------" {
                index += 1
                break
            }
            totalsRawData.append(text)
            index += 1
        }

        // Парсим значения по известным позициям
        let taken = totalsRawData.indices.contains(0) ? extractTaken(from: totalsRawData[0]) : nil
        let payments = totalsRawData.indices.contains(1) ? extractPayments(from: totalsRawData[1]) : []
        let change = totalsRawData.indices.contains(2) ? extractChange(from: totalsRawData[2]) : nil
        let taxType = totalsRawData.indices.contains(5) ? "НДС" : nil
        let taxesSum = totalsRawData.indices.contains(5) ? extractTaxesSum(from: totalsRawData[5]) : nil
        let totalSum = totalsRawData.indices.contains(6) ? extractTotalSum(from: totalsRawData[6]) : 0.0

        return (taken, payments, change, taxType, taxesSum, totalSum)
    }
    
    private func extractPayments(from text: String) -> [Payment] {
        var payments: [Payment] = []
        let parts = text.components(separatedBy: ":")

        if parts.count == 2 {
            let typeString = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let sumText = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
            let sum = extractAmount(from: sumText)

            // Определяем тип оплаты
            let type: PaymentTypeEnum = {
                if typeString.contains("Банковская карта") { return .card }
                if typeString.contains("Наличные") { return .cash }
                if typeString.contains("Мобильные платежи") { return .mobile }
                return .card
            }()

            payments.append(Payment(type: type, sum: sum))
        }

        return payments
    }
    
    private func extractAmount(from text: String) -> Double {
        let cleanedText = text
            .replacingOccurrences(of: "₸", with: "")
            .replacingOccurrences(of: "\u{00A0}", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let value = Double(cleanedText) ?? 0.0
        
        return value
    }
    
    // Извлекает "Сумма оплаты" (taken)
    private func extractTaken(from text: String) -> Double {
        return extractSpecificAmount(from: text, after: "Төленген сома/Сумма оплаты")
    }

    // Извлекает "Сумма сдачи" (change)
    private func extractChange(from text: String) -> Double {
        return extractSpecificAmount(from: text, after: "Қайтарым сомасы/Сумма сдачи")
    }

    // Извлекает "Сумма НДС" (taxesSum)
    private func extractTaxesSum(from text: String) -> Double {
        return extractSpecificAmount(from: text, after: "ҚҚС сомасы/Сумма НДС")
    }

    // Извлекает "Итоговую сумму" (totalSum)
    private func extractTotalSum(from text: String) -> Double {
        return extractSpecificAmount(from: text, after: ":")
    }

    // Общий метод, который извлекает число после указанного ключа
    private func extractSpecificAmount(from text: String, after keyword: String) -> Double {
        guard let range = text.range(of: keyword) else { return 0.0 }
        
        // Обрезаем строку, оставляя только сумму после ключа
        let amountText = text[range.upperBound...]
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "₸", with: "")
            .replacingOccurrences(of: "\u{00A0}", with: "") // Убираем неразрывные пробелы
            .replacingOccurrences(of: " ", with: "") // Убираем пробелы (разделители тысяч)
            .replacingOccurrences(of: ",", with: ".") // Заменяем запятую на точку
        
        let value = Double(amountText) ?? 0.0
        
        return value
    }
    
    private func convertDate(_ dateStr: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "Asia/Almaty")
        
        return formatter.date(from: dateStr) ?? Date()
    }
    
    private func parseItem(name: String, countPriceSumText: String, taxText: String) -> Item {
        let countPattern = #"^([\d.,]+)\s*\("#
        let unitPattern = #"\((.*?)\)"#
        let pricePattern = #"x\s*([\d\s]+,\d+)₸"#
        let sumPattern = #"=\s*([\d\s]+,\d+)₸"#

        let cleanedText = countPriceSumText.replacingOccurrences(of: "\u{00A0}", with: " ") // Убираем неразрывные пробелы

        let countText = extractMatch(from: cleanedText, using: countPattern)?
                .replacingOccurrences(of: ",", with: ".") ?? "0.0"
        let count = Double(countText) ?? 0.0
        let unitText = extractMatch(from: cleanedText, using: unitPattern) ?? "шт"
        let priceText = extractMatch(from: cleanedText, using: pricePattern)?
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: ".") ?? "0.0"
        let sumText = extractMatch(from: cleanedText, using: sumPattern)?
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: ".") ?? "0.0"

        let price = Double(priceText) ?? 0.0
        let sum = Double(sumText) ?? 0.0

        let unit = UnitOfMeasurementEnum.from(value: unitText)

        let taxSum = extractAmount(from: taxText.replacingOccurrences(of: "НДС", with: "").trimmingCharacters(in: .whitespaces))

        return Item(
            barcode: nil,
            codeMark: nil,
            name: name,
            count: count,
            price: price,
            unit: unit,
            sum: sum,
            taxType: taxText.isEmpty ? nil : "НДС",
            taxSum: taxSum
        )
    }
    
    private func extractMatch(from text: String, using pattern: String) -> String? {
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let nsString = text as NSString
        let match = regex?.firstMatch(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        if let range = match?.range(at: 1) {
            return nsString.substring(with: range).trimmingCharacters(in: .whitespaces)
        }
        return nil
    }
}
