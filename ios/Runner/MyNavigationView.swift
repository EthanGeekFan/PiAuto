//
//  NavigationWidgetController.swift
//  Runner
//
//  Created by Yifan Yang on 2021/2/19.
//

import UIKit
import AMapNaviKit

class MyNavigationViewController: UIViewController, AMapNaviDriveViewDelegate, AMapNaviDriveManagerDelegate {
    
    var driveView: AMapNaviDriveView!
    var viewFrame: CGRect!
    
    static var shared = MyNavigationViewController()
    
    override func loadView() {
        let screenSize = UIScreen.main.bounds
        let safeAreaInsets = UIApplication.shared.windows.first?.safeAreaInsets
        let leftInset = safeAreaInsets?.left ?? 0
        let rightInset = safeAreaInsets?.right ?? 0
        let topInset = safeAreaInsets?.top ?? 0
        let bottomInsets = safeAreaInsets?.bottom ?? 0
        let horizontalInset = leftInset + rightInset
        let verticalInset = topInset + bottomInsets
        let width = screenSize.width - horizontalInset
        let height = screenSize.height - verticalInset
        let viewWidth = width / 2 - 20
        let viewHeight = height - 20
        viewFrame = CGRect.init(x: 0, y: 0, width: viewWidth, height: viewHeight)
        
        self.view = UIView.init(frame: viewFrame)
        initDriveView()
        initDriveManager()
    }
    
    func initDriveView() {
        driveView = AMapNaviDriveView(frame: viewFrame)
        driveView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        driveView.delegate = self
        driveView.trackingMode = AMapNaviViewTrackingMode.carNorth
        driveView.showBackupRoute = true
        driveView.autoZoomMapLevel = true
        driveView.showMoreButton = false
        driveView.mapViewModeType = .dayNightAuto
        AMapNaviDriveManager.sharedInstance()
        
        self.view.addSubview(driveView)
    }
    
    func initDriveManager() {
       AMapNaviDriveManager.sharedInstance().delegate = self
       AMapNaviDriveManager.sharedInstance().allowsBackgroundLocationUpdates = true
       AMapNaviDriveManager.sharedInstance().pausesLocationUpdatesAutomatically = false
       
       //将driveView添加为导航数据的Representative，使其可以接收到导航诱导数据
       AMapNaviDriveManager.sharedInstance().addDataRepresentative(driveView)
    }
    
    func gotoPOI(latitude: Double, longitude: Double) {
        AMapNaviDriveManager.sharedInstance().calculateDriveRoute(withEnd: [AMapNaviPoint.location(withLatitude: CGFloat(latitude), longitude: CGFloat(longitude))], wayPoints: [], drivingStrategy: AMapNaviDrivingStrategy.multipleDefault)
    }
    
    func driveManager(_ driveManager: AMapNaviDriveManager, onCalculateRouteSuccessWith type: AMapNaviRoutePlanType) {
       NSLog(">>>>>>> onCalculateRouteSuccess");
        
        //算路成功后开始GPS导航
       AMapNaviDriveManager.sharedInstance().startGPSNavi()
    }
    
    func driveViewCloseButtonClicked(_ driveView: AMapNaviDriveView) {
        
        //停止导航
        AMapNaviDriveManager.sharedInstance().stopNavi()
        print("stopped Navi")
        AMapNaviDriveManager.sharedInstance().removeDataRepresentative(driveView)
        
        // FLutter pop
        let controller : FlutterViewController = self.view.window?.rootViewController as! FlutterViewController
        let searchChannel = FlutterMethodChannel(name: "com.ethan.PiAuto", binaryMessenger: controller.binaryMessenger)
        searchChannel.invokeMethod("stopNavigation", arguments: nil)
        print("Method Invoked")
        AMapNaviDriveManager.sharedInstance().delegate = nil
        let success = AMapNaviDriveManager.destroyInstance()
        NSLog("单例是否销毁成功 in  : \(success)")
        loadView()
    }
    
    deinit {
        AMapNaviDriveManager.sharedInstance().stopNavi()
        AMapNaviDriveManager.sharedInstance().removeDataRepresentative(driveView)
        AMapNaviDriveManager.sharedInstance().delegate = nil
            
        let success = AMapNaviDriveManager.destroyInstance()
        NSLog("单例是否销毁成功 : \(success)")
    }
}
