//
//  CustomAlerView.swift
//  CheloveCheck
//
//  Created by Sergey Ivanov on 05.01.2025.
//

import UIKit

enum AlertType {
    case success
    case error
}

final class CustomAlertView: UIView {
    private var onClose: (() -> Void)?

    // MARK: - UI Components
    private lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var alertView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.textColor = .white
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .white
        label.textAlignment = .left
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var supportLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 1
        label.isUserInteractionEnabled = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark")?.withTintColor(.white, renderingMode: .alwaysOriginal), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - Initializer
    init(type: AlertType, title: String, message: String, onClose: @escaping () -> Void) {
        super.init(frame: .zero)
        self.onClose = onClose
        setupUI()
        setupConstraints()
        triggerHapticFeedback(for: type)

        switch type {
        case .success:
            alertView.backgroundColor = .systemGreen
            setupSuccessView()
        case .error:
            alertView.backgroundColor = .systemRed
            setupSupportLabel()
            triggerShakeAnimation()
        }

        titleLabel.text = title
        messageLabel.text = message
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup UI
    private func setupUI() {
        addSubview(backgroundView)
        addSubview(alertView)

        alertView.addSubview(titleLabel)
        alertView.addSubview(messageLabel)
        alertView.addSubview(closeButton)

        closeButton.addTarget(self, action: #selector(dismissAlert), for: .touchUpInside)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Фон
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),

            // Алерт
            alertView.leadingAnchor.constraint(equalTo: leadingAnchor),
            alertView.trailingAnchor.constraint(equalTo: trailingAnchor),
            alertView.topAnchor.constraint(equalTo: topAnchor),

            // Заголовок
            titleLabel.topAnchor.constraint(equalTo: alertView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: alertView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -8),

            // Сообщение
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: alertView.leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: alertView.trailingAnchor, constant: -16),

            // Кнопка закрытия
            closeButton.topAnchor.constraint(equalTo: alertView.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: alertView.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            closeButton.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    private func setupSuccessView() {
        NSLayoutConstraint.activate([
            messageLabel.bottomAnchor.constraint(equalTo: alertView.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupSupportLabel() {
        supportLabel.text = "Нужна помощь? Напишите нажмите сюда"
        alertView.addSubview(supportLabel)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapSupportLink))
        supportLabel.addGestureRecognizer(tapGesture)
        
        NSLayoutConstraint.activate([
            supportLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 10),
            supportLabel.leadingAnchor.constraint(equalTo: alertView.leadingAnchor, constant: 16),
            supportLabel.trailingAnchor.constraint(equalTo: alertView.trailingAnchor, constant: -16),
            supportLabel.bottomAnchor.constraint(equalTo: alertView.bottomAnchor, constant: -16)
        ])
    }
    
    private func triggerHapticFeedback(for type: AlertType) {
        let feedbackGenerator = UINotificationFeedbackGenerator()
        switch type {
        case .success:
            feedbackGenerator.notificationOccurred(.success)
        case .error:
            feedbackGenerator.notificationOccurred(.error)
        }
    }
    
    private func triggerShakeAnimation() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.values = [-10, 10, -7, 7, -5, 5, 0]
        animation.duration = 0.5
        alertView.layer.add(animation, forKey: "shake")
    }
    
    // MARK: - Actions
    @objc private func dismissAlert() {
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0
        }) { [weak self] _ in
            self?.removeFromSuperview()
            self?.onClose?()
        }
    }

    @objc private func didTapSupportLink() {
        if let url = URL(string: "https://t.me/chelovecheck_com") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    // MARK: - Show Alert
    static func show(on viewController: UIViewController, type: AlertType, title: String, message: String, onClose: @escaping () -> Void) -> CustomAlertView {
        let alert = CustomAlertView(type: type, title: title, message: message, onClose: onClose)
        alert.frame = viewController.view.bounds
        viewController.view.addSubview(alert)
        return alert
    }
    
    func dismissAfterDelay(_ delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.dismissAlert()
        }
    }
}
