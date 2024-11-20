//
//  ViewController.swift
//  FesTracking
//
//  Created by 松下和也 on 2024/02/07.
//

import UIKit
import MapKit
class TopViewController: BaseViewController, MKMapViewDelegate{
    
    private var  appDelegate = UIApplication.shared.delegate as! AppDelegate
    @IBOutlet weak var mapView: UIView!
    @IBOutlet weak var introView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.setTitleView(withTitle: "MaTool", subTitile: "")
        
        mapView.layer.cornerRadius = 10
        let mapTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
        mapView.addGestureRecognizer(mapTapGesture)
        
        let centerCoordinate = CLLocationCoordinate2D(latitude: 34.77288, longitude:  138.01531)
        let region = MKCoordinateRegion(center: centerCoordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        
        introView.layer.cornerRadius = 10
        
        let introTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleIntroTap(_:)))
        introView.addGestureRecognizer(introTapGesture)
    }
    @objc func handleMapTap(_ gesture: UITapGestureRecognizer) {
        let storyboard: UIStoryboard = self.storyboard!
        let vc = storyboard.instantiateViewController(withIdentifier: "MapViewController") as!MapViewController
        pushFromRootVC(vc: vc)
    }
    @objc func handleIntroTap(_ gesture: UITapGestureRecognizer) {
        let storyboard: UIStoryboard = self.storyboard!
        let vc = storyboard.instantiateViewController(withIdentifier: "IntroViewController")
        pushFromRootVC(vc: vc)
        
    }

    @IBAction func settingsButtonTapped(_ sender: Any) {
        let storyboard: UIStoryboard = self.storyboard!
        let vc = storyboard.instantiateViewController(withIdentifier: "SettingsViewController")
        pushFromRootVC(vc: vc)
    }
    
    @IBAction func menuButtonTapped(_ sender: UIBarButtonItem) {
        let storyboard: UIStoryboard = self.storyboard!
        let vc = storyboard.instantiateViewController(withIdentifier: "MenuViewController") as! MenuViewController
        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        vc.delegate = self
        self.present(vc, animated: true)
    }
    @IBAction func guideButtonTapped(_ sender: UIBarButtonItem) {
        // URL文字列をURLオブジェクトに変換
        if let urlString = appDelegate.app.getString("userguideURL"),
           let url = URL(string: urlString) {
            // URLをデフォルトのブラウザで開く
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    
    }
    
}

