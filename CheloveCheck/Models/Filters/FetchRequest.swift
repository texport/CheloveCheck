//
//  FetchRequest.swift
//  CheloveCheck
//
//  Created by Sergey Ivanov on 03.03.2025.
//

import CoreData

struct FetchRequest {
    var predicate: NSPredicate? = nil
    var offset: Int = 0
    var limit: Int = 50
    var sortDescriptors: [NSSortDescriptor] = [NSSortDescriptor(key: "dateTime", ascending: false)]
    var searchQuery: String? = nil

    mutating func addSearchPredicate() {
        guard let query = searchQuery, !query.isEmpty else { return }

        let searchPredicates: [NSPredicate] = [
            NSPredicate(format: "companyName CONTAINS[cd] %@", query),
            NSPredicate(format: "fiscalSign CONTAINS[cd] %@", query),
            NSPredicate(format: "ANY items.name CONTAINS[cd] %@", query)
        ]
        
        let compoundSearchPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: searchPredicates)
        
        if let existingPredicate = predicate {
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [existingPredicate, compoundSearchPredicate])
        } else {
            predicate = compoundSearchPredicate
        }
    }
}
