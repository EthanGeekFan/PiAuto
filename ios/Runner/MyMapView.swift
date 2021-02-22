//
//  MyMapView.swift
//  Runner
//
//  Created by Yifan Yang on 2021/2/18.
//

import UIKit
import AMapNaviKit
import AMapSearchKit

class MyMapViewController: UIViewController, MAMapViewDelegate, AMapNaviDriveViewDelegate {
    
    var search: AMapSearchAPI!
    var mapView: MAMapView!
    
    static var shared: MyMapViewController = MyMapViewController()
    
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
        let viewFrame = CGRect.init(x: 0, y: 0, width: viewWidth, height: viewHeight)
        
        self.view = UIView.init(frame: viewFrame)
        mapView = MAMapView(frame: viewFrame)
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.userTrackingMode = MAUserTrackingMode.followWithHeading
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.zoomLevel = 18
        mapView.showsCompass = false
        print("View did load")
//        print(mapView.frame)
//        self.view = mapView
//        print(UIScreen.main.bounds)
        print(viewFrame)
//        mapView.frame = viewFrame
        self.view.addSubview(mapView)
    }

    
    func mapView(_ mapView: MAMapView!, annotationView view: MAAnnotationView!, calloutAccessoryControlTapped control: UIControl!) {
        print("name: \(String(describing: view.annotation.title))")
    }
    
    func mapView(_ mapView: MAMapView!, viewFor annotation: MAAnnotation!) -> MAAnnotationView! {

        if annotation.isKind(of: MAUserLocation.self) {
            return nil
        } else if annotation.isKind(of: MAPointAnnotation.self) {
            let pointReuseIndetifier = "pointReuseIndetifier"
            var annotationView: MAPinAnnotationView? = mapView.dequeueReusableAnnotationView(withIdentifier: pointReuseIndetifier) as! MAPinAnnotationView?

            if annotationView == nil {
                annotationView = MAPinAnnotationView(annotation: annotation, reuseIdentifier: pointReuseIndetifier)
            }

            annotationView!.canShowCallout = true
            annotationView!.isDraggable = false
            annotationView!.rightCalloutAccessoryView = UIButton(type: UIButton.ButtonType.detailDisclosure)

            return annotationView!
        }
        return nil
    }
}
