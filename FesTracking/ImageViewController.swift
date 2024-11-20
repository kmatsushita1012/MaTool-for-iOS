//
//  ImageViewController.swift
//  FesTracking
//
//  Created by 松下和也 on 2024/02/22.
//

import UIKit

class ImageViewController: UIViewController {
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    var image:UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        backButton.layer.cornerRadius = 20
        if let image = self.image{
            imageView.image = image
        }
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        // UIPanGestureRecognizerを追加
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        imageView.addGestureRecognizer(panGesture)
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        imageView.addGestureRecognizer(pinchGesture)
    }
    func setVC(image:UIImage){
        self.image = image
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard gesture.view != nil else { return }
        let translation = gesture.translation(in: view)
        gesture.view!.center = CGPoint(x: gesture.view!.center.x + translation.x, y: gesture.view!.center.y + translation.y)
        gesture.setTranslation(CGPoint.zero, in: view)
    }
    
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard gesture.view != nil else { return }
        if gesture.state == .began || gesture.state == .changed {
            gesture.view?.transform = (gesture.view?.transform.scaledBy(x: gesture.scale, y: gesture.scale))!
            gesture.scale = 1.0
        }
    }
    @IBAction func backButtonTapped(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
}

