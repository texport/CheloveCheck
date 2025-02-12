//
//  RepositoryProtocol.swift
//  Tandau
//
//  Created by Sergey Ivanov on 10.01.2025.
//

import Foundation

protocol RepositoryProtocol {
    associatedtype DomainModel
    func fetchAll() throws -> [DomainModel]
    func fetch(predicate: NSPredicate?) throws -> [DomainModel]
    func save(_ object: DomainModel) throws
    func delete(_ object: DomainModel) throws
}
