//
//  TodayFilter.swift
//  CheloveCheck
//
//  Created by Sergey Ivanov on 06.04.2025.
//

import Foundation

struct TodayFilter: CheckFilterProtocol {
    var title: String { return "За сегодня" }

    func apply(to request: inout FetchRequest) {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)

        request.predicate = NSPredicate(format: "dateTime >= %@", startOfDay as NSDate)
    }
}

