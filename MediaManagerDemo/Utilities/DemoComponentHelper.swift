//
//  DemoComponentHelper.swift
//  MediaManagerDemo
//
//  Created by Samuel Scherer on 4/14/21.
//  Copyright © 2021 RIIS. All rights reserved.
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
    
    public class func fetchRemoteController() -> DJIRemoteController? {
        if let aircraft = DJISDKManager.product() as? DJIAircraft {
            return aircraft.remoteController
        }
        return nil
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
}
