import UIKit
import AVFoundation

final class AddCheckViewController: UIViewController {
    private var cameraView: CameraView!
    private var flashlightOn = false
    private var overlayView: UIView?
    private var isProcessingQRCode = false
    private var repository: ReceiptRepository
    
    // MARK: - Initialization
    init(repository: ReceiptRepository) {
        self.repository = repository
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        view.backgroundColor = .mainBackground
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.backgroundColor = .mainBackground
        cameraView.backgroundColor = .mainBackground
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = .mainBackground
        
        // Добавляем кастомный CameraView
        cameraView = CameraView()
        cameraView.translatesAutoresizingMaskIntoConstraints = false
        cameraView.onQRCodeScanned = { [weak self] qrCode in
            self?.processQRCode(qrCode)
        }
        
        cameraView.onError = { [weak self] error in
            self?.showError(error)
        }
        
        view.addSubview(cameraView)
        
        NSLayoutConstraint.activate([
            cameraView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            cameraView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cameraView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cameraView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Navigation Bar Setup
    private func setupNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationController?.navigationBar.barTintColor = .mainBackground
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.mainTextColors,
            .font: UIFont.systemFont(ofSize: 17, weight: .bold)
        ]
        navigationItem.title = "Сканируйте QR-код"
        
        // Кнопка фонарика
        let flashlightButton = UIBarButtonItem(
            image: UIImage(systemName: flashlightOn ? "bolt.fill" : "bolt.slash.fill"),
            style: .plain,
            target: self,
            action: #selector(toggleFlashlight)
        )
        flashlightButton.tintColor = .systemBlue
        navigationItem.leftBarButtonItem = flashlightButton
        
        let closeButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(closeScreen)
        )
        closeButton.tintColor = .systemBlue
        navigationItem.rightBarButtonItem = closeButton
    }
    
    // MARK: - Button Actions
    @objc private func toggleFlashlight() {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        
        do {
            try device.lockForConfiguration()
            flashlightOn.toggle()
            device.torchMode = flashlightOn ? .on : .off
            navigationItem.leftBarButtonItem?.image = UIImage(systemName: flashlightOn ? "bolt.fill" : "bolt.slash.fill")
            device.unlockForConfiguration()
        } catch {
            self.showError(.flashlightError(error))
        }
    }
    
    @objc private func closeScreen() {
        if let presentingVC = presentingViewController {
            presentingVC.dismiss(animated: true, completion: nil)
        } else if let navigationController = navigationController {
            navigationController.popViewController(animated: true)
        } else {
            self.showError(.failedToCloseScreen)
        }
    }
    
    // MARK: - Блокировка интерфейса
    private func lockInterface() {
        guard overlayView == nil else { return }
        
        let overlay = UIView(frame: UIScreen.main.bounds)
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.addSubview(overlay)
            overlayView = overlay
            window.isUserInteractionEnabled = false
        }
    }
    
    private func unlockInterface() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            overlayView?.removeFromSuperview()
            overlayView = nil
            window.isUserInteractionEnabled = true
        }
    }
    
    // MARK: - QR Code Processing
    private func processQRCode(_ qrCode: String) {
        guard !isProcessingQRCode else { return }
        isProcessingQRCode = true

        var modifiedQRCode = qrCode
        
        if qrCode.hasPrefix("http://") {
            modifiedQRCode = qrCode.replacingOccurrences(of: "http://", with: "https://")
        }
        
        guard let url = URL(string: modifiedQRCode), let host = url.host else {
            showError(.invalidQRCode)
            isProcessingQRCode = false
            return
        }
        
        lockInterface()
        Loader.show()
        
        let handlerManager = OFDHandlerManager()
        
        guard let handler = handlerManager.handler(for: host) else {
            Loader.dismiss()
            unlockInterface()
            showError(.unsupportedDomain)
            isProcessingQRCode = false
            return
        }
        
        handler.fetchCheck(from: url) { [weak self] result in
            DispatchQueue.main.async {
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    Loader.dismiss()
                    self?.unlockInterface()
                    self?.isProcessingQRCode = false
                    guard let self = self else { return }
                    
                    switch result {
                    case .success(let receipt):
                        Loader.dismiss()
                        do {
                            try self.saveReceiptToDatabase(receipt)
                            DispatchQueue.main.async {
                                let receiptVC = ReceiptViewController(receipt: receipt, shouldShowSuccessAlert: true)
                                self.navigationController?.pushViewController(receiptVC, animated: true)
                            }
                        } catch {
                            Loader.dismiss()
                            self.showError(.failedToSaveReceipt(error))
                        }
                    case .failure(let error):
                        Loader.dismiss()
                        let appError = error as? AppError ?? .unknown(error)
                        self.showError(appError)
                    }
                }
            }
        }
    }

    private func saveReceiptToDatabase(_ receipt: Receipt) throws {
        try repository.save(receipt)
        NotificationCenter.default.post(name: .newCheckAdded, object: receipt)
    }
    
    private func showError(_ error: AppError) {
        CustomAlertView.show(on: self, type: .error, title: "Ошибка!", message: error.message) { [weak self] in
            self?.isProcessingQRCode = false
            self?.cameraView.startCamera()
        }
    }
}

extension Notification.Name {
    static let newCheckAdded = Notification.Name("newCheckAdded")
}
