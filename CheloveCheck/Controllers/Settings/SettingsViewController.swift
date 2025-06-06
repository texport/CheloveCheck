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
    
    /// Логика по работе с картами
    private func presentMapProviderPicker() {
        let alert = UIAlertController(title: "Выберите провайдер карт", message: nil, preferredStyle: .actionSheet)
        
        let providers: [(title: String, provider: MapProvider)] = [
            ("Apple Карты", .apple),
            ("Яндекс Карты", .yandex),
            ("Google Карты", .google),
            ("2ГИС", .dgis)
        ]
        
        providers.forEach { entry in
            alert.addAction(UIAlertAction(title: entry.title, style: .default) { _ in
                UserDefaults.standard.setValue(entry.provider.rawValue, forKey: "selectedMapProvider")
                self.applySnapshot()
            })
        }
        
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }
    
    private func exportReceiptsToJSON() {
        Loader.show()
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let receipts = try ReceiptRepository.shared.fetchAll()
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let data = try encoder.encode(receipts)
                
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
                let dateString = formatter.string(from: Date())
                let fileName = "ReceiptsBackup_\(dateString).json"
                
                let fileURL = FileManager.default
                    .temporaryDirectory
                    .appendingPathComponent(fileName)
                
                try data.write(to: fileURL)
                
                DispatchQueue.main.async {
                    Loader.dismiss()
                    
                    let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
                    activityVC.popoverPresentationController?.sourceView = self.view
                    
                    activityVC.completionWithItemsHandler = { activityType, completed, returnedItems, error in
                        if completed {
                            CustomAlertView.show(on: self,
                                                 type: .success,
                                                 title: "Успешно",
                                                 message: "Чеки экспортированы в файл «\(fileName)»") {
                            }
                        }
                    }
                    
                    self.present(activityVC, animated: true)
                }
            } catch {
                DispatchQueue.main.async {
                    Loader.dismiss()
                    self.showAlert(title: "Ошибка", message: "Не удалось экспортировать: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func importReceiptsFromJSON() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json])
        picker.delegate = self
        present(picker, animated: true)
    }
    
    // MARK: Удаление всех чеков
    private func confirmAndDeleteAllReceipts() {
        do {
            let count = try ReceiptRepository.shared.count()
            if count == 0 {
                CustomAlertView.show(on: self,
                                     type: .error,
                                     title: "Пусто",
                                     message: "Чеки для удаления отсутствуют.") {
                }
                return
            }

            let alert = UIAlertController(
                title: "Удалить все чеки?",
                message: "Всего будет удалено \(count) чеков. Это действие необратимо.",
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: "Удалить", style: .destructive) { _ in
                Loader.show()
                
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        try ReceiptRepository.shared.deleteAll()

                        DispatchQueue.main.async {
                            Loader.dismiss()
                            NotificationCenter.default.post(name: .receiptsDidDeleteAll, object: nil)
                            
                            CustomAlertView.show(on: self,
                                                 type: .success,
                                                 title: "Готово",
                                                 message: "Все чеки удалены.") {
                            }.dismissAfterDelay(3)
                        }
                    } catch {
                        DispatchQueue.main.async {
                            Loader.dismiss()
                            CustomAlertView.show(on: self,
                                                 type: .error,
                                                 title: "Ошибка",
                                                 message: "Не удалось удалить: \(error.localizedDescription)") {
                            }
                        }
                    }
                }
            })

            alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
            present(alert, animated: true)

        } catch {
            CustomAlertView.show(on: self,
                                 type: .error,
                                 title: "Ошибка",
                                 message: error.localizedDescription) {
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ОК", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: Выбор темы
    private func presentThemePicker() {
        let alert = UIAlertController(title: "Выберите тему", message: nil, preferredStyle: .actionSheet)

        ThemeManager.AppTheme.allCases.forEach { theme in
            alert.addAction(UIAlertAction(title: theme.rawValue, style: .default) { _ in
                ThemeManager.applyTheme(theme)
                self.applySnapshot()
            })
        }

        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "Header") else {
            return nil
        }
        
        let snapshot = dataSource.snapshot()
        let sectionIdentifier = snapshot.sectionIdentifiers[section]
        header.textLabel?.text = sectionIdentifier.title
        return header
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        
        if let url = item.url {
            UIApplication.shared.open(url)
        }
        
        switch item.title {
        case let title where title.contains("Провайдер карт"):
            presentMapProviderPicker()
        case "Выгрузить чеки в файл":
            exportReceiptsToJSON()
        case "Загрузить чеки из файла":
            importReceiptsFromJSON()
        case "Удалить все чеки из базы":
            confirmAndDeleteAllReceipts()
        case let title where ThemeManager.AppTheme.allCases.map({ $0.rawValue }).contains(title):
            presentThemePicker()
        default:
            break
        }
    }
}

extension SettingsViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else {
            return
        }

        let isAccessing = url.startAccessingSecurityScopedResource()

        guard isAccessing else {
            CustomAlertView.show(on: self,
                                 type: .error,
                                 title: "Ошибка доступа",
                                 message: "Не удалось получить доступ к файлу.") {}
            return
        }

        defer {
            url.stopAccessingSecurityScopedResource()
        }

        // Копируем файл во временную папку
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
        do {
            if FileManager.default.fileExists(atPath: tempURL.path) {
                try FileManager.default.removeItem(at: tempURL)
            }
            try FileManager.default.copyItem(at: url, to: tempURL)
        } catch {
            CustomAlertView.show(on: self,
                                 type: .error,
                                 title: "Ошибка",
                                 message: "Не удалось скопировать файл: \(error.localizedDescription)") {}
            return
        }

        // Обрабатываем файл
        controller.dismiss(animated: true) {
            Loader.showProgress(message: "Импорт чеков: 0%", progress: 0.0)
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let data = try Data(contentsOf: tempURL)
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let receipts = try decoder.decode([Receipt].self, from: data)

                    let result = try ReceiptRepository.shared.saveMany(
                        receipts,
                        chunkSize: 10000,
                        progress: { percent, progress in
                            DispatchQueue.main.async {
                                Loader.showProgress(message: "Импорт чеков: \(percent)%", progress: progress)
                            }
                        }
                    )

                    let imported = result.imported
                    let skipped = result.skipped

                    try? FileManager.default.removeItem(at: tempURL)

                    let message = self.buildImportReport(imported: imported, skipped: skipped)

                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .receiptsDidImport, object: nil)
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            Loader.dismiss()
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                CustomAlertView.show(on: self,
                                                     type: .success,
                                                     title: "Импорт завершён",
                                                     message: message) {}
                            }
                        }
                    }
                } catch let decodingError as DecodingError {
                    DispatchQueue.main.async {
                        Loader.dismiss()
                        var message = ""
                        switch decodingError {
                        case .dataCorrupted(let context):
                            message = "dataCorrupted: \(context.debugDescription)"
                        case .keyNotFound(let key, let context):
                            message = "keyNotFound: \(key.stringValue) – \(context.debugDescription)"
                        case .typeMismatch(let type, let context):
                            message = "typeMismatch: \(type) – \(context.debugDescription)"
                        case .valueNotFound(let value, let context):
                            message = "valueNotFound: \(value) – \(context.debugDescription)"
                        @unknown default:
                            message = decodingError.localizedDescription
                        }
                        
                        CustomAlertView.show(on: self,
                                             type: .error,
                                             title: "Ошибка",
                                             message: message) {}
                    }
                } catch {
                    DispatchQueue.main.async {
                        Loader.dismiss()
                        CustomAlertView.show(on: self,
                                             type: .error,
                                             title: "Ошибка",
                                             message: "Не удалось импортировать: \(error.localizedDescription)") {}
                    }
                }
            }
        }
    }

    /// Формирует текст отчета по импорту чеков
    private func buildImportReport(imported: [Receipt], skipped: [Receipt]) -> String {
        var message = "Импортировано чеков: \(imported.count)\nПропущено (дубликаты): \(skipped.count)"

        if !skipped.isEmpty {
            let details = skipped.prefix(5).map {
                let fiscal = $0.fiscalSign ?? "—"
                let date = formattedDate($0.dateTime)
                let sum = formattedSum($0.totalSum)
                return "• \(fiscal), \(date), \(sum)"
            }.joined(separator: "\n")

            message += "\n\nПропущенные чеки:\n\(details)"
            if skipped.count > 5 {
                message += "\n…и ещё \(skipped.count - 5)"
            }
        }

        return message
    }
    
    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "—" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = .current
        return formatter.string(from: date)
    }
    
    private func formattedSum(_ sum: Double?) -> String {
        guard let sum = sum else { return "—" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₸"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: sum)) ?? "\(sum)"
    }
}
