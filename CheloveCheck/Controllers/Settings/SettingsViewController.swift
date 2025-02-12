//
//  SettingsViewController.swift
//  CheloveCheck
//
//  Created by Sergey Ivanov on 03.02.2025.
//

import UIKit

final class SettingsViewController: UITableViewController {
    
    private enum Section {
        case main
    }
    
    private var dataSource: UITableViewDiffableDataSource<SettingsSection, SettingsItem>!
    
    init() {
        super.init(style: .grouped)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Настройки"
        tableView.backgroundColor = .mainBackground
        tableView.register(SettingsTableViewCell.self, forCellReuseIdentifier: SettingsTableViewCell.reuseIdentifier)
        tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "Header")
        
        configureDataSource()
        applySnapshot()
    }
    
    private func configureDataSource() {
        dataSource = UITableViewDiffableDataSource<SettingsSection, SettingsItem>(tableView: tableView) { tableView, indexPath, item in
            guard let cell = tableView.dequeueReusableCell(withIdentifier: SettingsTableViewCell.reuseIdentifier, for: indexPath) as? SettingsTableViewCell else {
                return UITableViewCell()
            }
            cell.configure(with: item)
            return cell
        }
    }
    
    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<SettingsSection, SettingsItem>()
        for section in SettingsSection.allCases {
            snapshot.appendSections([section])
            snapshot.appendItems(section.items, toSection: section)
        }
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "Header") else {
            return nil
        }
        // Получаем snapshot из diffable data source для доступа к секции
        let snapshot = dataSource.snapshot()
        let sectionIdentifier = snapshot.sectionIdentifiers[section]
        header.textLabel?.text = sectionIdentifier.title
        return header
    }

    // Обработка нажатия на ячейку
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let item = dataSource.itemIdentifier(for: indexPath), let url = item.url {
            UIApplication.shared.open(url)
        }
    }
}
