//
//  SettingsViewController.swift
//  CheloveCheck
//
//  Created by Sergey Ivanov on 10.01.2025.
//

import UIKit
import AVFoundation

final class CameraView: UIView, AVCaptureMetadataOutputObjectsDelegate {
    
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var overlayLayer: CAShapeLayer!
    private let scanFrameSize = CGSize(width: 250, height: 250)
    var onError: ((AppError) -> Void)?
    var onQRCodeScanned: ((String) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .mainBackground
        setupOverlay()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .mainBackground
        setupOverlay()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
        updateOverlay()
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        checkCameraPermissions()
    }
    
    // MARK: Private Functions
    
    private func checkCameraPermissions() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.setupCamera()
                    } else {
                        self.onError?(.cameraAccessDenied)
                    }
                }
            }
        case .denied, .restricted:
            onError?(.cameraAccessDenied)
        @unknown default:
            onError?(.unknown(NSError(domain: "CameraError", code: -1, userInfo: nil)))
        }
    }
    
    private func setupCamera() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            self.captureSession = AVCaptureSession()
            self.captureSession.beginConfiguration()

            defer {
                self.captureSession.commitConfiguration()
            }
            
            if self.captureSession.canSetSessionPreset(.hd1920x1080) {
                self.captureSession.sessionPreset = .hd1920x1080
            }
            
            guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
                DispatchQueue.main.async {
                    self.onError?(.cameraUnavailable)
                }
                return
            }
            
            do {
                let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
                
                if self.captureSession.canAddInput(videoInput) {
                    self.captureSession.addInput(videoInput)
                } else {
                    DispatchQueue.main.async {
                        self.onError?(.cameraSessionFailed(NSError(domain: "CameraError", code: -2, userInfo: nil)))
                    }
                    return
                }
            } catch {
                DispatchQueue.main.async {
                    self.onError?(.cameraSessionFailed(error))
                }
                return
            }
            
            let metadataOutput = AVCaptureMetadataOutput()
            if self.captureSession.canAddOutput(metadataOutput) {
                self.captureSession.addOutput(metadataOutput)
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.qr]
            } else {
                DispatchQueue.main.async {
                    self.onError?(.cameraSessionFailed(NSError(domain: "CameraError", code: -3, userInfo: nil)))
                }
                return
            }
            
            DispatchQueue.main.async {
                self.setupPreviewLayer()
            }
        }
    }
    
    private func setupPreviewLayer() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = bounds
        previewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(previewLayer)
        
        layer.addSublayer(overlayLayer)
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }
    
    private func setupOverlay() {
        overlayLayer = CAShapeLayer()
        updateOverlay()
        layer.addSublayer(overlayLayer)
    }
    
    private func updateOverlay() {
        overlayLayer.frame = bounds
        
        // Создаем путь с вырезанным прямоугольником
        let path = UIBezierPath(rect: bounds)
        let scanRect = CGRect(
            x: (bounds.width - scanFrameSize.width) / 2,
            y: (bounds.height - scanFrameSize.height) / 2,
            width: scanFrameSize.width,
            height: scanFrameSize.height
        )
        path.append(UIBezierPath(rect: scanRect).reversing())
        
        // Настраиваем затемнение области за пределами прямоугольника
        overlayLayer.path = path.cgPath
        overlayLayer.fillColor = UIColor.black.withAlphaComponent(0.5).cgColor
        
        // Добавляем углы прямоугольника
        addCorners(to: scanRect)
    }
    
    private func addCorners(to rect: CGRect) {
        let cornerRadius: CGFloat = 8 // Радиус скругления
        //let cornerLength: CGFloat = 30 // Длина линии угла
        let lineWidth: CGFloat = 4
        let cornerColor = UIColor.systemBlue.cgColor

        // Удаляем предыдущие углы, чтобы не дублировать
        overlayLayer.sublayers?.forEach { $0.removeFromSuperlayer() }

        // Углы прямоугольника
        let corners: [(CGPoint, CGPoint, CGPoint)] = [
            (CGPoint(x: rect.minX, y: rect.minY + cornerRadius), CGPoint(x: rect.minX, y: rect.minY), CGPoint(x: rect.minX + cornerRadius, y: rect.minY)), // Верхний левый
            (CGPoint(x: rect.maxX - cornerRadius, y: rect.minY), CGPoint(x: rect.maxX, y: rect.minY), CGPoint(x: rect.maxX, y: rect.minY + cornerRadius)), // Верхний правый
            (CGPoint(x: rect.minX, y: rect.maxY - cornerRadius), CGPoint(x: rect.minX, y: rect.maxY), CGPoint(x: rect.minX + cornerRadius, y: rect.maxY)), // Нижний левый
            (CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY), CGPoint(x: rect.maxX, y: rect.maxY), CGPoint(x: rect.maxX, y: rect.maxY - cornerRadius))  // Нижний правый
        ]

        for corner in corners {
            let cornerPath = UIBezierPath()
            cornerPath.move(to: corner.0) // Начало первой линии
            cornerPath.addLine(to: corner.1) // Центральная точка угла
            cornerPath.addLine(to: corner.2) // Завершение второй линии

            let cornerLayer = CAShapeLayer()
            cornerLayer.path = cornerPath.cgPath
            cornerLayer.strokeColor = cornerColor
            cornerLayer.lineWidth = lineWidth
            cornerLayer.fillColor = UIColor.clear.cgColor
            overlayLayer.addSublayer(cornerLayer)
        }
    }
    
    // MARK: Public Functions
    func stopCamera() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession?.stopRunning()
        }
    }
    
    func startCamera() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession?.startRunning()
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue else { return }
        
        stopCamera()
        onQRCodeScanned?(stringValue)
    }
}
