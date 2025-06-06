//
//  FiltersManager.swift
//  CheloveCheck
//
//  Created by Sergey Ivanov on 03.03.2025.
//

import Foundation

protocol FiltersManagerDelegate: AnyObject {
    func didUpdateChecks(_ checks: [Receipt], append: Bool)
}

final class FiltersManager {
    private let repository: ReceiptRepository
    private(set) var activeFilter: CheckFilterProtocol
    private var currentOffset: Int = 0
    private let fetchLimit: Int = 50
    private var hasMoreData: Bool = true
    private var searchQuery: String? = nil
    private var searchDebounceWorkItem: DispatchWorkItem?
    var selectedDateFilter: DateFilter?
    weak var delegate: FiltersManagerDelegate?
    
    var availableFilters: [CheckFilterProtocol] {
        let filters: [CheckFilterProtocol] = [
            AllChecksFilter(),
            TodayFilter(),
            LastWeekFilter(),
            LastMonthFilter(),
            selectedDateFilter ?? PlaceholderDateFilter()
        ]
        return filters
    }
    
    init(repository: ReceiptRepository, defaultFilter: CheckFilterProtocol = AllChecksFilter()) {
        self.repository = repository
        self.activeFilter = defaultFilter
    }
    
    func applyFilter(_ filter: CheckFilterProtocol) {
        print("🔍 Устанавливаем фильтр: \(filter.title)")
        
        // Сохраняем фильтр, если он дата-фильтр
        if let dateFilter = filter as? DateFilter {
            selectedDateFilter = dateFilter
        } else if filter is PlaceholderDateFilter {
                return // Если "Выбрать дату", просто показываем пикер — ничего не делаем
        } else {
            // Сброс даты, если выбран любой другой фильтр
            selectedDateFilter = nil
            
        }
        
        activeFilter = filter
        searchQuery = nil
        delegate?.didUpdateChecks([], append: false)
        resetPagination()
        fetchNextPage()
    }

    func applyDateFilter(for date: Date) {
        let dateFilter = DateFilter(date: date)
        selectedDateFilter = dateFilter
        print("📅 Применён фильтр даты: \(dateFilter.title)")
        applyFilter(dateFilter)
    }
    
    func clearDateFilter() {
        selectedDateFilter = nil
        applyFilter(AllChecksFilter())
    }
    
    func applySearch(_ query: String?) {
        // Отменяем предыдущую задачу, если пользователь быстро печатает
        searchDebounceWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.searchQuery = query
            self.delegate?.didUpdateChecks([], append: false)
            self.resetPagination()
            self.fetchNextPage()
        }
        
        // Сохраняем, чтобы можно было отменить
        searchDebounceWorkItem = workItem
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: workItem)
    }
    
    func fetchNextPage() {
        guard hasMoreData else { return }

        var request = FetchRequest(offset: currentOffset, limit: fetchLimit)
        activeFilter.apply(to: &request)
        request.searchQuery = searchQuery
        request.addSearchPredicate()

        repository.fetch(request: request) { [weak self] results in
            guard let self = self else { return }

            if results.isEmpty {
                self.hasMoreData = false
                return
            }

            self.currentOffset += results.count
            self.hasMoreData = results.count == self.fetchLimit // Если загрузили меньше лимита, значит, данных больше нет
            
            self.delegate?.didUpdateChecks(results, append: self.currentOffset > results.count)
        }
    }
    
    func refreshCurrentFilter() {
        resetPagination()
        fetchNextPage()
    }
    
    func resetAll() {
        searchQuery = nil
        selectedDateFilter = nil
        activeFilter = AllChecksFilter()
        resetPagination()
    }
    
    private func resetPagination() {
        currentOffset = 0
        hasMoreData = true
    }
}
