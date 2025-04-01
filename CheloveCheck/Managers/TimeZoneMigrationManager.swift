//
//  TimeZoneMigrationManager.swift
//  CheloveCheck
//
//  Created by Sergey Ivanov on 01.04.2025.
//

import CoreData

enum TimeZoneMigrationError: Error, LocalizedError {
    case contextFetchFailed(Error)
    case contextSaveFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .contextFetchFailed(let underlying):
            return "Ошибка при загрузке чеков из базы: \(underlying.localizedDescription)"
        case .contextSaveFailed(let underlying):
            return "Ошибка при сохранении изменений в базе: \(underlying.localizedDescription)"
        }
    }
}

final class TimeZoneMigrationManager {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func runMigrationIfNeeded() throws {
        // Проверяем, не мигрировали ли уже
        let didMigrate = UserDefaults.standard.bool(forKey: "DidFixTZinV1_6_0")
        guard !didMigrate else {
            print("[TZMigration] Миграция уже выполнялась ранее, повторять не нужно.")
            return
        }
        
        print("[TZMigration] Миграция ещё не выполнялась — запускаем процесс.")
        
        do {
            try migrateAllReceipts()
            print("[TZMigration] Миграция успешно выполнена.")
        } catch {
            print("[TZMigration] Миграция не удалась: \(error.localizedDescription)")
            throw error
        }
        
        // Если дошли сюда — миграция успешна
        UserDefaults.standard.set(true, forKey: "DidFixTZinV1_6_0")
    }
    
    private func migrateAllReceipts() throws {
        // Загружаем все ReceiptEntity
        let fetchRequest: NSFetchRequest<ReceiptEntity> = ReceiptEntity.fetchRequest()
        let allReceipts: [ReceiptEntity]
        
        do {
            allReceipts = try context.fetch(fetchRequest)
        } catch {
            throw TimeZoneMigrationError.contextFetchFailed(error)
        }
        
        // Если нет чеков, менять нечего
        guard !allReceipts.isEmpty else {
            print("[TZMigration] Нет чеков в базе, миграция не требуется.")
            return
        }
        
        print("[TZMigration] Найдено \(allReceipts.count) чек(ов). Сдвигаем дату у каждого (пример: -5 часов).")
        
        // Сдвигаем дату. Допустим, нужно отнять 5 часов.
        for receiptEntity in allReceipts {
            guard let oldDate = receiptEntity.dateTime else { continue }
            
            // Пример: “-5 hours”
            let newDate = oldDate.addingTimeInterval(-5 * 3600)
            receiptEntity.dateTime = newDate
        }
        
        // Сохраняем изменения, если есть
        guard context.hasChanges else { return }
        do {
            try context.save()
            print("[TZMigration] Изменения сохранены в Core Data.")
        } catch {
            throw TimeZoneMigrationError.contextSaveFailed(error)
        }
    }
}
