//
//  MapViewController.swift
//  FesTracking
//
//  Created by 松下和也 on 2024/02/12.
//


import UIKit
import MapKit
class MapViewController: BaseViewController,MKMapViewDelegate,CLLocationManagerDelegate,UIPickerViewDataSource,UIPickerViewDelegate{
    private var  appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    
    @IBOutlet weak var dayButton: UIButton!
    @IBOutlet weak var periodButton: UIButton!
    @IBOutlet weak var townButton: UIButton!
    @IBOutlet weak var currentButton: UIButton!
    @IBOutlet weak var floatButton: UIButton!
    @IBOutlet weak var reloadButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet var slider: UISlider!
    @IBOutlet var animationButton: UIButton!
    
    var containerView:UIView?
    let loadingAlert = LoadingAlert()
    
    var currentDay : Day = Day.getCurrentDay()
    var currentPeriod : Period = Period.getCurrentPeriod()
    var currentTown : String?
    var floatLocation:CustomLocation?
    let locationManager = CLLocationManager()
    var selectedTown = "全て"
    var routeCounter = 0
    
    var floatAnnotation:CustomAnnotation?
    var isAnimationRunning = false
    var polylines: [MKPolyline] = []
    var currentPolylineIndex = 0
    var timer: Timer?
    var currentIndex = 0
    var currentCoordinate = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
    
    var yOffset = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.currentTown == nil{
            if let defaultTown = UserDefaults.standard.string(forKey: "town"){
                self.currentTown = defaultTown
            }
        }
        if let yOffset = appDelegate.app.getDouble("yOffset"){
            self.yOffset = yOffset
        }
        navigationItem.setTitleView(withTitle: "地図", subTitile: "")
        mapView.delegate = self
        locationManager.delegate = self
        mapView.showsUserLocation = true
        // 位置情報の取得を開始
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        self.dayButton.setTitle(self.currentDay.text, for: .normal)
        self.periodButton.setTitle(self.currentPeriod.text, for: .normal)
        self.townButton.setTitle(self.currentTown, for: .normal)
        if let coordinate = locationManager.location?.coordinate{
            let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
            self.mapView.setRegion(region, animated: true)
        }
        
        self.getRoute(town: currentTown!,day: currentDay,period: currentPeriod)
        slider.isHidden = true
        enableButtons(isEnable: false)
        // Do any additional setup after loading the view.
    }
    func setVC(town:String){
        self.currentTown = town
    }
    
    func enableButtons(isEnable:Bool){
        floatButton.isEnabled = (floatAnnotation != nil)
        reloadButton.isEnabled = isEnable
        animationButton.isEnabled = isEnable
    }
    
    @IBAction func dayButtonTapped(_ sender: UIButton) {
        var alertController = UIAlertController(title: "選択してください", message: nil, preferredStyle: .actionSheet)
        guard let date = appDelegate.app.getStringArray("Date") else {return}
        for (i,day) in Day.allCases.enumerated(){
            alertController.addAction(UIAlertAction(title: "\(day.text) \(date[i])", style: .default, handler: { (_) in
                self.removeMapObj()
                self.currentDay = day
                self.dayButton.setTitle(self.currentDay.text, for: .normal)
                self.getRoute(town: self.currentTown!,day: self.currentDay, period: self.currentPeriod)
            }))
        }
        alertController.addAction(UIAlertAction(title: "キャンセル", style: .default, handler:{ (_) in
        }))
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = sender
            popoverController.sourceRect = sender.bounds
            popoverController.permittedArrowDirections = .any
        }
        
        // UIAlertControllerのviewにタップジェスチャーを追加
        if let alertControllerView = alertController.view {
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissAlertController))
            alertControllerView.addGestureRecognizer(tapGestureRecognizer)
        }
        
        present(alertController, animated: true, completion: nil)
        
    }
    @IBAction func periodButtonTapped(_ sender: UIButton) {
        var alertController = UIAlertController(title: "選択してください", message: nil, preferredStyle: .actionSheet)
        for period in Period.allCases{
            alertController.addAction(UIAlertAction(title: period.text, style: .default, handler: { (_) in
                self.removeMapObj()
                self.currentPeriod = period
                self.periodButton.setTitle(self.currentPeriod.text, for: .normal)
                self.getRoute(town: self.currentTown!, day: self.currentDay, period: self.currentPeriod)
            }))
        }
        alertController.addAction(UIAlertAction(title: "キャンセル", style: .default, handler:{ (_) in
        }))
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = sender
            popoverController.sourceRect = sender.bounds
            popoverController.permittedArrowDirections = .any
        }
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = sender
            popoverController.sourceRect = sender.bounds
            popoverController.permittedArrowDirections = .any
        }
        
        // UIAlertControllerのviewにタップジェスチャーを追加
        if let alertControllerView = alertController.view {
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissAlertController))
            alertControllerView.addGestureRecognizer(tapGestureRecognizer)
        }
        present(alertController, animated: true, completion: nil)
    }

    @IBAction func townButtonTapped(_ sender: UIButton) {
        self.showPickerView()
    }
    
    @objc func dismissAlertController() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func currentButtonTapped(_ sender: UIButton) {
        if let currentLocation = self.locationManager.location?.coordinate{
            
            self.mapView.setCenter(currentLocation, animated: false)
            currentButton.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
        }else{
            let status = CLLocationManager.authorizationStatus()

            switch status {
            case .authorizedAlways:
                break
            case .authorizedWhenInUse:
                break
            default:
                locationManager.requestWhenInUseAuthorization()
                locationManager.startUpdatingLocation()
                sleep(1)
                if let currentLocation = self.locationManager.location?.coordinate{
                    self.mapView.setCenter(currentLocation, animated: true)
                    currentButton.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)

                }
            }
        }
    }
    @IBAction func floatButtonTapped(_ sender: UIButton) {
        if self.isAnimationRunning{
            self.stopAnimation()
        }
        
        if let floatLocation = self.floatLocation{
            self.mapView.setCenter(floatLocation.coordinate, animated: true)
        }else{
            let alertController = UIAlertController(title: "お知らせ ", message: "\(currentTown)の屋台の位置情報は現在未登録です。", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
                return
            }
            alertController.addAction(okAction)
            present(alertController, animated: true, completion: nil)
        }
    }
    
    @IBAction func reloadButtonTapped(_ sender: UIButton) {
        
        self.getRoute(town: self.currentTown!,day: self.currentDay,period: self.currentPeriod)
        self.removeMapObj()
    }
    
    @IBAction func backButtonTapped(_ sender: UIBarButtonItem) {
        if let nav = navigationController{
            
            UIView.animate(withDuration: 0.3, animations: {
                self.containerView?.alpha = 0 // アルファ値を0にしてフェードアウトさせる
            }) { (finished) in
                // アニメーションが完了した後の処理
                self.containerView?.removeFromSuperview()
            }
            if self.isAnimationRunning{
                self.stopAnimation()
            }
            nav.popViewController(animated: true)
        }
    }
    
    @IBAction func menuButtonTapped(_ sender: UIBarButtonItem) {
        
        UIView.animate(withDuration: 0.3, animations: {
            self.containerView?.alpha = 0 // アルファ値を0にしてフェードアウトさせる
        }) { (finished) in
            // アニメーションが完了した後の処理
            self.containerView?.removeFromSuperview()
        }
        
        let storyboard: UIStoryboard = self.storyboard!
        let vc = storyboard.instantiateViewController(withIdentifier: "MenuViewController") as! MenuViewController
        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        vc.delegate = self
        
        self.stopAnimation()
        
        self.present(vc, animated: true)
    }
    func drawRoute(locations: [CustomLocation],color: UIColor) {
        self.routeCounter = 1
        var start = locations[0]
        if start.event == "なし"{
            start.event = "スタート"
        }else{
            start.event = "スタート \(start.event)"
        }
        self.drawAnnotation(location: start,color: color, type:.Point)
        
        if locations.count >= 2{
            
            Task{
                var totalRect = MKMapRect.null
                for i in 1 ..< locations.count{
                    
                    if locations[i].curveIncluded {
                        let polyline = await self.drawCurveLine(start:locations[i-1],end:locations[i],color: color)
                        if let polyline = polyline{
                            totalRect = totalRect.union(polyline.boundingMapRect)
                        }
                    }else{
                        let polyline = self.drawLine(start:locations[i-1],end:locations[i],color: color)
                        totalRect = totalRect.union(polyline.boundingMapRect)
                    }
                    if locations[i].event != "なし" && i < locations.count - 1 {
                        self.drawAnnotation(location: locations[i],color: color, type:.Point)
                    }
                    
                }
                if var last = locations.last{
                    if last.event == "なし"{
                        last.event = "ゴール"
                    }else{
                        last.event = "ゴール \(last.event)"
                    }
                    self.drawAnnotation(location: last,color: color,type: .Point)
                }
                let extraSpace = totalRect.size.width * 0.1 // 余白のサイズを設定
                totalRect = totalRect.insetBy(dx: -extraSpace, dy: -extraSpace)
                mapView.setVisibleMapRect(totalRect, animated: false)
            }
            
        }
    }
    
    private func  drawAnnotation(location:CustomLocation,color:UIColor,type:CustomAnnotation.AnnotationType){
        // ピンを作成
        var annotation:MKPointAnnotation
        if location.event.contains("余興")||location.event.contains("順路"){
            annotation = CustomAnnotation(coordinate: location.coordinate, title: location.event, subtitle: "", color: color,type: type,glyphText: String(routeCounter))
            routeCounter += 1;
        }else{
            annotation = CustomAnnotation(coordinate: location.coordinate, title: location.event, subtitle: "", color: color,type: type)
        }
        // ピンを地図上に追加
        mapView.addAnnotation(annotation)
    }
    
    private func drawFloatAnnotation(location:CustomLocation,color:UIColor){
        // ピンを作成
        let annotation = CustomAnnotation(coordinate: CLLocationCoordinate2D(latitude: location.coordinate.latitude - mapView.zoomLevel*yOffset, longitude: location.coordinate.longitude), title: location.event, subtitle: "", color: color, type: .Float)
        if location.event != "全て"{
            self.floatAnnotation = annotation
        }
        // ピンを地図上に追加
        mapView.addAnnotation(annotation)
    }
    @IBAction func animationButtonTapped(_ sender: UIButton) {
        if self.isAnimationRunning{
            //進行中なら停止処理
            self.stopAnimation()
            
        }else{
            //停止中なら開始処理
            self.startAnimation()
        }
    }

    private func drawLine(start:CustomLocation,end:CustomLocation,color:UIColor) -> MKPolyline{
        let polyline = MKPolyline(coordinates: [start.coordinate,end.coordinate], count: 2)
        let customPolyline = CustomPolyline(polyline: polyline, color: color)
        mapView.addOverlay(customPolyline,level: .aboveRoads)
        self.polylines.append(polyline)
        return polyline
    }
    private func drawCurveLine(start:CustomLocation,end:CustomLocation,color:UIColor) async -> MKPolyline?{
        let sourcePlaceMark = MKPlacemark(coordinate: start.coordinate)
        let destinationPlaceMark = MKPlacemark(coordinate: end.coordinate)
        let directionRequest = MKDirections.Request()
        directionRequest.source = MKMapItem(placemark: sourcePlaceMark)
        directionRequest.destination = MKMapItem(placemark: destinationPlaceMark)
        directionRequest.transportType = .walking
        let directions = MKDirections(request: directionRequest)
        let directionResponse : MKDirections.Response
        do{
            directionResponse = try await directions.calculate()
        }catch{
            return nil
        }
        let route = directionResponse.routes[0]
        let customPolyline = CustomPolyline(polyline: route.polyline, color: color)
        self.mapView.addOverlay(customPolyline, level: .aboveRoads)
        self.polylines.append(route.polyline)
        return route.polyline
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
        }
    }
    func getRoute(town:String,day:Day, period:Period){
        if self.isAnimationRunning{
            self.stopAnimation()
        }
        self.polylines = [MKPolyline]()
        self.floatAnnotation = nil
        loadingAlert.startAnimating()
        if let url = appDelegate.app.getString("routeURL"){
            
            var queryItems:[String:String] = [:]
            if town != "全て" {
                queryItems = [
                    "id": town,
                    "day": String(day.rawValue),
                    "period": String(period.rawValue)
                ]
            }else{
                queryItems = [
                    "id": "全て",
                ]
            }
            ServerRequest.get(url: url, params: queryItems, callbackFunc: self.callbackGetRoute,errorCallBackFunc: self.exceptGetRoute)
        }
    }
    func callbackGetRoute(responseData:Data){
        loadingAlert.stopAnimating()
        
        do{
            let json = try JSONSerialization.jsonObject(with: responseData, options: [])as![[String:Any]]
            if currentTown == "全て"{
                for jsonTown in json{
                    if let jsonInfo = jsonTown["info"] as?[String:Any],
                       let town = jsonInfo["id"] as? String,
                       let jsonColor = jsonInfo["color"] as? [Double]{
                        let color = UIColor(red: jsonColor[0], green: jsonColor[1], blue: jsonColor[2], alpha: 1.0)
                        if let defaultTown = UserDefaults.standard.string(forKey: "defaultTown"),
                           defaultTown == town{
                            if let jsonCoordinate = jsonInfo["coordinate"] as? [Double]{
                                let location = CustomLocation(latitude: jsonCoordinate[0], longitude: jsonCoordinate[1], event: "\(town)")
                                if let floatAnnotation = floatAnnotation{
                                    mapView.removeAnnotation(floatAnnotation)
                                }
                                let customAnnotation = CustomAnnotation(coordinate: CLLocationCoordinate2D(latitude: location.coordinate.latitude-mapView.zoomLevel*yOffset, longitude: location.coordinate.longitude), title: town, subtitle: "", color: color, type: .Float)
                                mapView.addAnnotation(customAnnotation)
                            }
                        }
                    }
                }
                if let coor = appDelegate.app.getCoordinate("defaultCoordinate"){
                    self.floatLocation = CustomLocation(latitude: coor.latitude, longitude: coor.longitude)
                    
                    if let centerCoordinate = locationManager.location?.coordinate{
                        let region = MKCoordinateRegion(center: centerCoordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
                        self.mapView.setRegion(region, animated: true)
                        currentButton.setImage(UIImage(systemName: "location.fill"), for: .normal)
                    }else{
                        let region = MKCoordinateRegion(center: coor, latitudinalMeters: 1000, longitudinalMeters: 1000)
                        self.mapView.setRegion(region, animated: true)
                        currentButton.setImage(UIImage(systemName: "location"), for: .normal)
                    }
                }
                enableButtons(isEnable: true)
            }else{
                let jsonTown = json[0]
                if let jsonInfo = jsonTown["info"] as?[String:Any],
                   let town = jsonInfo["id"] as? String,
                   let jsonColor = jsonInfo["color"] as? [Double]{
                    let color = UIColor(red: jsonColor[0], green: jsonColor[1], blue: jsonColor[2], alpha: 1.0)
                    if let jsonCoordinate = jsonInfo["coordinate"] as? [Double]{
                        let location = CustomLocation(latitude: jsonCoordinate[0], longitude: jsonCoordinate[1], event: "\(town)")
                        self.floatLocation = location
                        self.drawFloatAnnotation(location: location, color: color)
                        
                    }
                    if let jsonRoute = jsonTown["route"] as? [String :Any]{
                        var locations = [CustomLocation]()
                        for elem in jsonRoute["route"] as![[String :Any]]{
                            if let coordinate = elem["coordinate"] as? [Double],
                               let event = elem["event"] as? String,
                               let curveIncluded = elem["curveIncluded"] as? Bool{
                                locations.append(CustomLocation(latitude: coordinate[0], longitude: coordinate[1], event: event, curveIncluded: curveIncluded))
                            }
                        }
                        self.drawRoute(locations: locations,color:color)
                        enableButtons(isEnable: true)
                    }else{
                        enableButtons(isEnable: false)
                        let alertController = UIAlertController(title: "お知らせ", message: "指定された日程は未登録です。", preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
                            return
                        }
                        alertController.addAction(okAction)
                        present(alertController, animated: true, completion: nil)
                    }
                }
            }
            
        } catch {
            enableButtons(isEnable: false)
            let alertController = UIAlertController(title: "エラー", message: "データが存在しません。", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
                return
            }
            alertController.addAction(okAction)
            present(alertController, animated: true, completion: nil)
        }
    }
    func exceptGetRoute(errorType:ServerRequest.Error){
        enableButtons(isEnable: false)
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
            return
        }
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
        
    }
    func removeMapObj(){
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
    }
    func showPickerView(){
        self.selectedTown = self.currentTown!
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
        if let index = appDelegate.towns.firstIndex(of: currentTown!){
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
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline{
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor =  .systemRed
            renderer.lineWidth = 3
            return renderer
        }else if let customPolyline = overlay as? CustomPolyline{
            let renderer = MKPolylineRenderer(polyline: customPolyline.polyline)
            //変更
//            renderer.strokeColor =  customPolyline.color
            renderer.strokeColor =  .systemRed
            renderer.lineWidth = 3
            return renderer
        }
        return MKOverlayRenderer()
    }
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // 現在の位置情報以外の場合
        guard !(annotation is MKUserLocation) else {
            return nil
        }
        
        if let customAnnotation = annotation as? CustomAnnotation{
            if customAnnotation.type == CustomAnnotation.AnnotationType.Point{
                let identifier = "PointAnnotationView"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                
                if annotationView == nil {
                    annotationView = MKMarkerAnnotationView(annotation: customAnnotation, reuseIdentifier: identifier)
                } else {
                    annotationView?.annotation = annotation
                }
                //変更
//                annotationView?.markerTintColor = customAnnotation.color
                annotationView?.markerTintColor = .systemRed
                annotationView?.glyphImage = customAnnotation.image
                annotationView?.glyphText = customAnnotation.glyphText
                annotationView?.displayPriority = .required
                annotationView?.zPriority = .min
                annotationView?.canShowCallout = false
                
                
                return annotationView
            }else{
                
                let reuseIdentifier = "FloatAnnotationView"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier) as? MKMarkerAnnotationView
                if annotationView == nil {
                    annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
                } else {
                    annotationView?.annotation = annotation
                }
                annotationView?.glyphTintColor  = UIColor(white: 0.0, alpha: 0.0)
                annotationView?.markerTintColor = UIColor(white: 0.0, alpha: 0.0)
                let image = UIImage(named: "float")
                annotationView?.image = image
                annotationView?.backgroundColor = customAnnotation.color
                annotationView?.layer.cornerRadius = (annotationView?.frame.width)!/2
                annotationView?.canShowCallout = true
                annotationView?.displayPriority = .required
                annotationView?.zPriority = .max
                return annotationView
            }
        }else{
            let reuseIdentifier = "AnnotationView"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            return annotationView
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        view.isSelected = false
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
        self.selectedTown = appDelegate.towns[row]
    }
    @objc func doneButtonTapped(){
        UIView.animate(withDuration: 0.3, animations: {
            self.containerView?.alpha = 0 // アルファ値を0にしてフェードアウトさせる
        }) { (finished) in
            // アニメーションが完了した後の処理
            self.containerView?.removeFromSuperview()
        }
        changeCurrentTown()
    }
    func changeCurrentTown(){
        self.removeMapObj()
        self.currentTown = self.selectedTown
        self.townButton.setTitle(self.currentTown, for: .normal)
        self.getRoute(town: self.currentTown!, day: self.currentDay, period: self.currentPeriod)
    }
    
    func startAnimation() {
        slider.isHidden = false
        animationButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        self.isAnimationRunning = true
        currentCoordinate = polylines[0].points()[0].coordinate
        floatAnnotation?.coordinate = CLLocationCoordinate2D(latitude: currentCoordinate.latitude - mapView.zoomLevel*yOffset, longitude: currentCoordinate.longitude)
        currentIndex = 0
        currentPolylineIndex = 0
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateAnnotationPosition), userInfo: nil, repeats: true)
        
    }
    func stopAnimation() {
        timer?.invalidate()
        timer = nil
        animationDidFinish()
    }
    func animationDidFinish() {
        if let floatLocation = floatLocation{
            floatAnnotation!.coordinate = floatLocation.coordinate
        }
        slider.isHidden = true
        animationButton.setImage(UIImage(systemName: "arrowtriangle.forward"), for: .normal)
        self.isAnimationRunning = false
    }
    
    @objc func updateAnnotationPosition() {
        guard currentPolylineIndex < polylines.count else {
            timer?.invalidate()
            timer = nil
            animationDidFinish()
            return
        }
        
        let currentPolyline = polylines[currentPolylineIndex]
        let points = currentPolyline.points()
        let pointCount = currentPolyline.pointCount
        
        if currentIndex < pointCount - 1 {
            let nextCoordinate = points[currentIndex + 1].coordinate
            let distance = CLLocation(latitude: currentCoordinate.latitude, longitude: currentCoordinate.longitude).distance(from: CLLocation(latitude: nextCoordinate.latitude, longitude: nextCoordinate.longitude))
            
            if distance >= appDelegate.app.getDouble("replayDistance")! {
                let step = appDelegate.app.getDouble("replayDistance")! / distance
                let newLatitude = currentCoordinate.latitude + (nextCoordinate.latitude - currentCoordinate.latitude) * step
                let newLongitude = currentCoordinate.longitude + (nextCoordinate.longitude - currentCoordinate.longitude) * step
                currentCoordinate = CLLocationCoordinate2D(latitude: newLatitude, longitude: newLongitude)
                floatAnnotation!.coordinate = CLLocationCoordinate2D(latitude: newLatitude-mapView.zoomLevel*yOffset, longitude: newLongitude)
            } else {
                currentIndex += 1
                currentCoordinate = nextCoordinate
                floatAnnotation!.coordinate = CLLocationCoordinate2D(latitude: currentCoordinate.latitude-mapView.zoomLevel*yOffset, longitude: currentCoordinate.longitude)
            }
        } else {
            currentPolylineIndex += 1
            currentIndex = 0
            if currentPolylineIndex < polylines.count {
                currentCoordinate  = polylines[currentPolylineIndex].points()[0].coordinate
                floatAnnotation!.coordinate = CLLocationCoordinate2D(latitude: currentCoordinate.latitude-mapView.zoomLevel*yOffset, longitude: currentCoordinate.longitude)
            }
        }
        
        updateSlider()
    }
    
    @IBAction func sliderChanged(_ sender: UISlider) {
        // アニメーションの位置をスライダーに合わせて更新
        let totalPoints = polylines.reduce(0) { $0 + $1.pointCount }
        let targetIndex = Int(sender.value * Float(totalPoints))
        
        var accumulatedPoints = 0
        for (index, polyline) in polylines.enumerated() {
            if targetIndex < accumulatedPoints + polyline.pointCount {
                currentPolylineIndex = index
                currentIndex = targetIndex - accumulatedPoints
                floatAnnotation!.coordinate = polyline.points()[currentIndex].coordinate
                break
            }
            accumulatedPoints += polyline.pointCount
        }
    }
    
    func updateSlider() {
        let totalPoints = polylines.reduce(0) { $0 + $1.pointCount }
        let currentPoints = polylines[0..<currentPolylineIndex].reduce(0) { $0 + $1.pointCount } + currentIndex
        slider.value = Float(currentPoints) / Float(totalPoints)
    }
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        currentButton.setImage(UIImage(systemName: "paperplane"), for: .normal)
    }
}
