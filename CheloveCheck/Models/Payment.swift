//
//  Payment.swift
//  CheloveCheck
//
//  Created by Sergey Ivanov on 09.01.2025.
//

import CoreData

struct Payment {
    let type: PaymentTypeEnum
    let sum: Double
}

extension Payment {
    func toEntity(context: NSManagedObjectContext) -> PaymentEntity {
        let paymentEntity = PaymentEntity(context: context)
        paymentEntity.type = Int16(self.type.rawValue)
        paymentEntity.sum = self.sum
        return paymentEntity
    }
}

extension PaymentEntity {
    func toDomainModel() throws -> Payment {
        guard let paymentType = PaymentTypeEnum(rawValue: UInt16(self.type)) else {
            throw NSError(
                domain: "CoreDataError",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Неизвестный тип оплаты: \(self.type)"]
            )
        }

        return Payment(
            type: paymentType,
            sum: self.sum
        )
    }
}
