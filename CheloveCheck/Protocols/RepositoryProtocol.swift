//
//  RepositoryProtocol.swift
//  CheloveCheck
//
//  Created by Sergey Ivanov on 10.01.2025.
//

import Foundation

protocol RepositoryProtocol {
    associatedtype DomainModel
    func fetchAll() throws -> [DomainModel]
    func fetch(request: FetchRequest, completion: @escaping ([DomainModel]) -> Void)
    func save(_ object: DomainModel) throws
    func delete(_ object: DomainModel) throws
}
