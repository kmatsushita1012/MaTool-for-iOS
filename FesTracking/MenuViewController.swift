//
//  MenuViewController.swift
//  FesTracking
//
//  Created by 松下和也 on 2024/02/12.
//

import UIKit

class MenuViewController: UIViewController,UITableViewDataSource,UITableViewDelegate {
    private var  appDelegate = UIApplication.shared.delegate as! AppDelegate
    @IBOutlet weak var menuView: UIView!
    @IBOutlet weak var tableView: UITableView!
    var delegate: MenuDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // メニューの位置を取得する
        let menuPos = self.menuView.layer.position
        // 初期位置を画面の外側にするため、メニューの幅の分だけマイナスする
        self.menuView.layer.position.x = self.view.frame.width + self.menuView.frame.width
        // 表示時のアニメーションを作成する
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            options: .curveEaseOut,
            animations: {
                self.menuView.layer.position.x = menuPos.x
        },
            completion: { bool in
        })
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "MenuTableViewCell", bundle: nil), forCellReuseIdentifier: "MenuTableViewCell")
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        for touch in touches {
            if touch.view?.tag == 1 {
                UIView.animate(
                    withDuration: 0.2,
                    delay: 0,
                    options: .curveEaseIn,
                    animations: {
                        self.menuView.layer.position.x = self.view.frame.width + self.menuView.frame.width
                },
                    completion: { bool in
                        self.dismiss(animated: true, completion: nil)
                }
                )
            }
        }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.item {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
            cell.textLabel?.text = "ホーム"
            cell.imageView?.image = UIImage(systemName: "house")
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
            cell.textLabel?.text = "マップ"
            cell.imageView?.image = UIImage(systemName: "mappin.and.ellipse")
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
            cell.textLabel?.text = "各町紹介"
            cell.imageView?.image = UIImage(systemName: "doc.text.image")
            return cell
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
            cell.textLabel?.text = "設定"
            cell.imageView?.image = UIImage(systemName: "gearshape.fill")
            return cell
        case 4:
            let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
            cell.textLabel?.text = "使い方"
            cell.imageView?.image = UIImage(systemName: "questionmark.circle.fill")
            return cell
        case 5:
            let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
            cell.textLabel?.text = "お問い合わせ"
            cell.imageView?.image = UIImage(systemName: "envelope")
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
            return cell
        }
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let delegate = self.delegate{
            self.dismiss(animated: false)
            var vc:UIViewController
            switch indexPath.row {
            case 0:
                let storyboard: UIStoryboard = self.storyboard!
                vc = storyboard.instantiateViewController(withIdentifier: "TopViewController") as! TopViewController
                delegate.pushFromRootVC(vc: vc)
            case 1:
                let storyboard: UIStoryboard = self.storyboard!
                vc = storyboard.instantiateViewController(withIdentifier: "MapViewController") as!MapViewController
                delegate.pushFromRootVC(vc: vc)
            case 2:
                let storyboard: UIStoryboard = self.storyboard!
                vc = storyboard.instantiateViewController(withIdentifier: "IntroViewController") as!IntroViewController
                delegate.pushFromRootVC(vc: vc)
            case 3:
                let storyboard: UIStoryboard = self.storyboard!
                vc = storyboard.instantiateViewController(withIdentifier: "SettingsViewController") as!SettingsViewController
                delegate.pushFromRootVC(vc: vc)
            case 4:
                if let urlString = appDelegate.app.getString("userguideURL"),
                   let url = URL(string: urlString) {
                    // URLをデフォルトのブラウザで開く
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
                
            case 5:
                if let urlString = appDelegate.app.getString("formURL"),
                   let url = URL(string: urlString) {
                    // URLをデフォルトのブラウザで開く
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            default:
                break
            }
            
            
        }
    }
}

