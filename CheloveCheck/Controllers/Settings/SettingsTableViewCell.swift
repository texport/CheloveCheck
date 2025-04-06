//
//  SettingsTableViewCell.swift
//  CheloveCheck
//
//  Created by Sergey Ivanov on 04.02.2025.
//

import UIKit

final class SettingsTableViewCell: UITableViewCell {
    static let reuseIdentifier = "SettingsTableViewCell"
    
    private lazy var iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.tintColor = .label
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.layer.cornerRadius = 7
        iv.clipsToBounds = true
        return iv
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 30),
            iconImageView.heightAnchor.constraint(equalToConstant: 30),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
        
        accessoryType = .disclosureIndicator
        backgroundColor = .mainBackground
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with item: SettingsItem) {
        titleLabel.text = item.title
        print("⚙️ configure: item = \(item.title)")

        if let iconName = item.iconName {
            print("🔍 iconName: \(iconName)")
            if let image = UIImage(named: iconName) {
                print("📦 Используем кастомную иконку: \(iconName)")
                iconImageView.image = image
            } else if let systemImage = UIImage(systemName: iconName) {
                print("🖼 Используем SF Symbol: \(iconName)")
                iconImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(scale: .medium)
                iconImageView.image = systemImage
            } else {
                print("❌ Иконка не найдена: \(iconName)")
            }
        }

        accessoryType = item.url != nil ? .disclosureIndicator : .none
    }
}
