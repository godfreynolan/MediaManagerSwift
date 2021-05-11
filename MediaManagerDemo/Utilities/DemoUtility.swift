//
//  DemoUtility.swift
//  PlaybackDemo
//
//  Created by Samuel Scherer on 4/13/21.
//  Copyright © 2021 DJI. All rights reserved.
//
import Foundation
import DJIUXSDK
import DJISDK

class DemoUtility: NSObject {
    public class func show(result:String) {//TODO: Should I make this a global function like the objc original?
        DispatchQueue.main.async {
            let alertViewController = UIAlertController(title: nil, message: result, preferredStyle: UIAlertController.Style.alert)
            let okAction = UIAlertAction.init(title: "OK", style: UIAlertAction.Style.default, handler: nil)
            alertViewController.addAction(okAction)
            let navController = UIApplication.shared.keyWindow?.rootViewController as! UINavigationController
            navController.present(alertViewController, animated: true, completion: nil)
        }
    }
    
    public class func fetchProduct () -> DJIBaseProduct? {
        return DJISDKManager.product()
    }
    
    public class func fetchAircraft () -> DJIAircraft? {
        return DJISDKManager.product() as? DJIAircraft
    }
    
    public class func fetchCamera () -> DJICamera? {
        let aircraft = DJISDKManager.product() as? DJIAircraft
        return aircraft?.camera
    }
    
    public class func fetchFlightController() -> DJIFlightController? {
        let aircraft = DJISDKManager.product() as? DJIAircraft
        return aircraft?.flightController
    }
}
