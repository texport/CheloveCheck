//
//  LastWeekFilter.swift
//  CheloveCheck
//
//  Created by Sergey Ivanov on 03.03.2025.
//

import Foundation

struct LastWeekFilter: CheckFilterProtocol {
    var title: String { return "За неделю" }

    func apply(to request: inout FetchRequest) {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -7, to: Date())!

        request.predicate = NSPredicate(format: "dateTime >= %@", startDate as NSDate)
    }
}
