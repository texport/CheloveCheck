//
//  OFDHandlerProtocol.swift
//  Tandau
//
//  Created by Sergey Ivanov on 05.01.2025.
//

import Foundation

protocol OFDHandler {
    func fetchCheck(from url: URL, completion: @escaping (Result<Receipt, Error>) -> Void)
}
