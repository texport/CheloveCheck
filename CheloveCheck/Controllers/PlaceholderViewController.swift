//
//  PlaceholderViewController.swift
//  CheloveCheck
//
//  Created by Sergey Ivanov on 05.01.2025.
//

import UIKit

final class PlaceholderViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .mainBackground
        
        let label = UILabel()
        label.text = "Раздел находится в разработке"
        label.textColor = .mainTextColors
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
