//
//  CoreDataManager.swift
//  CheloveCheck
//
//  Created by Sergey Ivanov on 09.01.2025.
//

import CoreData

final class CoreDataManager {
    static let shared: CoreDataManager = {
        do {
            return try CoreDataManager()
        } catch {
            fatalError("Не удалось инициализировать CoreDataManager: \(error.localizedDescription)")
        }
    }()

    private let persistentContainer: NSPersistentContainer

    private init() throws {
        persistentContainer = NSPersistentContainer(name: "database")
        var persistentStoreLoadError: Error?
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                persistentStoreLoadError = error
            }
        }
        if let error = persistentStoreLoadError {
            throw error
        }
    }

    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    func saveContext() throws {
        if context.hasChanges {
            try context.save()
        }
    }
}
