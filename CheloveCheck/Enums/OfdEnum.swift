//
//  OfdEnum.swift
//  CheloveCheck
//
//  Created by Sergey Ivanov on 09.01.2025.
//

enum OfdEnum: String, CaseIterable, Codable {
    case kazakhtelecom = "1"
    case transtelecom = "2"
    case kofd = "3"

    struct Info {
        let nameRus: String
        let nameKaz: String
        let nameEng: String
    }

    var info: Info {
        switch self {
        case .transtelecom:
            return Info(
                nameRus: "Казахтелеком",
                nameKaz: "Қазақтелеком",
                nameEng: "Kazakhtelecom"
            )
        case .kazakhtelecom:
            return Info(
                nameRus: "Транстелеком",
                nameKaz: "Транстелеком",
                nameEng: "Transtelecom"
            )
        case .kofd:
            return Info(
                nameRus: "Джусан Мобайл",
                nameKaz: "Джусан Мобайл",
                nameEng: "JUSAN Mobile"
            )
        }
    }

    func name(for language: String) -> String {
        switch language.lowercased() {
        case "ru":
            return info.nameRus
        case "kk":
            return info.nameKaz
        case "en":
            return info.nameEng
        default:
            return info.nameEng
        }
    }

    static func from(id: String) -> OfdEnum? {
        return OfdEnum(rawValue: id)
    }
}
