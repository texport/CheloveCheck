//
//  errorExtension.swift
//  CheloveCheck
//
//  Created by Sergey Ivanov on 07.01.2025.
//

import Foundation

extension Error {
    var detailedDescription: String {
        if let localizedError = self as? LocalizedError, let description = localizedError.errorDescription {
            return description
        }
        return self.localizedDescription
    }
}
