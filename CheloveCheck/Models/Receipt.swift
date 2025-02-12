//
//  Ticket.swift
//  Tandau
//
//  Created by Sergey Ivanov on 05.01.2025.
//

import Foundation
import CoreData

struct Receipt {
    /// Шапка чека
    let companyName: String
    let certificateVAT: String?
    let iinBin: String
    let companyAddress: String
    let serialNumber: String
    let kgdId: String
    
    /// О чеке и ОФД
    let dateTime: Date
    let fiscalSign: String
    let ofd: OfdEnum
    
    /// Тело чека
    let typeOperation: OperationTypeEnum
    let items: [Item]
    let url: String
    
    /// Налоги
    let taxsesType: String?
    let taxesSum: Double?
    
    /// Итоги
    let taken: Double?
    let change: Double?
    let totalType: [Payment]
    let totalSum: Double
}

extension Receipt {
    func toEntity(context: NSManagedObjectContext) -> ReceiptEntity {
        let receiptEntity = ReceiptEntity(context: context)
        receiptEntity.companyName = self.companyName
        receiptEntity.certificateVAT = self.certificateVAT
        receiptEntity.iinBin = self.iinBin
        receiptEntity.companyAddress = self.companyAddress
        receiptEntity.serialNumber = self.serialNumber
        receiptEntity.kgdId = self.kgdId
        receiptEntity.dateTime = self.dateTime
        receiptEntity.fiscalSign = self.fiscalSign
        receiptEntity.ofd = self.ofd.rawValue
        receiptEntity.typeOperation = Int16(self.typeOperation.rawValue)
        receiptEntity.url = self.url
        receiptEntity.taken = self.taken ?? 0.0
        receiptEntity.change = self.change ?? 0.0
        receiptEntity.totalSum = self.totalSum

        // Преобразуем `Item` и связываем
        self.items.forEach { item in
            let itemEntity = item.toEntity(context: context)
            itemEntity.receipt = receiptEntity
        }

        // Преобразуем `Payment` и связываем
        self.totalType.forEach { payment in
            let paymentEntity = payment.toEntity(context: context)
            paymentEntity.receipt = receiptEntity
        }

        return receiptEntity
    }
}

extension ReceiptEntity {
    func toDomainModel() throws -> Receipt {
        // Преобразуем связанные `ItemEntity` в `Item`
        let items: [Item] = (self.items?.allObjects as? [ItemEntity])?.compactMap { itemEntity in
            itemEntity.toDomainModel()
        } ?? []

        // Преобразуем связанные `PaymentEntity` в `Payment`
        let totalType: [Payment] = try (self.payments?.allObjects as? [PaymentEntity])?.compactMap { paymentEntity in
            try paymentEntity.toDomainModel()
        } ?? []

        // Проверяем необходимые поля
        guard let companyName = self.companyName,
              let iinBin = self.iinBin,
              let companyAddress = self.companyAddress,
              let serialNumber = self.serialNumber,
              let kgdId = self.kgdId,
              let fiscalSign = self.fiscalSign,
              let ofdRaw = self.ofd,
              let ofd = OfdEnum(rawValue: ofdRaw),
              let typeOperation = OperationTypeEnum(rawValue: UInt16(self.typeOperation)),
              let url = self.url,
              let dateTime = self.dateTime else {
            throw NSError(domain: "CoreDataError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Некоторые обязательные поля отсутствуют в ReceiptEntity"])
        }

        // Возвращаем Receipt
        return Receipt(
            companyName: companyName,
            certificateVAT: self.certificateVAT,
            iinBin: iinBin,
            companyAddress: companyAddress,
            serialNumber: serialNumber,
            kgdId: kgdId,
            dateTime: dateTime,
            fiscalSign: fiscalSign,
            ofd: ofd,
            typeOperation: typeOperation,
            items: items,
            url: url,
            taxsesType: self.taxsesType,
            taxesSum: self.taxesSum,
            taken: self.taken,
            change: self.change,
            totalType: totalType,
            totalSum: self.totalSum
        )
    }
}
