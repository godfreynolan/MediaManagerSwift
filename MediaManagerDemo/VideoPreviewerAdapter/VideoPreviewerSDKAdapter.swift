//
//  VideoPreviewerSDKAdapter.swift
//  MediaManagerDemo
//
//  Created by Samuel Scherer on 4/21/21.
//  Copyright © 2021 DJI. All rights reserved.
//
//

import Foundation
import DJISDK
import DJIWidget

//#import "DemoComponentHelper.h"
//#import <DJISDK/DJISDK.h>
//#import <DJIWidget/DJIVideoPreviewer.h>
//

//#define IS_FLOAT_EQUAL(a, b) (fabs(a - b) < 0.0005)

func isFloatEqual(a:Float?, b:Float?) -> Bool {
    guard let a = a, let b = b else {
        return false
    }
    return abs(a-b) < 0.0005
}

class VideoPreviewerSDKAdapter : VideoPreviewerBase {
    
    var isEXTPortEnabled : NSNumber? //Bool
    var LBEXTPercent : NSNumber? // Float
    var HDMIAVPercent : NSNumber? //Float
    
    override func startLightbridgeListen() {
        //TODO: refactor these get initial value & continue updating into something convenient and understandable
        if let extEnabledKey = DJIAirLinkKey(index: 0,
                                          subComponent: DJIAirLinkLightbridgeLinkSubComponent,
                                          subComponentIndex: 0,
                                          andParam: DJILightbridgeLinkParamEXTVideoInputPortEnabled) {
            let extEnabled = DemoComponentHelper.startListeningAndGetValueForChangesOn(key: extEnabledKey, withListener: self) { [weak self] (oldValue:DJIKeyedValue?, newValue:DJIKeyedValue?) in
                if let newValue = newValue {
                    self?.isEXTPortEnabled = newValue.value as? NSNumber
                }
            }
            if let extEnabled = extEnabled {
                self.isEXTPortEnabled = extEnabled.value as? NSNumber
            }
        }
        
        if let LBPercentKey = DJIAirLinkKey(index: 0,
                                         subComponent: DJIAirLinkLightbridgeLinkSubComponent,
                                         subComponentIndex: 0,
                                         andParam: DJILightbridgeLinkParamBandwidthAllocationForLBVideoInputPort) {
            let LBPercent = DemoComponentHelper.startListeningAndGetValueForChangesOn(key: LBPercentKey, withListener: self) { [weak self](oldValue:DJIKeyedValue?, newValue:DJIKeyedValue?) in
                if let newValue = newValue {
                    self?.LBEXTPercent = newValue.value as? NSNumber
                }
                self?.updateVideoFeed()
            }
            if let LBPercent = LBPercent {
                self.LBEXTPercent = LBPercent.value as? NSNumber
            }
        }
        
        if let HDMIPercentKey = DJIAirLinkKey(index: 0,
                                              subComponent: DJIAirLinkLightbridgeLinkSubComponent,
                                              subComponentIndex: 0,
                                              andParam: DJILightbridgeLinkParamBandwidthAllocationForHDMIVideoInputPort) {
            let HDMIPercent = DemoComponentHelper .startListeningAndGetValueForChangesOn(key: HDMIPercentKey, withListener: self) { [weak self] (oldValue:DJIKeyedValue?, newValue:DJIKeyedValue?) in
                if let newValue = newValue {
                    self?.HDMIAVPercent = newValue.value as? NSNumber
                }
                self?.updateVideoFeed()
            }
            if let HDMIPercent = HDMIPercent {
                self.HDMIAVPercent = HDMIPercent.value as? NSNumber
            }
        }
        self.updateVideoFeed()
    }
    
    override func stopLightbridgeListen() {
        DJISDKManager.keyManager()?.stopAllListening(ofListeners: self)
    }
    
    
    //-(void)updateVideoFeed {
    func updateVideoFeed() {
    //    if (self.isEXTPortEnabled == nil) {
    //        [self swapToPrimaryVideoFeedIfNecessary];
    //        return;
    //    }
        guard let isEXTPortEnabled = self.isEXTPortEnabled?.boolValue else {
            self.swapToPrimaryVideoFeedIfNecessary()
            return
        }
        if isEXTPortEnabled {
            guard let lbExtPercent = self.LBEXTPercent else {
                self.swapToPrimaryVideoFeedIfNecessary()
                return
            }

            if isFloatEqual(a: lbExtPercent.floatValue, b: 1.0) {
                // All in primary source
                if self.isUsingPrimaryVideoFeed() {
                    self.swapVideoFeed()
                }
                return
            } else if isFloatEqual(a: lbExtPercent.floatValue, b: 0.0) {
                if self.isUsingPrimaryVideoFeed() {
                    self.swapVideoFeed()
                }
                return
            }
        } else {
            guard let hdmiAVPercent = self.HDMIAVPercent else {
                self.swapToPrimaryVideoFeedIfNecessary()
                return
            }
            if isFloatEqual(a: hdmiAVPercent.floatValue, b: 1.0) {//TODO: WTF does All in primary source mean? also understand the purpose of this logic
                // All in primary source
                if !self.isUsingPrimaryVideoFeed() {
                    self.swapVideoFeed()
                }
                return
            } else if isFloatEqual(a: hdmiAVPercent.floatValue, b: 0.0) {
                if !self.isUsingPrimaryVideoFeed() {
                    self.swapVideoFeed()
                }
                return
            }
        }
    }

    func isUsingPrimaryVideoFeed() -> Bool {
        return self.videoFeed === DJISDKManager.videoFeeder()?.primaryVideoFeed
    }
    //
    //-(void)swapVideoFeed {
    func swapVideoFeed() {
        self.videoPreviewer?.pause()
        self.videoFeed?.remove(self)
        if self.isUsingPrimaryVideoFeed() {
            self.videoFeed = DJISDKManager.videoFeeder()?.secondaryVideoFeed
        } else {
            self.videoFeed = DJISDKManager.videoFeeder()?.primaryVideoFeed
        }
        self.videoFeed?.add(self, with: nil)
        self.videoPreviewer?.safeResume()
    }
    
    func swapToPrimaryVideoFeedIfNecessary() {
        if !self.isUsingPrimaryVideoFeed() {
            self.swapVideoFeed()
        }
    }
}
