//
//  AllChecksFilter.swift
//  CheloveCheck
//
//  Created by Sergey Ivanov on 03.03.2025.
//

struct AllChecksFilter: CheckFilterProtocol {
    var title: String { return "Все" }

    func apply(to request: inout FetchRequest) {
        // Ничего не меняем, загружаем все чеки
    }
}
