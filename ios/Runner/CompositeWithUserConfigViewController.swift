
//
//  CompositeWithUserConfigViewController.swift
//  officialDemoNavi
//
//  Created by eidan on 2017/7/19.
//  Copyright © 2017年 AutoNavi. All rights reserved.
//

import UIKit
import AMapNaviKit

class CompositeWithUserConfigViewController: UIViewController, AMapNaviCompositeManagerDelegate {

    var compositeManager : AMapNaviCompositeManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.frame = self.view.bounds
        
        self.view.backgroundColor = UIColor.white;
        print(self.view.bounds)
        print(self.view.frame)
        let routeBtn = UIButton.init(type: UIButton.ButtonType.system)
        routeBtn.frame = CGRect.init(x: (self.view.bounds.size.width - 200) / 2.0, y: 100.0, width: 200.0, height: 45.0)
        print(routeBtn.frame)
        routeBtn.setTitle("传入终点", for: UIControl.State.normal)
        routeBtn.setTitleColor(UIColor.init(red: 53/255.0, green: 117/255.0, blue: 255/255.0, alpha: 1), for: UIControl.State.normal)
        routeBtn.layer.cornerRadius = 5
        routeBtn.layer.borderColor = UIColor.init(red: 53/255.0, green: 117/255.0, blue: 255/255.0, alpha: 1).cgColor
        routeBtn.layer.borderWidth = 1
        routeBtn.addTarget(self, action: #selector(self.routePlanWithEndPoint),for: UIControl.Event.touchUpInside)
        self.view.addSubview(routeBtn)
        
        let routeBtn1 = UIButton.init(type: UIButton.ButtonType.system)
        routeBtn1.frame = CGRect.init(x: (self.view.bounds.size.width - 200) / 2.0, y: 200.0, width: 200.0, height: 45.0)
        routeBtn1.setTitle("传入起终点、途径点", for: UIControl.State.normal)
        routeBtn1.setTitleColor(UIColor.init(red: 53/255.0, green: 117/255.0, blue: 255/255.0, alpha: 1), for: UIControl.State.normal)
        routeBtn1.layer.cornerRadius = 5
        routeBtn1.layer.borderColor = UIColor.init(red: 53/255.0, green: 117/255.0, blue: 255/255.0, alpha: 1).cgColor
        routeBtn1.layer.borderWidth = 1
        routeBtn1.addTarget(self, action: #selector(self.routePlanAction),for: UIControl.Event.touchUpInside)
        self.view.addSubview(routeBtn1)
        
        let routeBtn2 = UIButton.init(type: UIButton.ButtonType.system)
        routeBtn2.frame = CGRect.init(x: (self.view.bounds.size.width - 200) / 2.0, y: 300.0, width: 200.0, height: 45.0)
        routeBtn2.setTitle("直接进入导航界面", for: UIControl.State.normal)
        routeBtn2.setTitleColor(UIColor.init(red: 53/255.0, green: 117/255.0, blue: 255/255.0, alpha: 1), for: UIControl.State.normal)
        routeBtn2.layer.cornerRadius = 5
        routeBtn2.layer.borderColor = UIColor.init(red: 53/255.0, green: 117/255.0, blue: 255/255.0, alpha: 1).cgColor
        routeBtn2.layer.borderWidth = 1
        routeBtn2.addTarget(self, action: #selector(self.startNaviDirectly),for: UIControl.Event.touchUpInside)
        self.view.addSubview(routeBtn2)
        
        // init
        self.compositeManager = AMapNaviCompositeManager.init()
        self.compositeManager.delegate = self
        
        
        // Do any additional setup after loading the view.
    }
    
    // 传入终点
    @objc func routePlanWithEndPoint() {
        let config = AMapNaviCompositeUserConfig.init()
        config.setRoutePlanPOIType(AMapNaviRoutePlanPOIType.end, location: AMapNaviPoint.location(withLatitude: 39.918058, longitude: 116.397026), name: "故宫", poiId: nil)  //传入终点
        self.compositeManager.presentRoutePlanViewController(withOptions: config)
    }
    
    // 传入起终点、途径点
    @objc func routePlanAction() {
        let config = AMapNaviCompositeUserConfig.init()
        config.setRoutePlanPOIType(AMapNaviRoutePlanPOIType.start, location: AMapNaviPoint.location(withLatitude: 40.080525, longitude: 116.603039), name: "北京首都机场", poiId: "B000A28DAE") //传入起点，并且带高德POIId
        config.setRoutePlanPOIType(AMapNaviRoutePlanPOIType.way, location: AMapNaviPoint.location(withLatitude: 39.941823, longitude: 116.426319), name: "北京大学", poiId: "B000A816R6")      //传入途径点，并且带高德POIId
        config.setRoutePlanPOIType(AMapNaviRoutePlanPOIType.end, location: AMapNaviPoint.location(withLatitude: 39.918058, longitude: 116.397026), name: "故宫", poiId: "B000A8UIN8")         //传入终点，并且带高德POIId
        self.compositeManager.presentRoutePlanViewController(withOptions: config)
    }
    
    // 直接进入导航界面
    @objc func startNaviDirectly() {
        let config = AMapNaviCompositeUserConfig.init()
        config.setRoutePlanPOIType(AMapNaviRoutePlanPOIType.end, location: AMapNaviPoint.location(withLatitude: 39.918058, longitude: 116.397026), name: "故宫", poiId: nil)  //传入终点
        config.setStartNaviDirectly(true) //直接进入导航界面
        self.compositeManager.presentRoutePlanViewController(withOptions: config)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - AMapNaviCompositeManagerDelegate
    
    func compositeManager(_ compositeManager: AMapNaviCompositeManager, error: Error) {
        let error = error as NSError
        NSLog("error:{%d - %@}", error.code, error.localizedDescription)
    }
    
    func compositeManager(onCalculateRouteSuccess compositeManager: AMapNaviCompositeManager) {
        NSLog("onCalculateRouteSuccess,%ld", compositeManager.naviRouteID)
    }
    
    func compositeManager(_ compositeManager: AMapNaviCompositeManager, onCalculateRouteFailure error: Error) {
        let error = error as NSError
        NSLog("onCalculateRouteFailure error:{%d - %@}", error.code, error.localizedDescription)
    }
    
    func compositeManager(_ compositeManager: AMapNaviCompositeManager, didStartNavi naviMode: AMapNaviMode) {
        NSLog("didStartNavi")
    }
    
    func compositeManager(_ compositeManager: AMapNaviCompositeManager, didArrivedDestination naviMode: AMapNaviMode) {
        NSLog("didArrivedDestination")
    }
    
    func compositeManager(_ compositeManager: AMapNaviCompositeManager, update naviLocation: AMapNaviLocation?) {
//        NSLog("updateNaviLocation,%@",naviLocation)
    }
    
//    //以下注释掉的3个回调方法，如果需要自定义语音，可开启
//    func compositeManagerIsNaviSoundPlaying(_ compositeManager: AMapNaviCompositeManager) -> Bool {
//        return SpeechSynthesizer.Shared.isSpeaking()
//    }
//
//    func compositeManager(_ compositeManager: AMapNaviCompositeManager, playNaviSound soundString: String?, soundStringType: AMapNaviSoundType) {
//        if (soundString != nil) {
//            SpeechSynthesizer.Shared.speak(soundString!)
//        }
//    }
//
//    func compositeManagerStopPlayNaviSound(_ compositeManager: AMapNaviCompositeManager) {
//        SpeechSynthesizer.Shared.stopSpeak()
//    }

}
