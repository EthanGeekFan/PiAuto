//
//  MyMapViewFactory.swift
//  Runner
//
//  Created by Yifan Yang on 2021/2/16.
//

import Flutter
import UIKit
import AMapNaviKit

class MyMapViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return MyMapView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger)
    }
}

class MyMapView: NSObject, FlutterPlatformView, AMapNaviCompositeManagerDelegate {
    private var _view: UIView
    var compositeManager: AMapNaviCompositeManager!
    var viewController: UIViewController

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
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
        
        viewController = MyMapViewController.shared
        _view = UIView.init(frame: viewFrame)
//        viewController = CompositeWithUserConfigViewController()
        viewController.view.frame = viewFrame
        _view.addSubview(viewController.view)
        super.init()
        // iOS views can be created here
    }

    func view() -> UIView {
        return _view
    }

}
