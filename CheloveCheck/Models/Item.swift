//
//  Item.swift
//  CheloveCheck
//
//  Created by Sergey Ivanov on 06.01.2025.
//

import CoreData

struct Item: Codable {
    let barcode: String?
    let codeMark: String?
    let name: String
    let count: Double
    let price: Double
    let unit: UnitOfMeasurementEnum
    let sum: Double
    let taxType: String?
    let taxSum: Double?
}

extension Item {
    func toEntity(context: NSManagedObjectContext) -> ItemEntity {
        let itemEntity = ItemEntity(context: context)
        itemEntity.barcode = self.barcode
        itemEntity.codeMark = self.codeMark
        itemEntity.name = self.name
        itemEntity.count = self.count
        itemEntity.price = self.price
        itemEntity.unit = self.unit.rawValue
        itemEntity.sum = self.sum
        itemEntity.taxType = self.taxType
        itemEntity.taxSum = self.taxSum ?? 0.0
        return itemEntity
    }
}

extension ItemEntity {
    func toDomainModel() -> Item {
        let unit = UnitOfMeasurementEnum(rawValue: self.unit ?? "") ?? .unknown

        return Item(
            barcode: self.barcode,
            codeMark: self.codeMark,
            name: self.name ?? "Unknown Item",
            count: self.count,
            price: self.price,
            unit: unit,
            sum: self.sum,
            taxType: self.taxType,
            taxSum: self.taxSum
        )
    }
}

