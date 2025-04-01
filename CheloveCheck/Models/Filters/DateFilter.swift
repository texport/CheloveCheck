//
//  DateFilter.swift
//  CheloveCheck
//
//  Created by Sergey Ivanov on 03.03.2025.
//

import Foundation

struct DateFilter: CheckFilterProtocol {
    let date: Date

    var title: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        formatter.timeZone = TimeZone.current // Оставляем локальную зону только для отображения
        return formatter.string(from: date)
    }

    func apply(to request: inout FetchRequest) {
        let calendar = Calendar.current

        // Берём локальное начало дня
        let localStartOfDay = calendar.startOfDay(for: date)
        guard let localEndOfDay = calendar.date(byAdding: .day, value: 1, to: localStartOfDay)?.addingTimeInterval(-1) else {
            print("❌ Ошибка: не удалось вычислить конец дня")
            return
        }

        request.predicate = NSPredicate(
            format: "dateTime >= %@ AND dateTime <= %@",
            localStartOfDay as NSDate, localEndOfDay as NSDate
        )

        print("⏳ Фильтруем чеки (локально) с \(localStartOfDay) по \(localEndOfDay)")
    }
}

struct PlaceholderDateFilter: CheckFilterProtocol {
    var title: String { return "Выбрать дату" }
    
    func apply(to request: inout FetchRequest) {
        // Пока нет выбранной даты, фильтр не меняет запрос
    }
}
