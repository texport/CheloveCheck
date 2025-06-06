//
//  KazakhtelecomOFDHandler.swift
//  CheloveCheck
//
//  Created by Sergey Ivanov on 05.01.2025.
//

import Foundation

final class KazakhtelecomOFDHandler: NSObject, URLSessionTaskDelegate, OFDHandler {
    func fetchCheck(from initialURL: URL, completion: @escaping (Result<Receipt, Error>) -> Void) {
        // Настройка сессии с делегатом
        print("Ссылка на чек: \(initialURL)")
        
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        
        var request = URLRequest(url: initialURL)
        request.httpMethod = "GET"
        
        // Добавил User-Agent
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/97.0.4692.71 Safari/537.36", forHTTPHeaderField: "User-Agent")
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Ошибка первого запроса: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Ошибка: Некорректный HTTP-ответ")
                completion(.failure(NSError(domain: "InvalidResponse", code: 0, userInfo: nil)))
                return
            }
            
            // Если ответ не JSON, то чек не найден
            guard let contentType = httpResponse.allHeaderFields["Content-Type"] as? String,
                  contentType.contains("application/json") else {
                completion(.failure(NSError(domain: "InvalidContentType", code: 0, userInfo: [NSLocalizedDescriptionKey: "Чек не найден!"])))
                return
            }
            
            // Если это успешный запрос (например, JSON при 200)
            if httpResponse.statusCode == 200 {
                guard let data = data else {
                    print("Ошибка: Нет данных в ответе")
                    
                    completion(.failure(NSError(domain: "NoData", code: 0, userInfo: nil)))
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        do {
                            // Преобразование JSON в Receipt
                            let receipt = try self.convertToReceipt(from: json, url: initialURL)
                            completion(.success(receipt))
                        } catch {
                            print("Ошибка конвертации JSON в Receipt: \(error.localizedDescription)")
                            completion(.failure(error))
                        }
                    } else {
                        print("Ошибка: Неверный формат JSON")
                        completion(.failure(NSError(domain: "InvalidJSON", code: 0, userInfo: nil)))
                    }
                } catch {
                    print("Ошибка парсинга JSON: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            } else {
                print("Ошибка: HTTP-код \(httpResponse.statusCode)")
                completion(.failure(NSError(domain: "HTTPError", code: httpResponse.statusCode, userInfo: nil)))
            }
        }
        task.resume()
    }

    // Обработка перенаправлений
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        print("Перенаправление: HTTP-код \(response.statusCode)")
        print("Заголовки редиректа: \(response.allHeaderFields)")

        // Если Location найден
        if let location = response.allHeaderFields["Location"] as? String {
            print("Найден Location: \(location)")
            
            // Формируем новый URL
            let baseAPIURL = "https://consumer.oofd.kz/api/tickets"
            guard let newURL = URL(string: baseAPIURL + location) else {
                print("Ошибка: Невозможно сформировать URL")
                completionHandler(nil)
                return
            }
            
            print("Сформированный новый URL: \(newURL)")
            
            // Создаем новый запрос
            var newRequest = URLRequest(url: newURL)
            newRequest.httpMethod = "GET"
            newRequest.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/97.0.4692.71 Safari/537.36", forHTTPHeaderField: "User-Agent")
            
            // Завершаем редирект с новым запросом
            completionHandler(newRequest)
        } else {
            print("Location отсутствует, продолжаем с оригинальным запросом")
            completionHandler(request)
        }
    }
    
    private func convertToReceipt(from json: [String: Any], url: URL) throws -> Receipt {
        var dateTime: Date
        
        guard let ticket = json["ticket"] as? [String: Any],
              let items = ticket["items"] as? [[String: Any]],
              let orgTitle = json["orgTitle"] as? String,
              let orgId = json["orgId"] as? String,
              let orgAddress = json["retailPlaceAddress"] as? String,
              let kkmSerialNumber = json["kkmSerialNumber"] as? String,
              let kkmFnsId = json["kkmFnsId"] as? String,
              let fiscalId = ticket["fiscalId"] as? String,
              let operationTypeID = ticket["operationType"] as? UInt,
              let payments = ticket["payments"] as? [[String: Any]],
              let totalSum = ticket["totalSum"] as? Double else {
            throw NSError(domain: "Invalid JSON structure", code: 1, userInfo: nil)
        }
        
        // Преобразуем `operationTypeID` в `OperationTypeEnum`
        guard let operationType = OperationTypeEnum(rawValue: UInt16(operationTypeID)) else {
            throw NSError(domain: "InvalidOperationType", code: 2, userInfo: [NSLocalizedDescriptionKey: "Неизвестный идентификатор операции: \(operationTypeID)"])
        }
        
        // Извлекаем дату из JSON
        guard let transactionDateString = ticket["transactionDate"] as? String else {
            throw NSError(domain: "InvalidTransactionDate", code: 3, userInfo: [NSLocalizedDescriptionKey: "Дата отсутствует в JSON"])
        }

        // Попробуем использовать ISO8601DateFormatter
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let transactionDate = iso8601Formatter.date(from: transactionDateString) {
            // Успешно распознано
            dateTime = transactionDate
        } else {
            // Попробуем резервный DateFormatter
            let fallbackFormatter = DateFormatter()
            fallbackFormatter.locale = Locale(identifier: "en_US_POSIX")
            fallbackFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
            fallbackFormatter.timeZone = TimeZone(identifier: "Asia/Almaty")

            guard let fallbackDate = fallbackFormatter.date(from: transactionDateString) else {
                throw NSError(
                    domain: "InvalidTransactionDate",
                    code: 3,
                    userInfo: [NSLocalizedDescriptionKey: "Некорректная дата: \(transactionDateString)"]
                )
            }
            dateTime = fallbackDate
        }


        let ofd = OfdEnum.kazakhtelecom
        
        let itemsArray = items.compactMap { item -> Item? in
            guard let commodity = item["commodity"] as? [String: Any],
                  let rawName = commodity["name"] as? String,
                  let quantity = commodity["quantity"] as? Double,
                  let price = commodity["price"] as? Double,
                  let sum = commodity["sum"] as? Double else {
                return nil
            }
            
            let name = rawName.replacingOccurrences(of: "\\r|\\n", with: "", options: .regularExpression)
            let barcode = commodity["barcode"] as? String
            let exciseStamp = commodity["exciseStamp"] as? String
            let measureUnitCodeRaw = commodity["measureUnitCode"] as? String
            let measureUnitCode = UnitOfMeasurementEnum(rawValue: measureUnitCodeRaw ?? "") ?? .unknown
            
            let taxData = (commodity["taxes"] as? [[String: Any]])?.first
            let taxType = (taxData?["layout"] as? [String: Any])?["rate"] as? Double
            let taxSum = taxData?["sum"] as? Double
            
            return Item(
                barcode: barcode,
                codeMark: exciseStamp,
                name: name,
                count: Double(quantity),
                price: price,
                unit: measureUnitCode,
                sum: sum,
                taxType: taxType != nil ? "\(taxType!)" : nil,
                taxSum: taxSum
            )
        }
        
        let taxes = json["taxes"] as? [[String: Any]]
        let taxsesType = taxes?.first?["rate"] as? Double
        let taxesSum = taxes?.first?["sum"] as? Double
        
        let takenSum = ticket["takenSum"] as? Double
        let changeSum = ticket["changeSum"] as? Double
        
        var totalType: [Payment] = []

        for payment in payments {
            guard let paymentTypeString = payment["paymentType"] as? String,
                  let sum = payment["sum"] as? Double else {
                throw NSError(
                    domain: "PaymentParsingError",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Некорректная структура платежа: \(payment)"]
                )
            }

            // Приведение к нижнему регистру и удаление пробелов
            let normalizedType = paymentTypeString.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

            // Преобразование строки в PaymentTypeEnum с использованием замыкания
            let paymentType: PaymentTypeEnum? = {
                switch normalizedType {
                case "card":
                    return .card
                case "cash":
                    return .cash
                case "mobile":
                    return .mobile
                default:
                    return nil
                }
            }()

            // Проверяем, что paymentType найден
            guard let validPaymentType = paymentType else {
                throw NSError(
                    domain: "PaymentTypeMappingError",
                    code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "Неизвестный тип оплаты: \(paymentTypeString)"]
                )
            }

            // Создание объекта Payment
            let paymentObject = Payment(type: validPaymentType, sum: sum)
            totalType.append(paymentObject)
        }


        return Receipt(
            companyName: orgTitle,
            certificateVAT: nil,
            iinBin: orgId,
            companyAddress: orgAddress,
            serialNumber: kkmSerialNumber,
            kgdId: kkmFnsId,
            dateTime: dateTime,
            fiscalSign: fiscalId,
            ofd: ofd,
            typeOperation: operationType,
            items: itemsArray,
            url: url.absoluteString,
            taxsesType: taxsesType != nil ? "\(taxsesType!)" : nil,
            taxesSum: taxesSum,
            taken: takenSum,
            change: changeSum,
            totalType: totalType,
            totalSum: totalSum
        )
    }
}
