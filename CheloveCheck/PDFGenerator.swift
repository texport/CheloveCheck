//
//  PDFGenerator.swift
//  Tandau
//
//  Created by Sergey Ivanov on 07.01.2025.
//

//import UIKit
//import PDFKit
//
//final class PDFGenerator {
//    static func generatePDF(from receipt: Receipt) -> Data {
//        let pageWidth: CGFloat = 226.8
//        let pageHeight: CGFloat = 1000.0
//        let margin: CGFloat = 10
//        var currentY: CGFloat = margin
//        
//        let pdfMetaData = [
//            kCGPDFContextCreator: "Tandau App",
//            kCGPDFContextAuthor: "Sergey Ivanov",
//            kCGPDFContextTitle: ""
//        ]
//        
//        // Начало страницы
//        let pdfData = NSMutableData()
//        UIGraphicsBeginPDFContextToData(pdfData, CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), pdfMetaData)
//        UIGraphicsBeginPDFPage()
//        let context = UIGraphicsGetCurrentContext()
//        
//        let drawText: (String, CGRect, UIFont) -> CGFloat = { text, rect, font in
//            let paragraphStyle = NSMutableParagraphStyle()
//            paragraphStyle.alignment = .left
//            
//            let attributes: [NSAttributedString.Key: Any] = [
//                .font: font,
//                .paragraphStyle: paragraphStyle,
//                .foregroundColor: UIColor.black
//            ]
//            
//            let boundingRect = (text as NSString).boundingRect(
//                with: CGSize(width: rect.width, height: CGFloat.greatestFiniteMagnitude),
//                options: .usesLineFragmentOrigin,
//                attributes: attributes,
//                context: nil
//            )
//            
//            (text as NSString).draw(
//                with: CGRect(x: rect.origin.x, y: rect.origin.y, width: rect.width, height: boundingRect.height),
//                options: .usesLineFragmentOrigin,
//                attributes: attributes,
//                context: nil
//            )
//            return boundingRect.height
//        }
//        
//        // Шапка чека
//        let titleFont = UIFont.boldSystemFont(ofSize: 8)
//        let detailFont = UIFont.systemFont(ofSize: 8)
//        
//        // Отрисовка шапки чека
//        currentY += drawDashedLine(context: context, y: currentY, pageWidth: pageWidth)
//        currentY += drawText(receipt.companyName, CGRect(x: margin, y: currentY, width: pageWidth - 2 * margin, height: CGFloat.greatestFiniteMagnitude), titleFont)
//        currentY += drawText("Адрес: \(receipt.companyAddress)", CGRect(x: margin, y: currentY, width: pageWidth - 2 * margin, height: CGFloat.greatestFiniteMagnitude), detailFont)
//        currentY += drawText("ИИН/БИН: \(receipt.iinBin)", CGRect(x: margin, y: currentY, width: pageWidth - 2 * margin, height: CGFloat.greatestFiniteMagnitude), detailFont)
//        currentY += 10
//        currentY += drawDashedLine(context: context, y: currentY, pageWidth: pageWidth)
//        
//        currentY += drawAlignedText(prefixText: "", leftText: receipt.typeOperation.description(in: "ru"),
//                                    rightText: "",
//                                    leftFont: UIFont.boldSystemFont(ofSize: 14),
//                                    rightFont: UIFont.boldSystemFont(ofSize: 10),
//                                    leftColor: .black,
//                                    rightColor: .black,
//                                    margin: margin,
//                                    y: currentY,
//                                    pageWidth: pageWidth)
//        
//        // Форматирование даты
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "dd.MM.yyyy, HH:mm"
//        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
//        dateFormatter.locale = Locale(identifier: "ru_RU")
//        let formattedDate = dateFormatter.string(from: receipt.dateTime)
//
//        // Добавляем отрисовку форматированной даты
//        currentY += drawText("Дата и время: \(formattedDate)",
//                             CGRect(x: margin, y: currentY, width: pageWidth - 2 * margin, height: CGFloat.greatestFiniteMagnitude),
//                             titleFont)
//
//        currentY += 10
//        currentY += drawDashedLine(context: context, y: currentY, pageWidth: pageWidth)
//        
//        // Позиции товаров
//        currentY += drawText("Список товаров", CGRect(x: margin, y: currentY, width: pageWidth - 2 * margin, height: CGFloat.greatestFiniteMagnitude), titleFont)
//        currentY += 10
//        var itemIndex = 1
//        for item in receipt.items {
//            // Рисуем название товара
//            currentY += drawText("\(itemIndex). \(item.name)",
//                                 CGRect(x: margin, y: currentY, width: pageWidth - 2 * margin, height: CGFloat.greatestFiniteMagnitude),
//                                 detailFont)
//            
//            let unitEnum = item.unit
//            let unit: String
//
//            if unitEnum == .unknown {
//                unit = ""
//            } else {
//                unit = unitEnum.info.shortRus
//            }
//
//            let itemDetails: String
//            if unit.isEmpty {
//                itemDetails = "\(formatNumberCount(item.count)) x \(String(format: "%.2f", item.price))"
//            } else {
//                itemDetails = "\(formatNumberCount(item.count)) \(unit) x \(String(format: "%.2f", item.price))"
//            }
//
//            currentY += drawAlignedText(prefixText: "", leftText: itemDetails,
//                                        rightText: formatNumber(item.sum),
//                                        leftFont: detailFont,
//                                        rightFont: UIFont.boldSystemFont(ofSize: 10),
//                                        leftColor: .black,
//                                        rightColor: .black,
//                                        margin: margin,
//                                        y: currentY,
//                                        pageWidth: pageWidth)
//            
//            currentY += 10
//            itemIndex += 1
//        }
//        
//        currentY += drawDashedLine(context: context, y: currentY, pageWidth: pageWidth)
//        
//        // Итоги
//        currentY += drawAlignedText(prefixText: "", leftText: "ИТОГО",
//                                    rightText: formatNumber(receipt.totalSum),
//                                    leftFont: UIFont.boldSystemFont(ofSize: 14),
//                                    rightFont: UIFont.boldSystemFont(ofSize: 14),
//                                    leftColor: .black,
//                                    rightColor: .black,
//                                    margin: margin,
//                                    y: currentY,
//                                    pageWidth: pageWidth)
//        
//        for payment in receipt.totalType {
//            currentY += drawAlignedText(prefixText: "", leftText: payment.type.description(in: "ru"),
//                                        rightText: formatNumber(payment.sum),
//                                        leftFont: detailFont,
//                                        rightFont: UIFont.boldSystemFont(ofSize: 8),
//                                        leftColor: .black,
//                                        rightColor: .black,
//                                        margin: margin,
//                                        y: currentY,
//                                        pageWidth: pageWidth)
//        }
//        
//        if let taken = receipt.taken, taken > 0 {
//            currentY += drawAlignedText(prefixText: "", leftText: "Принято наличными",
//                                        rightText: formatNumber(taken),
//                                        leftFont: detailFont,
//                                        rightFont: UIFont.boldSystemFont(ofSize: 8),
//                                        leftColor: .black,
//                                        rightColor: .black,
//                                        margin: margin,
//                                        y: currentY,
//                                        pageWidth: pageWidth)
//        }
//        
//        if let change = receipt.change, change > 0 {
//            currentY += drawAlignedText(prefixText: "", leftText: "Сдача",
//                                        rightText: formatNumber(change),
//                                        leftFont: UIFont.boldSystemFont(ofSize: 8),
//                                        rightFont: UIFont.boldSystemFont(ofSize: 8),
//                                        leftColor: .black,
//                                        rightColor: .black,
//                                        margin: margin,
//                                        y: currentY,
//                                        pageWidth: pageWidth)
//        }
//        
//        currentY += 10
//        currentY += drawDashedLine(context: context, y: currentY, pageWidth: pageWidth)
//        
//        // QR-код
//        let qrRect = drawQRCodeAndText(
//            "Если нужен фискальный чек, нажмите на QR код.",
//            url: receipt.url,
//            currentY: &currentY,
//            pageWidth: pageWidth,
//            margin: margin,
//            pdfData: pdfData
//        )
//        
//        currentY += drawDashedLine(context: context, y: currentY, pageWidth: pageWidth)
//        
//        UIGraphicsEndPDFContext()
//        
//        let generatedPDF = pdfData as Data
//        
//        guard let pdfDocument = PDFDocument(data: generatedPDF),
//              let firstPage = pdfDocument.page(at: 0) else {
//            return generatedPDF
//        }
//        
//        let pageBounds = firstPage.bounds(for: .mediaBox)
//        let invertedY = pageBounds.height - qrRect.origin.y - qrRect.height
//        let annotationRect = CGRect(
//            x: qrRect.origin.x,
//            y: invertedY,
//            width: qrRect.width,
//            height: qrRect.height
//        )
//        
//        let linkAnnotation = PDFAnnotation(
//            bounds: annotationRect,
//            forType: .link,
//            withProperties: nil
//        )
//        linkAnnotation.url = URL(string: receipt.url)
//        firstPage.addAnnotation(linkAnnotation)
//        
//        // 5) Формируем новое Data
//        if let modifiedPDF = pdfDocument.dataRepresentation() {
//            return modifiedPDF
//        }
//        return generatedPDF
//    }
//
//    private static func drawDashedLine(context: CGContext?, y: CGFloat, pageWidth: CGFloat) -> CGFloat {
//        guard let context = context else { return 0 }
//        context.setLineWidth(1)
//        context.setStrokeColor(UIColor.lightGray.cgColor)
//        let dash: [CGFloat] = [1, 2]
//        context.setLineDash(phase: 0, lengths: dash)
//        context.move(to: CGPoint(x: 10, y: y))
//        context.addLine(to: CGPoint(x: pageWidth - 10, y: y))
//        context.strokePath()
//        return 10
//    }
//
//    // MARK: Рисует QR КОД
//    private static func drawQRCodeAndText(
//        _ text: String,
//        url: String,
//        currentY: inout CGFloat,
//        pageWidth: CGFloat,
//        margin: CGFloat,
//        pdfData: NSMutableData
//    ) -> CGRect {
//        let qrCodeSize: CGFloat = 100
//        let qrCodeMargin: CGFloat = 1
//
//        // Рассчитаем координаты для QR-кода
//        let qrRect = CGRect(x: (pageWidth - qrCodeSize) / 2,
//                            y: currentY,
//                            width: qrCodeSize,
//                            height: qrCodeSize)
//
//        // Если QR-код не помещается, начнем новую страницу
//        if currentY + qrCodeMargin + qrCodeSize + 20 > 1000 {
//            UIGraphicsBeginPDFPage()
//            // При этом вы можете менять страницу (если нужно),
//            // но для простоты, допустим всё на одной.
//            currentY = margin
//        }
//
//        if let qrImage = generateQRCode(from: url) {
//            qrImage.draw(in: qrRect) // Отрисовка QR-кода
//        }
//
//        currentY += qrCodeSize + qrCodeMargin
//
//        let linkFont = UIFont.systemFont(ofSize: 8)
//        let paragraphStyle = NSMutableParagraphStyle()
//        paragraphStyle.alignment = .center
//
//        let normalAttributes: [NSAttributedString.Key: Any] = [
//            .font: linkFont,
//            .paragraphStyle: paragraphStyle,
//            .foregroundColor: UIColor.black
//        ]
//        let attributedText = NSAttributedString(string: text, attributes: normalAttributes)
//
//        // Определяем максимально доступную ширину между полями.
//        let textRectMax = CGRect(x: margin,
//                                 y: currentY,
//                                 width: pageWidth - 2 * margin,
//                                 height: CGFloat.greatestFiniteMagnitude)
//
//        let boundingRect = attributedText.boundingRect(
//            with: textRectMax.size,
//            options: .usesLineFragmentOrigin,
//            context: nil
//        )
//
//        // Проверим, помещается ли текст
//        if currentY + boundingRect.height > 1000 {
//            UIGraphicsBeginPDFPage()
//            currentY = margin
//        }
//
//        // Рисуем текст в ширине (pageWidth - 2 * margin), с центровкой
//        let finalTextRect = CGRect(
//            x: margin,
//            y: currentY,
//            width: pageWidth - 2 * margin,
//            height: boundingRect.height
//        )
//        attributedText.draw(in: finalTextRect)
//
//        currentY += boundingRect.height + 10
//        
//        return qrRect
//    }
//
//    // MARK: Гиперссылка на ссылку чека в ОФД
//    private static func addLinkToPDF(data: Data, linkURL: String, linkRect: CGRect, pageIndex: Int) -> Data? {
//        guard let pdfDocument = PDFDocument(data: data) else { return nil }
//        guard let targetPage = pdfDocument.page(at: pageIndex) else { return nil }
//
//        let annotation = PDFAnnotation(bounds: linkRect, forType: .link, withProperties: nil)
//        annotation.url = URL(string: linkURL)
//        targetPage.addAnnotation(annotation)
//
//        return pdfDocument.dataRepresentation()
//    }
//
//    // MARK: Генерация QR кода
//    private static func generateQRCode(from string: String) -> UIImage? {
//        let data = string.data(using: .ascii)
//        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
//        filter.setValue(data, forKey: "inputMessage")
//        filter.setValue("Q", forKey: "inputCorrectionLevel")
//
//        guard let outputImage = filter.outputImage else { return nil }
//        let transform = CGAffineTransform(scaleX: 10, y: 10)
//        let scaledImage = outputImage.transformed(by: transform)
//
//        return UIImage(ciImage: scaledImage)
//    }
//    
//    private static func drawAlignedText(prefixText: String,
//                                        leftText: String,
//                                        rightText: String,
//                                        leftFont: UIFont,
//                                        rightFont: UIFont,
//                                        leftColor: UIColor,
//                                        rightColor: UIColor,
//                                        margin: CGFloat,
//                                        y: CGFloat,
//                                        pageWidth: CGFloat) -> CGFloat {
//        let prefixAttributes: [NSAttributedString.Key: Any] = [
//                .font: leftFont,
//                .foregroundColor: leftColor
//        ]
//        
//        // Вычисляем размеры левого текста
//        let leftAttributes: [NSAttributedString.Key: Any] = [
//            .font: leftFont,
//            .foregroundColor: leftColor
//        ]
//        let leftBoundingRect = (leftText as NSString).boundingRect(
//            with: CGSize(width: pageWidth / 2 - margin, height: CGFloat.greatestFiniteMagnitude),
//            options: .usesLineFragmentOrigin,
//            attributes: leftAttributes,
//            context: nil
//        )
//
//        // Рисуем левый текст
//        (leftText as NSString).draw(
//            with: CGRect(x: margin, y: y, width: pageWidth / 2 - margin, height: leftBoundingRect.height),
//            options: .usesLineFragmentOrigin,
//            attributes: leftAttributes,
//            context: nil
//        )
//
//        // Вычисляем размеры правого текста
//        let rightAttributes: [NSAttributedString.Key: Any] = [
//            .font: rightFont,
//            .foregroundColor: rightColor
//        ]
//        let rightBoundingRect = (rightText as NSString).boundingRect(
//            with: CGSize(width: pageWidth / 2 - margin, height: CGFloat.greatestFiniteMagnitude),
//            options: .usesLineFragmentOrigin,
//            attributes: rightAttributes,
//            context: nil
//        )
//
//        // Рисуем правый текст (выравниваем по правому краю)
//        let rightX = pageWidth - margin - rightBoundingRect.width
//        (rightText as NSString).draw(
//            with: CGRect(x: rightX, y: y, width: rightBoundingRect.width, height: rightBoundingRect.height),
//            options: .usesLineFragmentOrigin,
//            attributes: rightAttributes,
//            context: nil
//        )
//
//        // Возвращаем высоту блока текста
//        return max(leftBoundingRect.height, rightBoundingRect.height)
//    }
//
//    // MARK: Добавляем разделитель у цифр, если нужен
//    private static func formatNumber(_ number: Double) -> String {
//        let formatter = NumberFormatter()
//        formatter.numberStyle = .decimal
//        formatter.maximumFractionDigits = 2
//        formatter.minimumFractionDigits = 2
//        formatter.groupingSeparator = " "
//        formatter.locale = Locale(identifier: "ru_RU")
//        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
//    }
//    
//    private static func formatNumberCount(_ number: Double) -> String {
//        let formatter = NumberFormatter()
//        formatter.groupingSeparator = " "
//        formatter.locale = Locale(identifier: "ru_RU")
//        
//        if number.truncatingRemainder(dividingBy: 1) == 0 {
//            // Если дробной части нет, показываем только целую часть
//            formatter.maximumFractionDigits = 0
//        } else {
//            formatter.numberStyle = .decimal
//            formatter.maximumFractionDigits = 3
//            formatter.minimumFractionDigits = 2
//        }
//        
//        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
//    }
//}

import UIKit
import PDFKit

final class PDFGenerator {
    static func generatePDF(from receipt: Receipt) -> Data {
        let pageWidth: CGFloat = 226.8
        let pageHeight: CGFloat = 1000.0
        let margin: CGFloat = 10
        var currentY: CGFloat = margin
        
        let pdfMetaData = [
            kCGPDFContextCreator: "Tandau App",
            kCGPDFContextAuthor: "Sergey Ivanov",
            kCGPDFContextTitle: ""
        ]
        
        // Начало страницы
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), pdfMetaData)
        UIGraphicsBeginPDFPage()
        let context = UIGraphicsGetCurrentContext()
        
        let drawText: (String, CGRect, UIFont) -> CGFloat = { text, rect, font in
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .left
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .paragraphStyle: paragraphStyle,
                .foregroundColor: UIColor.black
            ]
            
            let boundingRect = (text as NSString).boundingRect(
                with: CGSize(width: rect.width, height: CGFloat.greatestFiniteMagnitude),
                options: .usesLineFragmentOrigin,
                attributes: attributes,
                context: nil
            )
            
            (text as NSString).draw(
                with: CGRect(x: rect.origin.x, y: rect.origin.y, width: rect.width, height: boundingRect.height),
                options: .usesLineFragmentOrigin,
                attributes: attributes,
                context: nil
            )
            return boundingRect.height
        }
        
        // Шапка чека
        let titleFont = UIFont.boldSystemFont(ofSize: 8)
        let detailFont = UIFont.systemFont(ofSize: 8)
        
        // Отрисовка шапки чека
        currentY += drawDashedLine(context: context, y: currentY, pageWidth: pageWidth)
        currentY += drawText(receipt.companyName, CGRect(x: margin, y: currentY, width: pageWidth - 2 * margin, height: CGFloat.greatestFiniteMagnitude), titleFont)
        
        if receipt.companyAddress != "" {
            currentY += drawText("Адрес: \(receipt.companyAddress)", CGRect(x: margin, y: currentY, width: pageWidth - 2 * margin, height: CGFloat.greatestFiniteMagnitude), detailFont)
        }
        
        currentY += drawText("ИИН/БИН: \(receipt.iinBin)", CGRect(x: margin, y: currentY, width: pageWidth - 2 * margin, height: CGFloat.greatestFiniteMagnitude), detailFont)
        currentY += 10
        currentY += drawDashedLine(context: context, y: currentY, pageWidth: pageWidth)
        
        currentY += drawAlignedText(prefixText: "", leftText: receipt.typeOperation.description(in: "ru"),
                                    rightText: "",
                                    leftFont: UIFont.boldSystemFont(ofSize: 14),
                                    rightFont: UIFont.boldSystemFont(ofSize: 10),
                                    leftColor: .black,
                                    rightColor: .black,
                                    margin: margin,
                                    y: currentY,
                                    pageWidth: pageWidth)
        
        // Форматирование даты
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy, HH:mm"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.locale = Locale(identifier: "ru_RU")
        let formattedDate = dateFormatter.string(from: receipt.dateTime)

        // Добавляем отрисовку форматированной даты
        currentY += drawText("Дата и время: \(formattedDate)",
                             CGRect(x: margin, y: currentY, width: pageWidth - 2 * margin, height: CGFloat.greatestFiniteMagnitude),
                             titleFont)

        currentY += 10
        currentY += drawDashedLine(context: context, y: currentY, pageWidth: pageWidth)
        
        // Позиции товаров
        currentY += drawText("Список товаров", CGRect(x: margin, y: currentY, width: pageWidth - 2 * margin, height: CGFloat.greatestFiniteMagnitude), titleFont)
        currentY += 10
        var itemIndex = 1
        for item in receipt.items {
            // Рисуем название товара
            currentY += drawText("\(itemIndex). \(item.name)",
                                 CGRect(x: margin, y: currentY, width: pageWidth - 2 * margin, height: CGFloat.greatestFiniteMagnitude),
                                 detailFont)
            
            let unitEnum = item.unit
            let unit: String

            if unitEnum == .unknown {
                unit = ""
            } else {
                unit = unitEnum.info.shortRus
            }

            let itemDetails: String
            if unit.isEmpty {
                itemDetails = "\(formatNumberCount(item.count)) x \(String(format: "%.2f", item.price))"
            } else {
                itemDetails = "\(formatNumberCount(item.count)) \(unit) x \(String(format: "%.2f", item.price))"
            }

            currentY += drawAlignedText(prefixText: "", leftText: itemDetails,
                                        rightText: formatNumber(item.sum),
                                        leftFont: detailFont,
                                        rightFont: UIFont.boldSystemFont(ofSize: 10),
                                        leftColor: .black,
                                        rightColor: .black,
                                        margin: margin,
                                        y: currentY,
                                        pageWidth: pageWidth)
            
            currentY += 10
            itemIndex += 1
        }
        
        currentY += drawDashedLine(context: context, y: currentY, pageWidth: pageWidth)
        
        // Итоги
        currentY += drawAlignedText(prefixText: "", leftText: "ИТОГО",
                                    rightText: formatNumber(receipt.totalSum),
                                    leftFont: UIFont.boldSystemFont(ofSize: 14),
                                    rightFont: UIFont.boldSystemFont(ofSize: 14),
                                    leftColor: .black,
                                    rightColor: .black,
                                    margin: margin,
                                    y: currentY,
                                    pageWidth: pageWidth)
        
        for payment in receipt.totalType {
            currentY += drawAlignedText(prefixText: "", leftText: payment.type.description(in: "ru"),
                                        rightText: formatNumber(payment.sum),
                                        leftFont: detailFont,
                                        rightFont: UIFont.boldSystemFont(ofSize: 8),
                                        leftColor: .black,
                                        rightColor: .black,
                                        margin: margin,
                                        y: currentY,
                                        pageWidth: pageWidth)
        }
        
        if let taken = receipt.taken, taken > 0 {
            currentY += drawAlignedText(prefixText: "", leftText: "Принято наличными",
                                        rightText: formatNumber(taken),
                                        leftFont: detailFont,
                                        rightFont: UIFont.boldSystemFont(ofSize: 8),
                                        leftColor: .black,
                                        rightColor: .black,
                                        margin: margin,
                                        y: currentY,
                                        pageWidth: pageWidth)
        }
        
        if let change = receipt.change, change > 0 {
            currentY += drawAlignedText(prefixText: "", leftText: "Сдача",
                                        rightText: formatNumber(change),
                                        leftFont: UIFont.boldSystemFont(ofSize: 8),
                                        rightFont: UIFont.boldSystemFont(ofSize: 8),
                                        leftColor: .black,
                                        rightColor: .black,
                                        margin: margin,
                                        y: currentY,
                                        pageWidth: pageWidth)
        }
        
        currentY += 10
        currentY += drawDashedLine(context: context, y: currentY, pageWidth: pageWidth)
        
        // QR-код
        let qrRect = drawQRCodeAndText(
            "Если нужен фискальный чек, нажмите на QR код.",
            url: receipt.url,
            currentY: &currentY,
            pageWidth: pageWidth,
            margin: margin,
            pageHeight: 1000.0
        )

        currentY += drawDashedLine(context: context, y: currentY, pageWidth: pageWidth)
        
        UIGraphicsEndPDFContext()
        
        let generatedPDF = pdfData as Data
        
        guard let pdfDocument = PDFDocument(data: generatedPDF),
              let firstPage = pdfDocument.page(at: 0) else {
            return generatedPDF
        }
        
        let pageBounds = firstPage.bounds(for: .mediaBox)
        let invertedY = pageBounds.height - qrRect.origin.y - qrRect.height
        let annotationRect = CGRect(
            x: qrRect.origin.x,
            y: invertedY,
            width: qrRect.width,
            height: qrRect.height
        )
        
        let linkAnnotation = PDFAnnotation(
            bounds: annotationRect,
            forType: .link,
            withProperties: nil
        )
        linkAnnotation.url = URL(string: receipt.url)
        firstPage.addAnnotation(linkAnnotation)
        
        // 5) Формируем новое Data
        if let modifiedPDF = pdfDocument.dataRepresentation() {
            return modifiedPDF
        }
        return generatedPDF
    }

    private static func drawDashedLine(context: CGContext?, y: CGFloat, pageWidth: CGFloat) -> CGFloat {
        guard let context = context else { return 0 }
        context.setLineWidth(1)
        context.setStrokeColor(UIColor.lightGray.cgColor)
        let dash: [CGFloat] = [1, 2]
        context.setLineDash(phase: 0, lengths: dash)
        context.move(to: CGPoint(x: 10, y: y))
        context.addLine(to: CGPoint(x: pageWidth - 10, y: y))
        context.strokePath()
        return 10
    }

    // MARK: Рисует QR КОД
    private static func drawQRCodeAndText(
        _ text: String,
        url: String,
        currentY: inout CGFloat,
        pageWidth: CGFloat,
        margin: CGFloat,
        pageHeight: CGFloat  // добавлен параметр pageHeight
    ) -> CGRect {
        let qrCodeSize: CGFloat = 100
        let qrCodeMargin: CGFloat = 1

        // Если QR-код не помещается на текущей странице, начинаем новую страницу
        if currentY + qrCodeMargin + qrCodeSize >= pageHeight {
            UIGraphicsBeginPDFPage()
            currentY = margin
        }

        // Определяем координаты для QR-кода
        let qrRect = CGRect(x: (pageWidth - qrCodeSize) / 2,
                            y: currentY,
                            width: qrCodeSize,
                            height: qrCodeSize)

        if let qrImage = generateQRCode(from: url) {
            qrImage.draw(in: qrRect) // отрисовка QR-кода
        }
        currentY += qrCodeSize + qrCodeMargin

        // Подготовка атрибутов для текста ссылки
        let linkFont = UIFont.systemFont(ofSize: 8)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .font: linkFont,
            .paragraphStyle: paragraphStyle,
            .foregroundColor: UIColor.black
        ]
        let attributedText = NSAttributedString(string: text, attributes: normalAttributes)

        // Определяем доступное пространство для текста
        let textRectMax = CGRect(x: margin,
                                 y: currentY,
                                 width: pageWidth - 2 * margin,
                                 height: CGFloat.greatestFiniteMagnitude)
        let boundingRect = attributedText.boundingRect(with: textRectMax.size,
                                                       options: .usesLineFragmentOrigin,
                                                       context: nil)
        let textHeight = ceil(boundingRect.height)
        
        // Если текст не помещается на текущей странице, начинаем новую страницу
        if currentY + textHeight >= pageHeight {
            UIGraphicsBeginPDFPage()
            currentY = margin
        }
        
        // Рисуем текст (с центровкой)
        let finalTextRect = CGRect(x: margin,
                                   y: currentY,
                                   width: pageWidth - 2 * margin,
                                   height: textHeight)
        attributedText.draw(in: finalTextRect)
        currentY += textHeight + 10

        return qrRect
    }

    // MARK: Гиперссылка на ссылку чека в ОФД
    private static func addLinkToPDF(data: Data, linkURL: String, linkRect: CGRect, pageIndex: Int) -> Data? {
        guard let pdfDocument = PDFDocument(data: data) else { return nil }
        guard let targetPage = pdfDocument.page(at: pageIndex) else { return nil }

        let annotation = PDFAnnotation(bounds: linkRect, forType: .link, withProperties: nil)
        annotation.url = URL(string: linkURL)
        targetPage.addAnnotation(annotation)

        return pdfDocument.dataRepresentation()
    }

    // MARK: Генерация QR кода
    private static func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: .ascii)
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("Q", forKey: "inputCorrectionLevel")

        guard let outputImage = filter.outputImage else { return nil }
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)

        return UIImage(ciImage: scaledImage)
    }
    
    private static func drawAlignedText(prefixText: String,
                                        leftText: String,
                                        rightText: String,
                                        leftFont: UIFont,
                                        rightFont: UIFont,
                                        leftColor: UIColor,
                                        rightColor: UIColor,
                                        margin: CGFloat,
                                        y: CGFloat,
                                        pageWidth: CGFloat) -> CGFloat {
        let prefixAttributes: [NSAttributedString.Key: Any] = [
                .font: leftFont,
                .foregroundColor: leftColor
        ]
        
        // Вычисляем размеры левого текста
        let leftAttributes: [NSAttributedString.Key: Any] = [
            .font: leftFont,
            .foregroundColor: leftColor
        ]
        let leftBoundingRect = (leftText as NSString).boundingRect(
            with: CGSize(width: pageWidth / 2 - margin, height: CGFloat.greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: leftAttributes,
            context: nil
        )

        // Рисуем левый текст
        (leftText as NSString).draw(
            with: CGRect(x: margin, y: y, width: pageWidth / 2 - margin, height: leftBoundingRect.height),
            options: .usesLineFragmentOrigin,
            attributes: leftAttributes,
            context: nil
        )

        // Вычисляем размеры правого текста
        let rightAttributes: [NSAttributedString.Key: Any] = [
            .font: rightFont,
            .foregroundColor: rightColor
        ]
        let rightBoundingRect = (rightText as NSString).boundingRect(
            with: CGSize(width: pageWidth / 2 - margin, height: CGFloat.greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: rightAttributes,
            context: nil
        )

        // Рисуем правый текст (выравниваем по правому краю)
        let rightX = pageWidth - margin - rightBoundingRect.width
        (rightText as NSString).draw(
            with: CGRect(x: rightX, y: y, width: rightBoundingRect.width, height: rightBoundingRect.height),
            options: .usesLineFragmentOrigin,
            attributes: rightAttributes,
            context: nil
        )

        // Возвращаем высоту блока текста
        return max(leftBoundingRect.height, rightBoundingRect.height)
    }

    // MARK: Добавляем разделитель у цифр, если нужен
    private static func formatNumber(_ number: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        formatter.groupingSeparator = " "
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    private static func formatNumberCount(_ number: Double) -> String {
        let formatter = NumberFormatter()
        formatter.groupingSeparator = " "
        formatter.locale = Locale(identifier: "ru_RU")
        
        if number.truncatingRemainder(dividingBy: 1) == 0 {
            // Если дробной части нет, показываем только целую часть
            formatter.maximumFractionDigits = 0
        } else {
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 3
            formatter.minimumFractionDigits = 2
        }
        
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}
