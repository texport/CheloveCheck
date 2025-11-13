//
//  KazakhtelecomOFDHandler.swift
//  CheloveCheck
//
//  Created by Sergey Ivanov on 05.01.2025.
//

import Foundation

final class KazakhtelecomOFDHandler: NSObject, URLSessionTaskDelegate, OFDHandler {
    private enum Constants {
        static let baseApiUrl = "https://consumer.oofd.kz/api/tickets/get-by-url"
        static let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/97.0.4692.71 Safari/537.36"
        static let maxResponseSize = 10 * 1024 * 1024 // 10 MB
        static let requestTimeout: TimeInterval = 30
    }
    
    private enum ApiError: Error {
        case invalidUrl
        case invalidResponse
        case invalidContentType
        case noData
        case invalidJson
        case httpError(Int)
        case responseTooLarge
        case requestCancelled
        case sslError
        
        var localizedDescription: String {
            switch self {
            case .invalidUrl:
                return "Некорректный URL"
            case .invalidResponse:
                return "Некорректный ответ от сервера"
            case .invalidContentType:
                return "Чек не найден!"
            case .noData:
                return "Нет данных в ответе"
            case .invalidJson:
                return "Неверный формат JSON"
            case .httpError(let code):
                return "Ошибка HTTP: \(code)"
            case .responseTooLarge:
                return "Размер ответа превышает допустимый"
            case .requestCancelled:
                return "Запрос был отменен"
            case .sslError:
                return "Ошибка SSL/TLS"
            }
        }
    }
    
    private var session: URLSession?
    private var currentTask: URLSessionDataTask?
    
    deinit {
        session?.invalidateAndCancel()
        session = nil
    }
    
    private func setupSession() -> URLSession {
        if let existingSession = session {
            return existingSession
        }
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = Constants.requestTimeout
        sessionConfig.timeoutIntervalForResource = Constants.requestTimeout
        sessionConfig.waitsForConnectivity = true
        
        let newSession = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: .main)
        session = newSession
        return newSession
    }
    
    func fetchCheck(from initialURL: URL, completion: @escaping (Result<Receipt, Error>) -> Void) {
        print("Ссылка на чек: \(initialURL)")
        
        // Отменяем предыдущий запрос, если он есть
        currentTask?.cancel()
        
        do {
            let apiURL = try createApiUrl(from: initialURL)
            print("API URL: \(apiURL)")
            
            let request = createRequest(for: apiURL)
            performRequest(request, initialURL: initialURL, completion: completion)
        } catch {
            print("Ошибка при создании API URL: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
    
    private func createApiUrl(from initialURL: URL) throws -> URL {
        let params = try extractParams(from: initialURL)
        print("Извлеченные параметры: \(params)")
        return try buildApiUrl(with: params)
    }
    
    private func extractParams(from url: URL) throws -> [String: String] {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            print("Ошибка: не удалось извлечь параметры из URL: \(url)")
            throw ApiError.invalidUrl
        }
        
        let params = Dictionary(uniqueKeysWithValues: queryItems.map { ($0.name, $0.value ?? "") })
        print("Параметры из URL: \(params)")
        return params
    }
    
    private func buildApiUrl(with params: [String: String]) throws -> URL {
        var components = URLComponents(string: Constants.baseApiUrl)!
        
        let queryItems = [
            URLQueryItem(name: "t", value: params["t"]),
            URLQueryItem(name: "i", value: params["i"]),
            URLQueryItem(name: "f", value: params["f"]),
            URLQueryItem(name: "s", value: params["s"])
        ].compactMap { $0 }
        
        print("Query items для API URL: \(queryItems)")
        components.queryItems = queryItems
        
        guard let apiURL = components.url else {
            print("Ошибка: не удалось создать API URL")
            throw ApiError.invalidUrl
        }
        
        return apiURL
    }
    
    private func createRequest(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(Constants.userAgent, forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 30
        return request
    }
    
    private func performRequest(_ request: URLRequest, initialURL: URL, completion: @escaping (Result<Receipt, Error>) -> Void) {
        print("Начинаем выполнение запроса к URL: \(request.url?.absoluteString ?? "")")
        
        let session = setupSession()
        
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error as NSError? {
                if error.code == NSURLErrorCancelled {
                    print("Запрос был отменен")
                    completion(.failure(ApiError.requestCancelled))
                } else {
                    print("Ошибка сетевого запроса: \(error.localizedDescription)")
                    completion(.failure(error))
                }
                return
            }
            
            print("Получен ответ от сервера")
            
            do {
                let receipt = try self.handleResponse(data: data, response: response, initialURL: initialURL)
                print("Успешно создан Receipt")
                completion(.success(receipt))
            } catch let apiError as ApiError {
                print("Ошибка API: \(apiError.localizedDescription)")
                completion(.failure(apiError))
            } catch {
                print("Неизвестная ошибка: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        
        currentTask = task
        print("Запускаем задачу")
        task.resume()
    }
    
    // MARK: - URLSessionTaskDelegate
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        print("Получен SSL/TLS challenge")
        
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let serverTrust = challenge.protectionSpace.serverTrust {
                // Проверяем валидность сертификата
                var result: SecTrustResultType = .invalid
                let status = SecTrustEvaluate(serverTrust, &result)
                
                if status == errSecSuccess && (result == .proceed || result == .unspecified) {
                    let credential = URLCredential(trust: serverTrust)
                    completionHandler(.useCredential, credential)
                    return
                }
            }
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        completionHandler(.performDefaultHandling, nil)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        print("Получен редирект на: \(request.url?.absoluteString ?? "")")
        completionHandler(request)
    }
    
    private func handleResponse(data: Data?, response: URLResponse?, initialURL: URL) throws -> Receipt {
        print("Начинаем обработку ответа")
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("Ошибка: ответ не является HTTP ответом")
            throw ApiError.invalidResponse
        }
        
        print("HTTP статус код: \(httpResponse.statusCode)")
        print("HTTP заголовки: \(httpResponse.allHeaderFields)")
        
        guard httpResponse.statusCode == 200 else {
            print("Ошибка: HTTP код \(httpResponse.statusCode)")
            throw ApiError.httpError(httpResponse.statusCode)
        }
        
        guard let data = data else {
            print("Ошибка: нет данных в ответе")
            throw ApiError.noData
        }
        
        // Проверяем размер данных
        guard data.count <= Constants.maxResponseSize else {
            print("Ошибка: размер ответа превышает допустимый (\(data.count) байт)")
            throw ApiError.responseTooLarge
        }
        
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Полученный JSON: \(jsonString)")
        }
        
        if let contentType = httpResponse.allHeaderFields["Content-Type"] as? String {
            print("Content-Type: \(contentType)")
            guard contentType.contains("application/json") else {
                print("Ошибка: неверный Content-Type: \(contentType)")
                throw ApiError.invalidContentType
            }
        } else {
            print("Content-Type отсутствует в заголовках")
        }
        
        return try parseResponse(data: data, initialURL: initialURL)
    }
    
    private func parseResponse(data: Data, initialURL: URL) throws -> Receipt {
        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            print("Ошибка: не удалось распарсить JSON")
            throw ApiError.invalidJson
        }
        
        return try convertToReceipt(from: json, url: initialURL)
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
