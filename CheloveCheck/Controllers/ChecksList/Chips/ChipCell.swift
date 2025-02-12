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

    private let chevronImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "chevron")?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = UIColor(resource: .filtersText)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = true
        return imageView
    }()

    private var chevronWidthConstraint: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(chevronImageView)

        contentView.layer.cornerRadius = 14
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = .clear
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor(resource: .filters).cgColor

        chevronWidthConstraint = chevronImageView.widthAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            contentView.heightAnchor.constraint(equalToConstant: 28),

            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            chevronImageView.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 2),
            chevronImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            chevronImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            chevronWidthConstraint,
            chevronImageView.heightAnchor.constraint(equalToConstant: 12)
        ])
    }

    func configure(with title: String, showsChevron: Bool) {
        titleLabel.text = title
        chevronImageView.isHidden = !showsChevron
        chevronWidthConstraint.constant = showsChevron ? 12 : 0
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

    static func calculateSize(for title: String, showsChevron: Bool, minimumWidth: CGFloat? = nil) -> CGSize {
        let textWidth = title.size(withAttributes: [.font: UIFont.systemFont(ofSize: 14)]).width
        let chevronWidth: CGFloat = showsChevron ? 18 : 0
        let padding: CGFloat = 32 // Внутренние отступы (12 слева + 12 справа + 8 для текста)
        let calculatedWidth = textWidth + chevronWidth + padding

        // Применяем минимальную ширину, если она задана
        let finalWidth = max(calculatedWidth, minimumWidth ?? 0)
        return CGSize(width: finalWidth, height: 28)
    }

}
