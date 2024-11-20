//
//  BaseViewController.swift
//  FesTracking
//
//  Created by 松下和也 on 2024/03/14.
//

import UIKit

class BaseViewController: UIViewController, MenuDelegate{
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    func pushFromRootVC(vc: UIViewController) {
        if let nav = navigationController{
            nav.modalPresentationStyle = .fullScreen
            nav.modalTransitionStyle = .crossDissolve
            nav.pushViewController(vc, animated: true)
        }
    }
}
protocol MenuDelegate {
    func pushFromRootVC(vc:UIViewController)
}
