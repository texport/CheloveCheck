//
//  ChipCell.swift
//  CheloveCheck
//
//  Created by Sergey Ivanov on 30.01.2025.
//

import UIKit

final class ChipCell: UICollectionViewCell {
    static let reuseIdentifier = "ChipCell"

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14, weight: .light)
        label.textColor = UIColor(resource: .filtersText)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(titleLabel)

        contentView.layer.cornerRadius = 14
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = .clear
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor(resource: .filters).cgColor

        NSLayoutConstraint.activate([
            contentView.heightAnchor.constraint(equalToConstant: 28),

            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }

    func configure(with title: String) {
        titleLabel.text = title
    }
    
    func setSelected(_ isSelected: Bool, animated: Bool = true) {
        let newBackgroundColor = isSelected ? UIColor(resource: .filterSelected) : .clear
        let newBorderColor = isSelected ? UIColor(resource: .filterSelected).cgColor : UIColor(resource: .filters).cgColor
        let newTextColor = isSelected ? UIColor(resource: .filterTextSelected) : UIColor(resource: .filtersText)

        if animated {
            UIView.animate(withDuration: 0.25, animations: {
                self.contentView.backgroundColor = newBackgroundColor
                self.contentView.layer.borderColor = newBorderColor
                self.titleLabel.textColor = newTextColor
            })
        } else {
            self.contentView.backgroundColor = newBackgroundColor
            self.contentView.layer.borderColor = newBorderColor
            self.titleLabel.textColor = newTextColor
        }
    }

    static func calculateSize(for title: String) -> CGSize {
        let textWidth = title.size(withAttributes: [.font: UIFont.systemFont(ofSize: 14)]).width
        let padding: CGFloat = 24
        return CGSize(width: textWidth + padding, height: 28)
    }
}
