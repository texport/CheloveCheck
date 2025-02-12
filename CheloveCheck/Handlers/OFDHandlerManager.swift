//
//  OFDHandlerManager.swift
//  CheloveCheck
//
//  Created by Sergey Ivanov on 05.01.2025.
//

final class OFDHandlerManager {
    private var handlers: [String: OFDHandler] = [:]
    
    // Регистрация обработчиков
    init() {
        registerHandler(for: "consumer.oofd.kz", handler: KazakhtelecomOFDHandler())
        registerHandler(for: "ofd1.kz", handler: TranstelecomOFDHandler())
        registerHandler(for: "87.255.215.96", handler: TranstelecomOFDHandler())
        registerHandler(for: "consumer.kofd.kz", handler: JusanOFDHandler())
    }
    
    func registerHandler(for domain: String, handler: OFDHandler) {
        handlers[domain] = handler
    }
    
    func handler(for domain: String) -> OFDHandler? {
        return handlers[domain]
    }
}
