//
//  ChecksViewController.swift
//  CheloveCheck
//
//  Created by Sergey Ivanov on 10.01.2025.
//

import UIKit
import MapKit

final class ChecksViewController: UIViewController, UICollectionViewDelegate {
    // Флаги состояния
    private var isFetching: Bool = false
    private var hasMoreData: Bool = true
    private var isTopControlsHidden: Bool = false
    
    // Основной массив данных
    private var checks: [Receipt] = []
    private let repository: ReceiptRepository
    private let filtersManager: FiltersManager
    private var scrollTimer: Timer?
    
    private var topControlsHeightConstraint: NSLayoutConstraint!
    private let topControlsDesiredHeight: CGFloat = 80
    private var searchBarTrailingConstraint: NSLayoutConstraint!
    private var tableViewTopConstraint: NSLayoutConstraint!
    
    // MARK: - UI Elements
    private lazy var topControlsContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .mainBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Найти чек"
        searchBar.searchTextField.textColor = UIColor(resource: .searchFieldText)
        
        let placeholderAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(resource: .searchPlaceholderFieldText)
        ]
        
        searchBar.backgroundImage = UIImage()
        searchBar.searchTextField.backgroundColor = UIColor(resource: .searchFieldBackground)
        searchBar.layer.cornerRadius = 12
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.setShowsCancelButton(true, animated: true)
        searchBar.setValue("Отмена", forKey: "cancelButtonText")
        return searchBar
    }()
    
    // Контейнер для горизонтального скролла фильтров
    private lazy var filtersCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.register(ChipCell.self, forCellWithReuseIdentifier: ChipCell.reuseIdentifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isScrollEnabled = true // Включить прокрутку
        collectionView.alwaysBounceHorizontal = true // Добавить bounce-эффект при достижении конца
        
        return collectionView
    }()

    // Основная таблица
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .mainBackground
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(CheckCell.self, forCellReuseIdentifier: "CheckCell")
        tableView.isHidden = true
        tableView.separatorStyle = .none
        
        // Скрытие клавиатуры при скролле
        tableView.keyboardDismissMode = .onDrag
        
        return tableView
    }()
    
    // Placeholder — отображается, если нет чеков
    private lazy var placeholderViewMain: UIView = {
        let placeholderView = UIView()
        placeholderView.backgroundColor = .mainBackground
        placeholderView.translatesAutoresizingMaskIntoConstraints = false
        return placeholderView
    }()
    
    private lazy var placeholderViewSecond: UIView = {
        let placeholderView = UIView()
        placeholderView.backgroundColor = .mainBackground
        placeholderView.translatesAutoresizingMaskIntoConstraints = false
        return placeholderView
    }()
    
    private lazy var placeholderImage: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "PlaceholderImage"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private lazy var placeholderLabel: UILabel = {
        let placeholderLabel = UILabel()
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.text = "Нет чеков"
        placeholderLabel.textColor = UIColor(resource: .mainTextColors)
        placeholderLabel.textAlignment = .center
        placeholderLabel.font = UIFont.boldSystemFont(ofSize: 17)
        return placeholderLabel
    }()
    
    private lazy var placeholderDescription: UILabel = {
        let placeholderDescription = UILabel()
        placeholderDescription.translatesAutoresizingMaskIntoConstraints = false
        placeholderDescription.textColor = UIColor(resource: .text2)
        placeholderDescription.text = "Чтобы добавить чек, нажмите\n кнопку \"+\" вверху или «Добавить»,\n внизу экрана"
        placeholderDescription.textAlignment = .center
        placeholderDescription.numberOfLines = 3
        placeholderDescription.font = UIFont.boldSystemFont(ofSize: 14)
        return placeholderDescription
    }()
    
    // MARK: - Инициализация
    init(repository: ReceiptRepository) {
        self.repository = repository
        self.filtersManager = FiltersManager(repository: repository)
        super.init(nibName: nil, bundle: nil)
        filtersManager.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .newCheckAdded, object: nil)
        NotificationCenter.default.removeObserver(self, name: .receiptsDidChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: .receiptsDidImport, object: nil)
    }
    
    // MARK: - Жизненный цикл
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        updatePlaceholderIfDatabaseIsEmpty()
        
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.prefetchDataSource = self
        
        searchBar.setShowsCancelButton(false, animated: false)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNewCheckAdded(_:)),
            name: .newCheckAdded,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleReceiptsDidChange),
            name: .receiptsDidChange,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleReceiptsDidImport),
            name: .receiptsDidImport,
            object: nil
        )
        
        filtersManager.fetchNextPage()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startScrollingAnimation()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopScrollingAnimation()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }

    // MARK: UI SETUP
    private func setupUI() {
        title = "Мои чеки"
        view.backgroundColor = .mainBackground
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addCheck)
        )
        navigationItem.rightBarButtonItem?.tintColor = UIColor(resource: .button1)
        
        view.addSubview(topControlsContainer)
        topControlsContainer.addSubview(searchBar)
        topControlsContainer.addSubview(filtersCollectionView)
        
        view.addSubview(tableView)
        view.addSubview(placeholderViewMain)
        placeholderViewMain.addSubview(placeholderViewSecond)
        placeholderViewSecond.addSubview(placeholderImage)
        placeholderViewSecond.addSubview(placeholderLabel)
        placeholderViewSecond.addSubview(placeholderDescription)
        
        topControlsHeightConstraint = topControlsContainer.heightAnchor.constraint(
            equalToConstant: topControlsDesiredHeight
        )
        
        tableViewTopConstraint = tableView.topAnchor.constraint(equalTo: topControlsContainer.bottomAnchor)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapGesture)
        
        searchBarTrailingConstraint = searchBar.trailingAnchor.constraint(equalTo: topControlsContainer.trailingAnchor, constant: -16)
        
        NSLayoutConstraint.activate([
            topControlsContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topControlsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topControlsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topControlsHeightConstraint,
            
            searchBar.topAnchor.constraint(equalTo: topControlsContainer.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: topControlsContainer.leadingAnchor, constant: 10),
            searchBarTrailingConstraint,
            searchBar.heightAnchor.constraint(equalToConstant: 36),
            
            filtersCollectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            filtersCollectionView.leadingAnchor.constraint(equalTo: topControlsContainer.leadingAnchor, constant: 16),
            filtersCollectionView.trailingAnchor.constraint(equalTo: topControlsContainer.trailingAnchor, constant: -5),
            filtersCollectionView.bottomAnchor.constraint(equalTo: topControlsContainer.bottomAnchor),
            filtersCollectionView.heightAnchor.constraint(equalToConstant: 44),
            
            tableViewTopConstraint,
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            placeholderViewMain.topAnchor.constraint(equalTo: topControlsContainer.bottomAnchor),
            placeholderViewMain.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            placeholderViewMain.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            placeholderViewMain.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            placeholderViewSecond.centerXAnchor.constraint(equalTo: placeholderViewMain.centerXAnchor),
            placeholderViewSecond.centerYAnchor.constraint(equalTo: placeholderViewMain.centerYAnchor),
            placeholderViewSecond.leadingAnchor.constraint(equalTo: placeholderViewMain.leadingAnchor, constant: 32),
            placeholderViewSecond.trailingAnchor.constraint(equalTo: placeholderViewMain.trailingAnchor, constant: -32),
            
            placeholderImage.topAnchor.constraint(equalTo: placeholderViewSecond.topAnchor),
            placeholderImage.centerXAnchor.constraint(equalTo: placeholderViewSecond.centerXAnchor),
            placeholderImage.widthAnchor.constraint(equalTo: placeholderViewSecond.widthAnchor, multiplier: 0.6),

            placeholderLabel.topAnchor.constraint(equalTo: placeholderImage.bottomAnchor, constant: 8),
            placeholderLabel.centerXAnchor.constraint(equalTo: placeholderViewSecond.centerXAnchor),
            
            placeholderDescription.topAnchor.constraint(equalTo: placeholderLabel.bottomAnchor, constant: 4),
            placeholderDescription.centerXAnchor.constraint(equalTo: placeholderViewSecond.centerXAnchor),
            placeholderDescription.leadingAnchor.constraint(equalTo: placeholderViewSecond.leadingAnchor, constant: 32),
            placeholderDescription.trailingAnchor.constraint(equalTo: placeholderViewSecond.trailingAnchor, constant: -32),
            placeholderDescription.bottomAnchor.constraint(equalTo: placeholderViewSecond.bottomAnchor)
        ])
    }
    
    // MARK: - Private Functions
    private func updateUI() {
        let isEmpty = checks.isEmpty
        tableView.isHidden = isEmpty
        updatePlaceholderIfDatabaseIsEmpty()
        
        tableView.reloadData()
    }
    
    private func updatePlaceholderIfDatabaseIsEmpty() {
        do {
            let totalCount = try repository.count()
            placeholderViewMain.isHidden = totalCount > 0
        } catch {
            placeholderViewMain.isHidden = true
        }
    }
    
    private func showError(_ error: AppError) {
        let alert = CustomAlertView.show(on: self, type: .error, title: "Ошибка!", message: error.message) { }
        guard let parentView = self.view else { return }
        alert.frame.origin.y = parentView.safeAreaInsets.top
    }
    
    private func createFilterButton(title: String, borderColor: String, addArrow: Bool = false, width: CGFloat) -> UIButton {
        let button = UIButton(type: .system)
        
        var configuration = UIButton.Configuration.plain()
        configuration.title = title
        configuration.baseForegroundColor = UIColor(resource: .filtersText) // Цвет текста и стрелки
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: 14)
            return outgoing
        }
        
        if addArrow {
            if let arrowImage = UIImage(named: "chevron")?.withRenderingMode(.alwaysOriginal) {
                configuration.image = arrowImage
                configuration.imagePlacement = .trailing
                configuration.imagePadding = 2
            }
        }
        
        button.configuration = configuration
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor(resource: .filters).cgColor
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.titleLabel?.numberOfLines = 1
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: width).isActive = true
        button.heightAnchor.constraint(equalToConstant: 28).isActive = true

        return button
    }
    
    private func startScrollingAnimation() {
        scrollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let visibleItems = self.filtersCollectionView.indexPathsForVisibleItems.sorted()
            
            // Найдём текущий индекс последнего видимого элемента
            guard let lastVisibleIndexPath = visibleItems.last else { return }

            // Рассчитаем следующий индекс
            let nextIndex = lastVisibleIndexPath.item + 1

            // Если дошли до конца, возвращаемся к началу
            let nextIndexPath: IndexPath
            
            if nextIndex < self.filtersManager.availableFilters.count {
                nextIndexPath = IndexPath(item: nextIndex, section: 0)
            } else {
                nextIndexPath = IndexPath(item: 0, section: 0)
            }
            
            // Прокручиваем к следующему элементу
            self.filtersCollectionView.scrollToItem(at: nextIndexPath, at: .centeredHorizontally, animated: true)
        }
    }
    
    private func stopScrollingAnimation() {
        scrollTimer?.invalidate()
        scrollTimer = nil
    }
    
    private func showFilters(_ show: Bool) {
        UIView.animate(withDuration: 0.25) {
            self.filtersCollectionView.alpha = show ? 1 : 0
            self.filtersCollectionView.isUserInteractionEnabled = show
            self.filtersCollectionView.isHidden = !show
        }
    }
    
    // MARK: - Actions
    @objc private func addCheck() {
        let addVC = AddCheckViewController(repository: repository)
        let navController = UINavigationController(rootViewController: addVC)
        navController.modalPresentationStyle = .automatic
        navController.navigationBar.backgroundColor = .mainBackground
        present(navController, animated: true, completion: nil)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func handleNewCheckAdded(_ notification: Notification) {
        if let newCheck = notification.object as? Receipt {
            checks.insert(newCheck, at: 0)
            checks.sort { $0.dateTime > $1.dateTime }
            updateUI()
        }
    }
    
    @objc private func handleReceiptsDidChange() {
        filtersManager.fetchNextPage()
        updateUI()
    }
    
    @objc private func handleReceiptsDidImport() {
        filtersManager.fetchNextPage()
        updateUI()
    }
}

// MARK: Делегат FiltersManagerDelegate
extension ChecksViewController: FiltersManagerDelegate {
    func didUpdateChecks(_ checks: [Receipt]) {
        print("✅ Обновляем UI. Чеков загружено: \(checks.count)")
        self.checks = checks
        updateUI()
    }
}

// MARK: - UITableViewDataSource
extension ChecksViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return checks.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CheckCell",
                                                       for: indexPath) as? CheckCell
        else {
            return UITableViewCell()
        }
        
        cell.delegate = self
        cell.selectionStyle = .none
        cell.backgroundColor = UIColor(resource: .mainBackground)
        cell.configure(with: checks[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ChecksViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        
        // Виброотклик
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()
        
        Loader.show()
        
        // Анимация сжатия ячейки
        UIView.animate(withDuration: 0.1, animations: {
            cell.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }, completion: { _ in
            // Возвращаем ячейку к нормальному состоянию
            UIView.animate(withDuration: 0.1, animations: {
                cell.transform = .identity
            }, completion: { _ in
                tableView.deselectRow(at: indexPath, animated: false)
                
                let receipt = self.checks[indexPath.row]
                let receiptVC = ReceiptViewController(receipt: receipt, shouldShowSuccessAlert: false)
                let navController = UINavigationController(rootViewController: receiptVC)
                navController.modalPresentationStyle = .pageSheet
                navController.navigationBar.backgroundColor = .mainBackground
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    Loader.dismiss()
                    self.present(navController, animated: true, completion: nil)
                }
            })
        })
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard checks.count >= 5 else { return }

        let offsetY = scrollView.contentOffset.y

        if offsetY > 20, !isTopControlsHidden {
            isTopControlsHidden = true
            UIView.animate(withDuration: 0.25, animations: {
                self.topControlsContainer.alpha = 0
                self.topControlsContainer.isUserInteractionEnabled = false
                self.searchBar.isHidden = true
                self.filtersCollectionView.isHidden = true

                // Изменяем констрейнт таблицы
                self.tableViewTopConstraint.constant = -self.topControlsDesiredHeight
                self.view.layoutIfNeeded()
            })
        } else if offsetY <= 0, isTopControlsHidden {
            isTopControlsHidden = false
            UIView.animate(withDuration: 0.25, animations: {
                self.topControlsContainer.alpha = 1
                self.topControlsContainer.isUserInteractionEnabled = true
                self.searchBar.isHidden = false
                self.filtersCollectionView.isHidden = false

                // Возвращаем констрейнт таблицы
                self.tableViewTopConstraint.constant = 0
                self.view.layoutIfNeeded()
            })
        }
        
        let contentHeight = scrollView.contentSize.height
        let scrollHeight = scrollView.frame.size.height
        if offsetY > contentHeight - scrollHeight - 100 {
            filtersManager.fetchNextPage()
        }
    }
}

// MARK: - UITableViewDataSourcePrefetching
extension ChecksViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        // Если среди префетч-индексов есть «близкие к концу», загружаем следующую страницу
        if indexPaths.contains(where: { $0.row >= checks.count - 10 }) {
            filtersManager.fetchNextPage()
        }
    }
}

// MARK: - Поиск
extension ChecksViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            // Если строка поиска пуста, сбрасываем результаты и показываем все
            filtersManager.applySearch(nil) // Очистка поиска
            showFilters(true) // Показываем фильтры
            return
        }
        
        // Если есть текст в поиске, скрываем фильтры и применяем поиск
        showFilters(false)
        filtersManager.applySearch(searchText)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
        
        // Обновляем констрейнт trailing
        UIView.animate(withDuration: 0.25) {
            self.searchBarTrailingConstraint.constant = -17 // Уменьшаем ширину для кнопки Cancel
            self.view.layoutIfNeeded()
        }
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        if searchBar.text?.isEmpty ?? true {
            searchBar.setShowsCancelButton(false, animated: true)
            
            // Восстанавливаем полный размер searchBar
            UIView.animate(withDuration: 0.25) {
                self.searchBarTrailingConstraint.constant = -10
                self.view.layoutIfNeeded()
            }
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.endEditing(true)
        searchBar.setShowsCancelButton(false, animated: true)
        
        // Восстанавливаем полный размер searchBar
        UIView.animate(withDuration: 0.25) {
            self.searchBarTrailingConstraint.constant = -10
            self.view.layoutIfNeeded()
        }
        
        showFilters(true) // Показываем фильтры
        filtersManager.applySearch(nil) // Очистка поиска
    }
}

// MARK: Удаление чека, выбор ячейки чека
extension ChecksViewController: CheckCellDelegate {
    func didTapView(on cell: CheckCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let receipt = checks[indexPath.row]
        
        let receiptVC = ReceiptViewController(receipt: receipt, shouldShowSuccessAlert: false)
        let navController = UINavigationController(rootViewController: receiptVC)
        navController.navigationBar.backgroundColor = .mainBackground
        navController.modalPresentationStyle = .pageSheet
        present(navController, animated: true)
    }
    
    func didTapLocationButton(with address: String) {
        openMap(with: address)
    }
    
    func didTapDelete(on cell: CheckCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        deleteCheck(at: indexPath)
    }
    
    private func deleteCheck(at indexPath: IndexPath) {
        let receipt = checks[indexPath.row]
        do {
            try repository.delete(receipt)
            checks.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            updateUI()

            // Показываем контейнер, если чеков осталось меньше 5
            if checks.count < 5 {
                isTopControlsHidden = false
                UIView.animate(withDuration: 0.25) {
                    self.topControlsHeightConstraint.constant = self.topControlsDesiredHeight
                    self.view.layoutIfNeeded()
                }
            }
        } catch {
            showError(.failedToDeleteReceipt(error))
        }
    }
    
    private func openMap(with address: String) {
        let raw = UserDefaults.standard.string(forKey: "selectedMapProvider")
        let provider = MapProvider(rawValue: raw ?? "") ?? .apple
        let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? address

        switch provider {
        case .apple:
            let searchRequest = MKLocalSearch.Request()
            searchRequest.naturalLanguageQuery = address
            let search = MKLocalSearch(request: searchRequest)
            search.start { (response, error) in
                guard let coordinate = response?.mapItems.first?.placemark.coordinate else {
                    self.showError(.placeNotFound(address))
                    return
                }
                let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
                mapItem.name = address
                mapItem.openInMaps()
            }

        case .yandex:
            if let appURL = URL(string: "yandexmaps://maps.yandex.ru/?text=\(encoded)"),
               UIApplication.shared.canOpenURL(appURL) {
                UIApplication.shared.open(appURL)
            } else if let webURL = URL(string: "https://yandex.ru/maps/?text=\(encoded)") {
                UIApplication.shared.open(webURL)
            }

        case .google:
            if let appURL = URL(string: "comgooglemaps://?q=\(encoded)"),
               UIApplication.shared.canOpenURL(appURL) {
                UIApplication.shared.open(appURL)
            } else if let webURL = URL(string: "https://www.google.com/maps/search/?api=1&query=\(encoded)") {
                UIApplication.shared.open(webURL)
            }

        case .dgis:
            if let appURL = URL(string: "dgis://2gis.ru/search/\(encoded)"),
               UIApplication.shared.canOpenURL(appURL) {
                UIApplication.shared.open(appURL)
            } else if let webURL = URL(string: "https://2gis.kz/search/\(encoded)") {
                UIApplication.shared.open(webURL)
            }
        }
    }
}

extension NSLayoutConstraint {
    func with(priority: UILayoutPriority) -> Self {
        self.priority = priority
        return self
    }
}

// MARK: Filters
extension ChecksViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filtersManager.availableFilters.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChipCell.reuseIdentifier, for: indexPath) as? ChipCell else {
            return UICollectionViewCell()
        }

        let filter = filtersManager.availableFilters[indexPath.row]
        let isSelected = filtersManager.activeFilter.title == filter.title

        cell.configure(with: filter.title)
        cell.setSelected(isSelected, animated: false)

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let filter = filtersManager.availableFilters[indexPath.row]
        return ChipCell.calculateSize(for: filter.title)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedFilter = filtersManager.availableFilters[indexPath.row]
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()

        if selectedFilter is PlaceholderDateFilter || selectedFilter is DateFilter {
            showDatePicker() // Всегда открываем DatePicker
        } else {
            filtersManager.applyFilter(selectedFilter)
        }

        collectionView.reloadData()
    }
    
    private func showDatePicker() {
        let alertController = UIAlertController(title: "Выберите дату", message: nil, preferredStyle: .alert)
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.locale = Locale(identifier: "ru_RU")
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.maximumDate = Calendar.current.startOfDay(for: Date())
        
        // Если уже была выбрана дата, устанавливаем её
        if let selectedDate = filtersManager.selectedDateFilter?.date {
            datePicker.date = selectedDate
        }
        
        alertController.view.addSubview(datePicker)
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            datePicker.leadingAnchor.constraint(equalTo: alertController.view.leadingAnchor, constant: 20),
            datePicker.trailingAnchor.constraint(equalTo: alertController.view.trailingAnchor, constant: -20),
            datePicker.topAnchor.constraint(equalTo: alertController.view.topAnchor, constant: 50),
            datePicker.bottomAnchor.constraint(equalTo: alertController.view.bottomAnchor, constant: -50)
        ])
        
        let confirmAction = UIAlertAction(title: "Применить", style: .default) { _ in
            self.filtersManager.applyDateFilter(for: datePicker.date)
            self.filtersCollectionView.reloadData()
        }
        
        let cancelAction = UIAlertAction(title: "Отмена", style: .cancel) { _ in
            self.filtersManager.clearDateFilter() // При отмене сбрасываем дату
            self.filtersCollectionView.reloadData()
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }
}
