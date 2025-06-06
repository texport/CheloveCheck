//
//  CheckFilterProtocol.swift
//  CheloveCheck
//
//  Created by Sergey Ivanov on 03.03.2025.
//

protocol CheckFilterProtocol {
    var title: String { get }
    func apply(to request: inout FetchRequest)
}
