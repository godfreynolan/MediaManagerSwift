//
//  DemoComponentHelper.swift
//  MediaManagerDemo
//
//  Created by Samuel Scherer on 4/14/21.
//  Copyright © 2021 DJI. All rights reserved.
//

/**
 *  It is recommended that user should not cache any instances of DJIBaseProduct (including DJIAircraft and DJIHandheld) and any instances
 *  of DJIBaseComponent (e.g. DJICamera). Therefore, a set of helper methods is provided to access the product and components.
 */

import Foundation
import DJISDK

class DemoComponentHelper: DemoUtility {
    
    //Product, Aircraft, Camera and Flight Controllers can be fetched from Base Class DemoUtility
    
    public class func fetchHandheld() -> DJIHandheld? {
        return DJISDKManager.product() as? DJIHandheld
    }
    
    //TODO: test this to see if you need to unwrap to DJIAircraft or DJIHandheld before getting the gimbal object
    public class func fetchGimbal() -> DJIGimbal? {
        return DJISDKManager.product()?.gimbal
    }
    
    public class func fetchRemoteController() -> DJIRemoteController? {
        if let aircraft = DJISDKManager.product() as? DJIAircraft {
            return aircraft.remoteController
        }
        return nil
    }
    
    //TODO: test this to see if you need to unwrap to DJIAircraft or DJIHandheld before getting the gimbal object
    public class func fetchBattery() -> DJIBattery? {
        return DJISDKManager.product()?.battery
    }
    
    //TODO: test this to see if you need to unwrap to DJIAircraft or DJIHandheld before getting the gimbal object
    public class func fetchAirlink() -> DJIAirLink? {
        return DJISDKManager.product()?.airLink
    }
    
    public class func fetchPayload() -> DJIPayload? {
        if let aircraft = DJISDKManager.product() as? DJIAircraft {
            return aircraft.payload
        }
        return nil
    }
    
    public class func fetchHandheldController() -> DJIHandheldController? {
        if let handheld = DJISDKManager.product() as? DJIHandheld {
            return handheld.handheldController
        }
        return nil
    }
    
    public class func fetchMobileRemoteController() -> DJIMobileRemoteController? {
        if let aircraft = DJISDKManager.product() as? DJIAircraft {
            return aircraft.mobileRemoteController
        }
        return nil
    }
    
    //TODO: should return be optional?
    @objc public class func startListeningAndGetValueForChangesOn(key:DJIKey, withListener:Any, andUpdateBlock:DJIKeyedListenerUpdateBlock) -> DJIKeyedValue? {
        return DJISDKManager.keyManager()?.getValueFor(key)
    }
}
