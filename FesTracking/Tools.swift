//
//  Tools.swift
//  FesManaging
//
//  Created by 松下和也 on 2024/02/13.
//

import Foundation
import CoreLocation
import UIKit
import MapKit

enum Day: Int, CaseIterable{
    case Friday = 0
    case Saturday
    case Sunday
    case Monday
    var text : String{
        switch self {
        case .Friday:
            return "金曜日"
        case .Saturday:
            return "土曜日"
        case .Sunday:
            return "日曜日"
        case .Monday:
            return "月曜日"
        }
    }
    static func getCurrentDay() -> Day {
        let currentDate = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: currentDate)
        
        switch weekday {
        case 6: // 金曜日
            return .Friday
        case 7: // 土曜日
            return.Saturday
        case 1: // 日曜日
            return .Sunday
        case 2: // 月曜日
            return .Monday
        default:
            return .Friday // 金曜から月曜以外の曜日の場合はnilを返す
        }
    }
    
}

enum Period :Int, CaseIterable{
    case Morning = 0
    case Afternoon
    case Night
    var text : String{
        switch self {
        case .Morning:
            return "午前"
        case .Afternoon:
            return "午後"
        case .Night:
            return "夜"
        }
    }
    static func getCurrentPeriod() -> Period {
        let currentDate = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentDate)
        if hour >= 6 && hour < 12 {
            return .Morning
        } else if hour >= 12 && hour < 17 {
            return .Afternoon
        } else {
            return .Night
        }
    }
}

class CustomLocation{
    var coordinate:CLLocationCoordinate2D
    var event :String
    var curveIncluded:Bool
    var polyline: MKPolyline?
    var annotation:MKAnnotation?
    init(latitude:Double,longitude:Double , event:String="なし", curveIncluded: Bool=false) {
        self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.event = event
        self.curveIncluded = curveIncluded
    }
    init(clLocation:CLLocationCoordinate2D, event:String="なし", curveIncluded: Bool=false){
        self.coordinate = clLocation
        self.event = event
        self.curveIncluded = curveIncluded
    }
    
    func decode()->[String:Any]{
        return [
            "coordinate":[coordinate.latitude,coordinate.longitude],
            "event":event,
            "curveIncluded":curveIncluded
        ]
    }
}

class CustomAnnotation: MKPointAnnotation{
    enum AnnotationType{
        case Float
        case Point
    }
    let type: AnnotationType
    let color: UIColor // ピンの色を保持するプロパティ
    var glyphText:String?
    
    var image: UIImage?{
        if let title = self.title{
            if  title.contains("休憩"){
                let components = title.components(separatedBy: CharacterSet.decimalDigits.inverted)
                let integers = components.compactMap { Int($0) }
                if integers.isEmpty{
                    return UIImage(systemName: "timer")
                }else{
                    if let image = UIImage(systemName: "goforward.\(integers[0])"){
                        return image
                    }else{
                        return UIImage(systemName: "timer")
                    }
                    
                }
            }else if title.contains("スタート"){
                return UIImage(systemName: "s.circle")
            }
            else if title.contains("ゴール"){
                return UIImage(systemName: "g.circle")
            }
        }
        return nil
    }
    
    
    init(coordinate: CLLocationCoordinate2D, title: String?, subtitle: String?, color: UIColor,type: CustomAnnotation.AnnotationType,glyphText:String?=nil) {
        self.color = color
        self.type = type
        self.glyphText = glyphText
        super.init()
        self.coordinate = coordinate
        self.title = title
       
    }
}

class Route{
    var locations:[CustomLocation]
    var stack:[CustomLocation]
    
    init() {
        locations = [CustomLocation]()
        stack = [CustomLocation]()
    }
    
    var count : Int{
        return locations.count
    }
    
    func append(location:CustomLocation){
        locations.append(location)
        stack = [CustomLocation]()
    }
    func getLocation(index:Int)->CustomLocation?{
        if index >= 0 && index < locations.count{
            return locations[index]
        }else{
            return nil
        }
    }
    func getCurve(index:Int)->Bool{
        return locations[index].curveIncluded
    }
    func getEvent(index:Int)->String{
        return locations[index].event
    }
    func setLocations(locations:[CustomLocation]){
        self.locations = locations
    }
    func setCurve(index:Int, curveIncluded:Bool)->MKPolyline?{
        locations[index].curveIncluded = curveIncluded
        return locations[index].polyline
    }
    func setEvent(index:Int,event:String)->MKAnnotation?{
        locations[index].event = event
        return locations[index].annotation
    }
    func setPolyline(index:Int,polyline:MKPolyline){
        locations[index].polyline = polyline
    }
    func setAnnotation(index:Int,annotation:MKAnnotation){
        locations[index].annotation = annotation
    }
    func undo()->(MKPolyline?,MKAnnotation?){
        stack.append(locations.popLast()!)
        let tpl =  (stack.last?.polyline,stack.last?.annotation)
        return tpl
    }
    func redo()->(MKPolyline?,MKAnnotation?){
        locations.append(stack.popLast()!)
        let tpl =  (locations.last?.polyline,locations.last?.annotation)
        return tpl
    }
    func findFromCoordinate(clLocation:CLLocationCoordinate2D)->Int?{
        for i in 0..<self.count{
            if clLocation.latitude ==  locations[i].coordinate.latitude &&
                clLocation.longitude ==  locations[i].coordinate.longitude{
                return i
            }
        }
        return nil
    }
    func decode()->[Any]{
        var routeObj = [Any]()
        for location in locations{
            routeObj.append(location.decode())
        }
        return routeObj
    }
}
extension UINavigationItem {
 
    func setTitleView(withTitle title: String, subTitile: String) {
 
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .boldSystemFont(ofSize: 17)
        titleLabel.textColor = .white
 
        let stackView = UIStackView(arrangedSubviews: [titleLabel])
        stackView.distribution = .equalCentering
        stackView.alignment = .center
        stackView.axis = .vertical
 
        self.titleView = stackView
    }
}

class ServerRequest{
    enum Error {
        case DataTask
        case InvaliedResponce
        case InvaliedStatusCode
        case NoData
    }
    static func post(url:String,endpoint:String="",jsonData:Data,callbackFunc:((Data)->Void)?,errorCallBackFunc:((Error)->Void)?=nil){
        let urlComponents = URLComponents(string: "\(url)/\(endpoint)")
        if let url = urlComponents?.url {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            // URLSessionを使用してリクエストを送信
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    //print("データタスクでエラーが発生しました: \(error)")
                    if let errorFunc = errorCallBackFunc{
                        DispatchQueue.main.sync {
                            errorFunc(Error.DataTask)
                        }
                    }
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse else {
                    //print("無効なHTTPレスポンス")
                    if let errorFunc = errorCallBackFunc{
                        DispatchQueue.main.sync {
                            errorFunc(Error.InvaliedResponce)
                        }
                    }
                    return
                }
                guard (200...299).contains(httpResponse.statusCode) else {
                    //print("無効なステータスコード: \(httpResponse.statusCode)")
                    if let errorFunc = errorCallBackFunc{
                        DispatchQueue.main.sync {
                            errorFunc(Error.InvaliedStatusCode)
                        }
                    }
                    return
                }
                guard let responseData = data else {
                    //print("データが見つかりません")
                    if let errorFunc = errorCallBackFunc{
                        DispatchQueue.main.sync {
                            errorFunc(Error.NoData)
                        }
                    }
                    return
                }
                //print("受信成功")
                if let function = callbackFunc{
                    DispatchQueue.main.sync {
                        function(responseData)
                            
                    }
                }
            }
            task.resume()
        }
    }
    static func post(url:String,endpoint:String="", jsonData:Data,callbackFunc:((Data,[String:Any])->Void)?,args:[String:Any],errorCallBackFunc:((Error)->Void)?=nil){
        let urlComponents = URLComponents(string: "\(url)/\(endpoint)")
        
        if let url = urlComponents?.url {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            // URLSessionを使用してリクエストを送信
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    //print("データタスクでエラーが発生しました: \(error)")
                    if let errorFunc = errorCallBackFunc{
                        DispatchQueue.main.sync {
                            errorFunc(Error.DataTask)
                        }
                    }
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse else {
                    //print("無効なHTTPレスポンス")
                    if let errorFunc = errorCallBackFunc{
                        DispatchQueue.main.sync {
                            errorFunc(Error.InvaliedResponce)
                        }
                    }
                    return
                }
                guard (200...299).contains(httpResponse.statusCode) else {
                    //print("無効なステータスコード: \(httpResponse.statusCode)")
                    if let errorFunc = errorCallBackFunc{
                        DispatchQueue.main.sync {
                            errorFunc(Error.InvaliedStatusCode)
                        }
                    }
                    return
                }
                guard let responseData = data else {
                    //print("データが見つかりません")
                    
                    if let errorFunc = errorCallBackFunc{
                        DispatchQueue.main.sync {
                            errorFunc(Error.NoData)
                        }
                    }
                    return
                }
                //print("受信成功")
                if let function = callbackFunc{
                    DispatchQueue.main.sync {
                        function(responseData,args)
                    }
                }
            }
            task.resume()
        }
    }
    static func get(url:String,endpoint:String="",params:[String:String],callbackFunc:@escaping(Data)->Void,errorCallBackFunc:((Error)->Void)?=nil){
        var urlComponents = URLComponents(string: "\(url)/\(endpoint)")
        var queryItems:[URLQueryItem] = []
        for (key,value) in params{
            queryItems.append(URLQueryItem(name: key, value: value))
        }
        urlComponents?.queryItems = queryItems
        print(urlComponents?.url!.absoluteString)
        if let url = urlComponents?.url {
            let session = URLSession.shared
            let request = URLRequest(url: url)
            let task = session.dataTask(with: request) { data, response, error in
                if let error = error {
                    //print("データタスクでエラーが発生しました: \(error)")
                    if let errorFunc = errorCallBackFunc{
                        DispatchQueue.main.sync {
                            errorFunc(Error.DataTask)
                        }
                    }
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse else {
                    //print("無効なHTTPレスポンス")
                    if let errorFunc = errorCallBackFunc{
                        DispatchQueue.main.sync {
                            errorFunc(Error.InvaliedResponce)
                        }
                    }
                    return
                }
                guard (200...299).contains(httpResponse.statusCode) else {
                    //print("無効なステータスコード: \(httpResponse.statusCode)")
                    if let errorFunc = errorCallBackFunc{
                        DispatchQueue.main.sync {
                            errorFunc(Error.InvaliedStatusCode)
                        }
                    }
                    return
                }
                guard let responseData = data else {
                    //print("データが見つかりません")
                    if let errorFunc = errorCallBackFunc{
                        DispatchQueue.main.sync {
                            errorFunc(Error.NoData)
                        }
                    }
                    return
                }
                // JSONデータをデコード
                //print("受信成功")
                DispatchQueue.main.sync {
                    callbackFunc(responseData)
                }
            }
            // データタスクを開始
            task.resume()
        }
    }
}

class App {
    var property: Dictionary<String, Any> = [:]
    
    init() {
        // App.plistのパス取得
        let path = Bundle.main.path(forResource: "App", ofType: "plist")
        // App.plistをDictionary形式で読み込み
        let configurations = NSDictionary(contentsOfFile: path!)
        if let datasourceDictionary: [String : Any]  = configurations as? [String : Any] {
            property = datasourceDictionary
        }
    }

    /// 指定されたキーの値を取得する
    /// - Parameter key: plistのキー
    func getString(_ key: String) -> String? {
        guard let value: String = property[key] as? String else {
            return nil
        }
        return value
    }
    func getDouble(_ key: String) -> Double? {
        guard let value: Double = property[key] as? Double else {
            return nil
        }
        return value
    }
    func getStringArray(_ key: String) -> [String]? {
        guard let array: [String] = property[key] as? [String] else {
            return nil
        }
        return array
    }
    func getCoordinate(_ key: String) -> CLLocationCoordinate2D? {
        guard let array: [Double] = property[key] as? [Double] else {
            return nil
        }
        let coor = CLLocationCoordinate2D(latitude: array[0], longitude: array[1])
        return coor
    }
    
}

extension UIImage {
   static func loadImageFromURL(urlStr: String,view:UIView ,completion: @escaping (UIImage?) -> Void) {
        let loadingAlert = LoadingAlert()
        
        func urlEncode(string: String) -> String? {
            return string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        }
        func showLoadingAlert() {
            // ビューにアラートを追加してアニメーションを開始する
            loadingAlert.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(loadingAlert)
            
            NSLayoutConstraint.activate([
                loadingAlert.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                loadingAlert.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                loadingAlert.widthAnchor.constraint(equalToConstant: 150),
                loadingAlert.heightAnchor.constraint(equalToConstant: 100)
            ])
            
            loadingAlert.startAnimating()
        }
        
        func hideLoadingAlert() {
            // アラートを非表示にしてビューから削除する
            loadingAlert.stopAnimating()
            loadingAlert.removeFromSuperview()
        }
       showLoadingAlert()
        if let encodedURL = urlEncode(string: urlStr) {
            if let url = URL(string: encodedURL) {
                URLSession.shared.dataTask(with: url) { data, response, error in
                    if let error = error {
                        //print("Error: \(error.localizedDescription)")
                        DispatchQueue.main.async {
                            hideLoadingAlert()
                            completion(nil)
                        }
                        return
                    }
                    
                    if let data = data {
                        if let image = UIImage(data: data) {
                            DispatchQueue.main.async {
                                hideLoadingAlert()
                                completion(image)
                            }
                            
                        } else {
                            //print("Error: Invalid image data")
                            DispatchQueue.main.async {
                                hideLoadingAlert()
                                completion(nil)
                            }
                        }
                    } else {
                        //print("Error: No data received")
                        DispatchQueue.main.async {
                            hideLoadingAlert()
                            completion(nil)
                        }
                    }
                }.resume()
            } else {
                //print("Error: Invalid URL")
                DispatchQueue.main.async {
                    hideLoadingAlert()
                    completion(nil)
                }
            }
        } else {
            //print("Error: URL encoding failed")
            DispatchQueue.main.async {
                hideLoadingAlert()
                completion(nil)
            }
        }
    }
}

class CustomPolyline: MKOverlay{
    
    
    var coordinate: CLLocationCoordinate2D
    var boundingMapRect: MKMapRect
    var hash: Int
    var superclass: AnyClass?
    var description: String
    
    let polyline: MKPolyline
    let color: UIColor
    
    init(polyline:MKPolyline,color: UIColor) {
        self.color = color
        self.polyline = polyline
        self.coordinate = polyline.coordinate
        self.boundingMapRect = polyline.boundingMapRect
        self.hash = polyline.hash
        self.superclass = polyline.superclass
        self.description = polyline.description
    }
    
    func `self`() -> Self {
        return self
    }
    // performメソッド
    func perform(_ aSelector: Selector!) -> Unmanaged<AnyObject>! {
        return nil
    }
    
    // performメソッド（オブジェクトを受け取る）
    func perform(_ aSelector: Selector!, with object: Any!) -> Unmanaged<AnyObject>! {
        return nil
    }
    
    // performメソッド（オブジェクト2つを受け取る）
    func perform(_ aSelector: Selector!, with object1: Any!, with object2: Any!) -> Unmanaged<AnyObject>! {
        return nil
    }
    
    // isProxyメソッド
    func isProxy() -> Bool {
        return false
    }
    
    // isKind(of:)メソッド
    func isKind(of aClass: AnyClass) -> Bool {
        return aClass == CustomPolyline.self
    }
    
    // isMember(of:)メソッド
    func isMember(of aClass: AnyClass) -> Bool {
        return aClass == CustomPolyline.self
    }
    
    // conforms(to:)メソッド
    func conforms(to aProtocol: Protocol) -> Bool {
        return false
    }
    
    // responds(to:)メソッド
    func responds(to aSelector: Selector!) -> Bool {
        return false
    }
    
    // isEqualメソッド
    func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? CustomPolyline else {
            return false
        }
        return self.polyline.isEqual(other.polyline) && self.color == other.color
    }
}

extension MKAnnotationView{
    func setSize(size:Int){
        let frame = CGRect(x: 0, y: 0, width: size, height: size)
        self.frame = frame
    }
}


extension MKMapView {
    var zoomLevel: Double {
        let MERCATOR_OFFSET: Double = 268435456.0
        let MERCATOR_RADIUS: Double = 85445659.44705395
        
        let region = self.region
        let centerPixelX = MERCATOR_OFFSET + MERCATOR_RADIUS * region.center.longitude * .pi / 180.0
        let centerPixelY = MERCATOR_OFFSET - MERCATOR_RADIUS * log((1 + sin(region.center.latitude * .pi / 180.0)) / (1 - sin(region.center.latitude * .pi / 180.0))) / 2.0
        let zoomScale = Double(self.bounds.size.width) / region.span.longitudeDelta * 360.0 / .pi
        let zoomLevel = log2(zoomScale)
        
        return sqrt(sqrt(zoomLevel))
    }
}
