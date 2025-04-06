//
//  ReceiptRepository.swift
//  CheloveCheck
//
//  Created by Sergey Ivanov on 10.01.2025.
//

import CoreData

final class ReceiptRepository: RepositoryProtocol {
    typealias DomainModel = Receipt

    private let context: NSManagedObjectContext
    static let shared = ReceiptRepository(context: CoreDataManager.shared.context)

    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func count(predicate: NSPredicate? = nil) throws -> Int {
        let request: NSFetchRequest<ReceiptEntity> = ReceiptEntity.fetchRequest()
        request.predicate = predicate
        
        return try context.count(for: request)
    }
    
    func fetch(request: FetchRequest, completion: @escaping ([Receipt]) -> Void) {
        context.perform {
            do {
                let fetchRequest: NSFetchRequest<ReceiptEntity> = ReceiptEntity.fetchRequest()
                fetchRequest.predicate = request.predicate
                fetchRequest.fetchOffset = request.offset
                fetchRequest.fetchLimit = request.limit
                fetchRequest.sortDescriptors = request.sortDescriptors
                
                let entities = try self.context.fetch(fetchRequest)
                let receipts = try entities.map { try $0.toDomainModel() }
                
                DispatchQueue.main.async {
                    completion(receipts)
                }
            } catch {
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
    }
    
    func fetchAll() throws -> [Receipt] {
        let request: NSFetchRequest<ReceiptEntity> = ReceiptEntity.fetchRequest()
        let entities = try context.fetch(request)
        return try entities.map { try $0.toDomainModel() }
    }
    
    func save(_ receipt: Receipt) throws {
        // Проверяем, существует ли уже чек с таким же фискальным признаком
        let fetchRequest: NSFetchRequest<ReceiptEntity> = ReceiptEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "fiscalSign == %@", receipt.fiscalSign)
        
        let existingReceipts = try context.fetch(fetchRequest)
        if !existingReceipts.isEmpty {
            throw NSError(domain: "CoreDataError", code: 133021, userInfo: [NSLocalizedDescriptionKey: "Чек уже найден и сохранен"])
        }

        // Преобразуем Receipt в ReceiptEntity
        _ = receipt.toEntity(context: context)

        // Сохраняем изменения
        if context.hasChanges {
            try context.save()
        }
    }
    
    func delete(_ receipt: Receipt) throws {
        let fetchRequest: NSFetchRequest<ReceiptEntity> = ReceiptEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "fiscalSign == %@", receipt.fiscalSign)

        let entities = try context.fetch(fetchRequest)
        guard !entities.isEmpty else {
            throw NSError(
                domain: "CoreDataError",
                code: NSManagedObjectValidationError,
                userInfo: [NSLocalizedDescriptionKey: "Чек с таким фискальным признаком не найден."]
            )
        }
        
        for entity in entities {
            context.delete(entity)
        }
        if context.hasChanges {
            try context.save()
        }
    }
    
    func deleteAll() throws {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = ReceiptEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        try context.execute(deleteRequest)
        try context.save()
    }
}
