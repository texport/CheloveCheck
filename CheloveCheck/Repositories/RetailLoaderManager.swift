//
//  DataManager.swift
//  CheloveCheck
//
//  Created by Sergey Ivanov on 06.02.2025.
//

import Foundation
import CoreData

enum RetailLoaderError: Error {
    case jsonLoadingError
    case missingVersionKey
    case missingDataKey
    case coreDataError(Error)
}

final class RetailLoaderManager {
    static let shared = RetailLoaderManager()

    private init() {}

    // Загружаем JSON из ресурсов
    private func loadJSONFromBundle() throws -> [String: Any]? {
        guard let url = Bundle.main.url(forResource: "retails", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw RetailLoaderError.jsonLoadingError
        }
        return json
    }

    // Проверяем версию данных и обновляем при необходимости
    func preloadDataIfNeeded() throws {
        let savedVersion = UserDefaults.standard.string(forKey: "DataVersion") ?? "0.0"

        let json = try loadJSONFromBundle()

        guard let currentVersion = json?["version"] as? String else {
            throw RetailLoaderError.missingVersionKey
        }

        if currentVersion != savedVersion {
            if let dataArray = json?["data"] as? [[String: Any]] {
                try preloadData(json: dataArray)
                UserDefaults.standard.set(currentVersion, forKey: "DataVersion")
            } else {
                throw RetailLoaderError.missingDataKey
            }
        } else {
            print("Версия данных (\(savedVersion)) не изменилась. Обновление не требуется.")
        }
    }

    // Очистка базы и загрузка новых данных
    private func preloadData(json: [[String: Any]]) throws {
        let context = CoreDataManager.shared.context
        
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "RetailEntity")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {
            throw RetailLoaderError.coreDataError(error)
        }

        // Загружаем новые записи
        for item in json {
            let entry = RetailEntity(context: context)
            entry.networkName = item["networkName"] as? String
            entry.legalName = item["legalName"] as? String
            entry.bin = item["bin"] as? String
        }

        do {
            try context.save()
        } catch {
            throw RetailLoaderError.coreDataError(error)
        }
    }

    // Получение всех записей для отладки
    func fetchAllDirectories() throws {
        let context = CoreDataManager.shared.context
        let fetchRequest: NSFetchRequest<RetailEntity> = RetailEntity.fetchRequest()

        do {
            let results = try context.fetch(fetchRequest)
        } catch {
            throw RetailLoaderError.coreDataError(error)
        }
    }
}
