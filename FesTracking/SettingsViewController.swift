//
//  SettingsViewController.swift
//  FesTracking
//
//  Created by 松下和也 on 2024/02/08.
//

import UIKit

class SettingsViewController :BaseViewController, UITableViewDelegate,UITableViewDataSource,UIPickerViewDataSource, UIPickerViewDelegate{

    
    private var  appDelegate = UIApplication.shared.delegate as! AppDelegate
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    var currentTown: String?
    var containerView:UIView?
    
    override func viewDidLoad() {
        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = UIColor(red: 0.50196, green: 0.13725, blue: 0.45490, alpha: 1.0)
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        navigationItem.setTitleView(withTitle: "設定", subTitile: "")
        tableView.register(UINib(nibName: "SwitchTableViewCell", bundle: nil), forCellReuseIdentifier: "SwitchTableViewCell")
        tableView.register(UINib(nibName: "ListTableViewCell", bundle: nil), forCellReuseIdentifier: "ListTableViewCell")
        tableView.layer.cornerRadius = 10
        
        
        if let town = UserDefaults.standard.string(forKey: "town"){
            self.currentTown = town
        }
    }
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        heightConstraint.constant = CGFloat(tableView.contentSize.height)
    }
    
    @IBAction func backButton(_ sender: UIBarButtonItem) {
        if let nav = navigationController{
            nav.popViewController(animated: true)
        }
    }
    @IBAction func menuButtonTapped(_ sender: UIBarButtonItem) {
        let storyboard: UIStoryboard = self.storyboard!
        let vc = storyboard.instantiateViewController(withIdentifier: "MenuViewController") as! MenuViewController
        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        vc.delegate = self
        self.present(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.item {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ListTableViewCell", for: indexPath) as! ListTableViewCell
            //TODO リスト
            if  let currentTown = self.currentTown,
                let index = appDelegate.towns.firstIndex(of: currentTown){
                cell.setCell(labelText:  "マイ屋台", options:self.appDelegate.towns,defaultIndex: index)
            }else{
                cell.setCell(labelText:  "マイ屋台", options:self.appDelegate.towns,defaultIndex: 0)
            }
            return cell
        case 1:
            let isOn = UserDefaults.standard.bool(forKey: "diplomat")
            let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchTableViewCell", for: indexPath) as! SwitchTableViewCell
            cell.setCell(labelText: "外交モード",isOn: isOn,returnFunc: self.changeDiplomatMode)
            return cell
            
            
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "NormalTableViewCell", for: indexPath)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            showPickerView()
            tableView.reloadData()
        default:
            break
        }
    }
    
    func showPickerView(){
        let pickerViewHeight: CGFloat = 200 // UIPickerViewの高さ
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        // 下部に表示されるUIViewを作成
        self.containerView = UIView(frame: CGRect(x: 0, y: screenHeight, width: screenWidth, height: pickerViewHeight + 44))
        containerView!.backgroundColor = .white // 背景色を白に設定（任意）
        let borderLayer = CALayer()
        borderLayer.frame = CGRect(x: 0, y: 0, width: containerView!.frame.size.width, height: 1.0)
        borderLayer.backgroundColor = UIColor.systemGray4.cgColor
        containerView!.layer.addSublayer(borderLayer)
        let pickerView = UIPickerView(frame: CGRect(x: 0, y: 44, width: screenWidth, height: pickerViewHeight))
        pickerView.backgroundColor = .systemGray5
        pickerView.dataSource = self // 必要に応じてデータソースを設定
        pickerView.delegate = self // 必要に応じてデリゲートを設定
        if  let currentTown = self.currentTown,
            let index = appDelegate.towns.firstIndex(of: currentTown){
            pickerView.selectRow(index, inComponent: 0, animated: false)
        }
        containerView!.addSubview(pickerView)
        
        // Doneボタンを作成
        let doneButton = UIButton(type: .system)
        doneButton.frame = CGRect(x: screenWidth - 70, y: 0, width: 70, height: 44)
        doneButton.setTitle("完了", for: .normal)
        doneButton.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        containerView!.addSubview(doneButton)
        if let parent = self.parent{
            parent.view.addSubview(containerView!)
        }
        // アニメーションでUIViewを表示
        UIView.animate(withDuration: 0.3) {
            self.containerView!.frame.origin.y = screenHeight - pickerViewHeight - 44 // 下部から表示
        }
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return appDelegate.towns.count // データソースの要素数を返す
        }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return appDelegate.towns[row] // データソースから各行のタイトルを返す
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.currentTown = appDelegate.towns[row]
    }
    
    func changeDiplomatMode(isOn: Bool) {
        UserDefaults.standard.set(isOn, forKey: "diplomat")
        UserDefaults.standard.synchronize()
    }
    
    @objc func doneButtonTapped(){
        UIView.animate(withDuration: 0.3, animations: {
            self.containerView?.alpha = 0 // アルファ値を0にしてフェードアウトさせる
        }) { (finished) in
            // アニメーションが完了した後の処理
            self.containerView?.removeFromSuperview()
        }
        self.changeMyTown()
    }
    func changeMyTown(){
        UserDefaults.standard.set(self.currentTown, forKey: "town")
        UserDefaults.standard.synchronize()
        tableView.reloadData()
    }
}
