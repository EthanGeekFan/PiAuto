import UIKit
import Flutter
import AMapNaviKit
import AMapSearchKit

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, AMapSearchDelegate {
    
    var search: AMapSearchAPI = AMapSearchAPI()
    var currentPOISearchCallback: FlutterResult!
    var currentTipSearchCallback: FlutterResult!
    var poiSearchRequest: AMapPOIKeywordsSearchRequest!
    var tipSearchRequest: AMapInputTipsSearchRequest!
    var annos: Array<MAPointAnnotation>!
    
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Configure your API Key here
    AMapServices.shared()?.apiKey = "f3ea289093262c9d627e2c1d37225fb1"
    
    AMapServices.shared()?.enableHTTPS = true
    
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let searchChannel = FlutterMethodChannel(name: "com.ethan.PiAuto", binaryMessenger: controller.binaryMessenger)
    searchChannel.setMethodCallHandler({
        (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        if call.method == "searchPOI" {
            self.currentPOISearchCallback = result
            
            print(call.arguments!)
            
            self.search.delegate = self
            self.poiSearchRequest = AMapPOIKeywordsSearchRequest()
            self.poiSearchRequest.keywords = "\(call.arguments!)"
            self.poiSearchRequest.requireExtension = true
//            request.city =

            self.poiSearchRequest.cityLimit = true
            self.poiSearchRequest.requireSubPOIs = false
            
            self.search.aMapPOIKeywordsSearch(self.poiSearchRequest)
            
        } else if call.method == "inputTips" {
            self.currentTipSearchCallback = result
            // search for suggestions
            self.search.delegate = self
            self.tipSearchRequest = AMapInputTipsSearchRequest()
            self.tipSearchRequest.keywords = "\(call.arguments!)"
//            suggestionRequest.city = "北京"
            print("Searching tips...")
            self.search.aMapInputTipsSearch(self.tipSearchRequest)
        } else if call.method == "selectPOI" {
            MyMapViewController.shared.mapView.selectAnnotation(self.annos[call.arguments! as! Int], animated: true)
            result("ok")
        } else if call.method == "clearAnnos" {
            MyMapViewController.shared.mapView.removeAnnotations(self.annos)
            result("ok")
        } else if call.method == "gotoPOI" {
            let latitude: Double = (call.arguments! as! Array<Any>)[0] as! Double
            let longitude: Double = (call.arguments! as! Array<Any>)[1] as! Double
            MyNavigationViewController.shared.gotoPOI(latitude: latitude, longitude: longitude)
        }
    })
    
    weak var registrar = self.registrar(forPlugin: "MyMapView")
    let mapViewFactory = MyMapViewFactory(messenger: registrar!.messenger())
    self.registrar(forPlugin: "<MyMapView>")!.register(
        mapViewFactory,
        withId: "com.ethan.PiAuto/views/mapview")
    
    let myNavigationViewFactory = MyNavigationViewFactory(messenger: registrar!.messenger())
    self.registrar(forPlugin: "<MyNavigationView>")!.register(
        myNavigationViewFactory,
        withId: "com.ethan.PiAuto/views/navigationview")
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
    func onPOISearchDone(_ request: AMapPOISearchBaseRequest!, response: AMapPOISearchResponse!) {
        
        if poiSearchRequest == nil || poiSearchRequest! != request {
            currentPOISearchCallback(nil)
            return
        }

        if response.count == 0 {
            currentPOISearchCallback(nil)
            return
        }

        //解析response获取POI信息，具体解析见 Demo
        self.annos = Array<MAPointAnnotation>()
        var result: Array<Dictionary<String, Any>> = []

        for aPOI in response.pois {
            let dict: Dictionary<String, Any> = ["name": aPOI.name!, "address": aPOI.address!, "latitude": aPOI.location.latitude, "longitude": aPOI.location.longitude]
            result.append(dict)
            
            let coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(aPOI.location.latitude), longitude: CLLocationDegrees(aPOI.location.longitude))
            let anno = MAPointAnnotation()
            anno.coordinate = coordinate
            anno.title = aPOI.name
            anno.subtitle = aPOI.address
            annos.append(anno)
        }
        MyMapViewController.shared.mapView.addAnnotations(annos)
        MyMapViewController.shared.mapView.showAnnotations(annos, animated: false)
        MyMapViewController.shared.mapView.selectAnnotation(annos.first, animated: true)
        currentPOISearchCallback(result)
    }
    
    func onInputTipsSearchDone(_ request: AMapInputTipsSearchRequest!, response: AMapInputTipsSearchResponse!) {
        
        if tipSearchRequest == nil || tipSearchRequest! != request {
            currentTipSearchCallback(nil)
            return
        }
        
        if response.count == 0 {
            currentTipSearchCallback(nil)
            return
        }
        
       //解析response获取提示词，具体解析见 Demo
        var result: Array<Dictionary<String, Any>> = []
        for aTip in response.tips {
            // tip types:
            // 0: Brand
            // 1: Busline
            // 2: POI
            var type: Int = 0
            if aTip.location == nil && aTip.uid == nil {
                type = 0
            } else if aTip.uid != nil && aTip.location == nil {
                type = 1
            } else if aTip.uid != nil && aTip.location != nil {
                type = 2
            }
            let dict: Dictionary<String, Any> = ["name": aTip.name!, "address": aTip.address!, "type": type]
            result.append(dict)
        }
        print(result)
        currentTipSearchCallback(result)
    }
}
