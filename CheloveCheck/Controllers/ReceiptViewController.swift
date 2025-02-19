//
//  ReceiptViewController.swift
//  CheloveCheck
//
//  Created by Sergey Ivanov on 07.01.2025.
//

import UIKit
import PDFKit

final class ReceiptViewController: UIViewController {
    private var pdfData: Data!
    private var pdfView: PDFView!
    private let shouldShowSuccessAlert: Bool
    private var hasShownAlert = false

    init(receipt: Receipt, shouldShowSuccessAlert: Bool) {
        self.shouldShowSuccessAlert = shouldShowSuccessAlert
        super.init(nibName: nil, bundle: nil)
        self.pdfData = PDFGenerator.generatePDF(from: receipt)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        setupPDFView()
        setupNavigationBar()
        
        navigationItem.hidesBackButton = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if shouldShowSuccessAlert, !hasShownAlert {
            hasShownAlert = true
            let alert = CustomAlertView.show(on: self, type: .success, title: "Чек найден!", message: "Чек успешно найден и сохранен в приложении.") {}
            alert.dismissAfterDelay(2)
        }
    }

    private func setupPDFView() {
        pdfView = PDFView(frame: view.bounds)
        pdfView.autoScales = true
        view.addSubview(pdfView)

        if let document = PDFDocument(data: pdfData) {
            pdfView.document = document
        }
    }

    private func setupNavigationBar() {
        navigationItem.title = "Чек"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(sharePDF)
        )
    }
    
    @objc private func sharePDF() {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("receipt.pdf")
        
        do {
            try pdfData.write(to: tempURL)
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            present(activityVC, animated: true, completion: nil)
        } catch {
            showError(AppError.pdfError(error))
        }
    }
    
    private func showError(_ error: AppError) {
        let alert = CustomAlertView.show(on: self, type: .error, title: "Ошибка!", message: error.message) { }
        guard let parentView = self.view else { return }
        alert.frame.origin.y = parentView.safeAreaInsets.top
    }
}
