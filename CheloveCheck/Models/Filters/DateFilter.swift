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
        
        // Конец дня — 23:59:59
        guard let localEndOfDay = calendar.date(byAdding: .day, value: 1, to: localStartOfDay)?.addingTimeInterval(-1) else {
            return
        }

        // Применяем предикат
        request.predicate = NSPredicate(
            format: "dateTime >= %@ AND dateTime <= %@",
            localStartOfDay as NSDate, localEndOfDay as NSDate
        )

        // Форматируем дату для логов
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZZ"
        formatter.timeZone = TimeZone.current

        let startStr = formatter.string(from: localStartOfDay)
        let endStr = formatter.string(from: localEndOfDay)

        print("⏳ Фильтруем чеки (локально) с \(startStr) по \(endStr)")
    }
}

struct PlaceholderDateFilter: CheckFilterProtocol {
    var title: String { return "Выбрать дату" }
    
    func apply(to request: inout FetchRequest) {
        // Пока нет выбранной даты, фильтр не меняет запрос
    }
}
