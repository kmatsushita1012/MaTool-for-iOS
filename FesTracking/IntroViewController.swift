//
//  IntroViewController.swift
//  FesTracking
//
//  Created by 松下和也 on 2024/02/22.
//

import UIKit

class IntroViewController:BaseViewController,UIPickerViewDataSource, UIPickerViewDelegate{
    private var  appDelegate = UIApplication.shared.delegate as! AppDelegate
    @IBOutlet weak var townButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var descriptionContainerView: UIView!
    @IBOutlet weak var townButtonContainer: UIView!
    @IBOutlet weak var descriptionView: UITextView!
    var containerView:UIView?
    var currentTown:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = UIColor(red: 0.50196, green: 0.13725, blue: 0.45490, alpha: 1.0)
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        navigationItem.setTitleView(withTitle: "各町紹介", subTitile: "")
        
        let imageTapGesture = UITapGestureRecognizer(target: self, action: #selector(imageViewTapped(_:)))
        imageView.addGestureRecognizer(imageTapGesture)
        imageView.isUserInteractionEnabled = true
        imageView.layer.cornerRadius = 10
        descriptionContainerView.layer.cornerRadius = 10
        
        if let defaultTown = UserDefaults.standard.string(forKey: "town"),
            defaultTown != "全て"{
            if self.currentTown == nil{
                self.currentTown = defaultTown
            }
            if self.currentTown == defaultTown{
                favoriteButton.setImage(UIImage(systemName: "star.fill"), for: .normal)
            }else{
                favoriteButton.setImage(UIImage(systemName: "star"), for: .normal)
            }
        }else{
            if self.currentTown == nil{
                self.currentTown = appDelegate.towns[1]
            }
        }
        //TODO 情報取得
        self.getInfo()
        townButton.setTitle(self.currentTown, for: .normal)
        townButtonContainer.layer.cornerRadius = 10
    }
    func setVC(town:String){
        self.currentTown = town
    }
    func getInfo(){
        if let url = appDelegate.app.getString("infoURL"),
           let currentTown = self.currentTown{
            var queryItems:[String:String] = [
                "id":currentTown,
            ]
            ServerRequest.get(url: url, params: queryItems, callbackFunc: self.callbackGetInfo,errorCallBackFunc: self.exceptGetInfo)
        }
    }
    func callbackGetInfo(responseData:Data){
        do{
            let json = try JSONSerialization.jsonObject(with: responseData, options: [])as![[String:Any]]
            //print("受信したJSONデータ: \(json.first)")
            if  let jsonInfo = json.first,
                let description = jsonInfo["description"] as? String,
                let imageURL = jsonInfo["imageURL"] as? String{
                descriptionView.text = description
                UIImage.loadImageFromURL(urlStr: imageURL,view: self.view) { image in
                    if let image = image {
                        DispatchQueue.main.async {
                            self.imageView.image = image
                        }
                    }
                }
            }
            
        } catch {
            //print("JSONパースエラー: \(error)")
        }
    }
    @IBAction func townButtonTapped(_ sender: UIButton) {
        showPickerView()
    }
    
    @IBAction func favoriteButtonTapped(_ sender: UIButton) {
        if let currentTown = self.currentTown{
            let alertController = UIAlertController(title: "登録完了", message: "\(currentTown)をお気に入りに登録しました", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
                UserDefaults.standard.set(self.currentTown, forKey: "town")
                self.favoriteButton.setImage(UIImage(systemName: "star.fill"), for: .normal)
            }
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
        
    }
    @IBAction func locationButtonTapped(_ sender: UIButton) {
        let storyboard: UIStoryboard = self.storyboard!
        let vc = storyboard.instantiateViewController(withIdentifier: "MapViewController") as!MapViewController
        pushFromRootVC(vc: vc)
    }
    @IBAction func backButtonTapped(_ sender: UIBarButtonItem) {
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
    @objc func doneButtonTapped(){
        UIView.animate(withDuration: 0.3, animations: {
            self.containerView?.alpha = 0 // アルファ値を0にしてフェードアウトさせる
        }) { (finished) in
            // アニメーションが完了した後の処理
            self.containerView?.removeFromSuperview()
        }
        townButton.layer.cornerRadius = 10
        townButton.setTitle(self.currentTown, for: .normal)
        if let defaultTown = UserDefaults.standard.string(forKey: "town"){
            if self.currentTown == defaultTown{
                favoriteButton.setImage(UIImage(systemName: "star.fill"), for: .normal)
            }else{
                favoriteButton.setImage(UIImage(systemName: "star"), for: .normal)
            }
        }
        descriptionView.text = ""
        imageView.image = UIImage(systemName: "photo")
        self.getInfo()
    }
    @objc func imageViewTapped(_ gesture: UITapGestureRecognizer){
        let storyboard: UIStoryboard = self.storyboard!
        let imageVC = storyboard.instantiateViewController(withIdentifier: "ImageViewController") as! ImageViewController
        imageVC.setVC(image: imageView.image!)
        imageVC.modalTransitionStyle = .crossDissolve
        imageVC.modalPresentationStyle = .overCurrentContext
        self.present(imageVC, animated: true, completion: nil)
    }

    func showPickerView(){
        let pickerViewHeight: CGFloat = 200 // UIPickerViewの高さ
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        // 下部に表示されるUIViewを作成
        self.containerView = UIView(frame: CGRect(x: 0, y: screenHeight, width: screenWidth, height: pickerViewHeight + 44))
        containerView!.backgroundColor = .white
        let pickerView = UIPickerView(frame: CGRect(x: 0, y: 44, width: screenWidth, height: pickerViewHeight))
        pickerView.backgroundColor = .systemGray5
        pickerView.dataSource = self // 必要に応じてデータソースを設定
        pickerView.delegate = self // 必要に応じてデリゲートを設定
        containerView!.addSubview(pickerView)
        let borderLayer = CALayer()
        borderLayer.frame = CGRect(x: 0, y: 0, width: containerView!.frame.size.width, height: 1.0)
        borderLayer.backgroundColor = UIColor.systemGray4.cgColor
        containerView!.layer.addSublayer(borderLayer)
        if  let currentTown = self.currentTown,
            let index = appDelegate.towns.firstIndex(of: currentTown){
            pickerView.selectRow(index, inComponent: 0, animated: false)
        }
        // Doneボタンを作成
        let doneButton = UIButton(type: .system)
        doneButton.frame = CGRect(x: screenWidth - 70, y: 0, width: 70, height: 44)
        doneButton.setTitle("完了", for: .normal)
        doneButton.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        containerView!.addSubview(doneButton)

        // containerViewを画面に追加
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
        return appDelegate.towns.count-1 // データソースの要素数を返す
        }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return appDelegate.towns[row+1] // データソースから各行のタイトルを返す
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.currentTown = appDelegate.towns[row+1] // 選択された行に対応するデータソースの要素を取得
    }
    func exceptGetInfo(errorType:ServerRequest.Error){
        var message = ""
        switch errorType {
        case .DataTask:
            message = "ネットワーク接続に問題があります。Wi-fiもしくはモバイルデータ通信の接続状況を確認してください。"
        case .InvaliedResponce:
            message = "サーバーが応答していません。時間をおいて再度お試しください。"
        case .InvaliedStatusCode:
            message = "正常に処理されませんでした。時間をおいて再度お試しください。"
        case .NoData:
            message = "データが存在しません。"
        default:
            message = "予期せぬエラーが発生しました。"
        }
        let alertController = UIAlertController(title: "エラー", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
        }
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
        
    }
}
