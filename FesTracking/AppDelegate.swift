//
//  AppDelegate.swift
//  FesTracking
//
//  Created by 松下和也 on 2024/02/07.
//

import UIKit
import CoreLocation

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var app = App()
    var towns:[String] = ["全て"]

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        if let town = UserDefaults.standard.string(forKey: "town"){
            print(town)
        }else{
            if let town = app.getString("defaultTown"){
                UserDefaults.standard.set(town, forKey: "town")
                
            }else{
                UserDefaults.standard.set("全て", forKey: "town")
            }
            UserDefaults.standard.synchronize()
        }
        self.getAllInfo()
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    func getAllInfo(){
        if let url = app.getString("infoURL"){
            var queryItems:[String:String] = [
                "id":"全て"
            ]
            ServerRequest.get(url: url, params: queryItems, callbackFunc: self.callbackGetAllInfo)
        }
    }
    func callbackGetAllInfo(responseData:Data){
        do{
            let json = try JSONSerialization.jsonObject(with: responseData, options: [])as![[String:Any]]
            for jsonInfo in json{
                if let town = jsonInfo["id"] as? String{
                    towns.append(town)
                }
            }
            //print("受信したJSONデータ: \(json)")
        } catch {
            //print("JSONパースエラー: \(error)")
        }

    }
}

