//
//  CheckCell.swift
//  Tandau
//
//  Created by Sergey Ivanov on 10.01.2025.
//

import UIKit
import MapKit
import CoreData

protocol CheckCellDelegate: AnyObject {
    func didTapDelete(on cell: CheckCell)
    func didTapLocationButton(with address: String)
    func didTapView(on cell: CheckCell)
}

final class CheckCell: UITableViewCell {
    
    weak var delegate: CheckCellDelegate?
    private var address: String?
    
    // MARK: - UI Elements
    
    private lazy var cardView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .loaderBackgound
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowOpacity = 0.1
        view.layer.shadowRadius = 4
        view.layer.masksToBounds = false
        let interaction = UIContextMenuInteraction(delegate: self)
        view.addInteraction(interaction)
        return view
    }()
    
    private lazy var companyNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 17)
        label.textColor = .mainTextColors
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var iinBinLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .text2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var locationButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Узнать на карте", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        button.setTitleColor(.systemBlue, for: .normal)
        button.addTarget(self, action: #selector(locationButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var totalSumLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textColor = .mainTextColors
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .text2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .clear
        selectionStyle = .none
        clipsToBounds = false
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Configuration
    
    func configure(with receipt: Receipt) {
        let companyName = fetchRetailNetworkName(for: receipt.iinBin) ?? receipt.companyName
        companyNameLabel.text = companyName
        
        iinBinLabel.text = "ИИН/БИН: \(receipt.iinBin)"
        
        let sum = formatTotalSum(receipt.totalSum)
        totalSumLabel.text = "\(sum) ₸"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy, HH:mm"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateLabel.text = dateFormatter.string(from: receipt.dateTime)
        
        address = receipt.companyAddress
    }
    
    private func formatTotalSum(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.groupingSeparator = " "
        formatter.decimalSeparator = ""
        formatter.maximumFractionDigits = 0
        
        return formatter.string(from: NSNumber(value: amount)) ?? "\(Int(amount))"
    }
    
    private func fetchRetailNetworkName(for iinBin: String) -> String? {
        let context = CoreDataManager.shared.context
        let fetchRequest: NSFetchRequest<RetailEntity> = RetailEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "bin == %@", iinBin)

        do {
            let results = try context.fetch(fetchRequest)
            // Если нашли запись, возвращаем networkName
            return results.first?.networkName
        } catch {
            print("Ошибка поиска RetailEntity: \(error)")
            return nil
        }
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        contentView.backgroundColor = .clear
        
        contentView.addSubview(cardView)
        cardView.addSubview(companyNameLabel)
        cardView.addSubview(iinBinLabel)
        cardView.addSubview(locationButton)
        cardView.addSubview(separatorView)
        cardView.addSubview(totalSumLabel)
        cardView.addSubview(dateLabel)
        
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            cardView.heightAnchor.constraint(equalToConstant: 166),
            
            companyNameLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            companyNameLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            companyNameLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            
            iinBinLabel.topAnchor.constraint(equalTo: companyNameLabel.bottomAnchor, constant: 4),
            iinBinLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            iinBinLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            
            locationButton.topAnchor.constraint(equalTo: iinBinLabel.bottomAnchor, constant: 12),
            locationButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            
            separatorView.topAnchor.constraint(equalTo: locationButton.bottomAnchor, constant: 16),
            separatorView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            separatorView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            separatorView.heightAnchor.constraint(equalToConstant: 1),
            
            totalSumLabel.topAnchor.constraint(equalTo: separatorView.bottomAnchor, constant: 15),
            totalSumLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            totalSumLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16),
            
            dateLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            dateLabel.centerYAnchor.constraint(equalTo: totalSumLabel.centerYAnchor)
        ])
    }
    
    @objc private func locationButtonTapped() {
        guard let address = address, !address.isEmpty else { return }
        delegate?.didTapLocationButton(with: address)
    }
}

// MARK: - UIContextMenuInteractionDelegate
extension CheckCell: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let viewAction = UIAction(title: "Просмотр",
                                      image: UIImage(systemName: "eye")) { _ in
                self.delegate?.didTapView(on: self)
            }
            let deleteAction = UIAction(title: "Удалить",
                                        image: UIImage(systemName: "trash"),
                                        attributes: .destructive) { _ in
                self.delegate?.didTapDelete(on: self)
            }
            return UIMenu(title: "Действия", children: [viewAction, deleteAction])
        }
    }
}
