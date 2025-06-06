//
//  SettingsViewController.swift
//  CheloveCheck
//
//  Created by Sergey Ivanov on 10.01.2025.
//

import UIKit

final class MainTabBarController: UITabBarController, UITabBarControllerDelegate {
    let receiptRepository: ReceiptRepository
    
    init() {
        self.receiptRepository = ReceiptRepository(context: CoreDataManager.shared.context)
        super.init(nibName: nil, bundle: nil)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.receiptRepository = ReceiptRepository(context: CoreDataManager.shared.context)
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        self.receiptRepository = ReceiptRepository(context: CoreDataManager.shared.context)
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self

        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .mainBackground
            tabBar.standardAppearance = appearance
            tabBar.scrollEdgeAppearance = appearance
        } else {
            tabBar.barTintColor = .mainBackground
            tabBar.isTranslucent = false
        }
        
        view.backgroundColor = .mainBackground
        
        let checksVC = ChecksViewController(repository: receiptRepository)
        let addVC = AddCheckViewController(repository: receiptRepository)
        //let costVC = PlaceholderViewController()
        let settingsVC = SettingsViewController()
        
        viewControllers = [
            createNavController(for: checksVC, title: "Мои чеки", image: UIImage(systemName: "doc.text.magnifyingglass") ?? UIImage()),
            createNavController(for: addVC, title: "Добавить", image: UIImage(systemName: "plus.circle.fill") ?? UIImage()),
            //createNavController(for: costVC, title: "Расходы", image: UIImage(systemName: "tengesign.circle") ?? UIImage()),
            createNavController(for: settingsVC, title: "Настройки", image: UIImage(systemName: "gearshape.fill") ?? UIImage())
        ]
    }
    
    private func createNavController(for rootViewController: UIViewController, title: String, image: UIImage) -> UINavigationController {
        let navController = UINavigationController(rootViewController: rootViewController)
        rootViewController.title = title
        navController.tabBarItem.title = title
        navController.tabBarItem.image = image
        return navController
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if let navController = viewController as? UINavigationController,
           let rootVC = navController.viewControllers.first,
           rootVC is AddCheckViewController {
            presentAddCheckScreen()
            return false
        }
        return true
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if selectedIndex == 0,
           let navController = viewController as? UINavigationController,
           let checksVC = navController.viewControllers.first as? ChecksViewController {
            checksVC.scrollToTop()
        }
    }
    
    // MARK: - Модальное представление
    private func presentAddCheckScreen() {
        let addVC = AddCheckViewController(repository: receiptRepository)
        let navController = UINavigationController(rootViewController: addVC)
        navController.modalPresentationStyle = .automatic
        navController.navigationBar.backgroundColor = .mainBackground
        present(navController, animated: true, completion: nil)
    }
}
