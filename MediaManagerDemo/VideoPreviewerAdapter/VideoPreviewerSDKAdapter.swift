//
//  VideoPreviewerSDKAdapter.swift
//  MediaManagerDemo
//
//  Created by Samuel Scherer on 4/20/21.
//  Copyright © 2021 DJI. All rights reserved.
//

import Foundation
import DJISDK

//#import <DJIWidget/DJIVideoPreviewer.h>
import DJIWidget//TODO how to import one header from module?

//#import "VideoPreviewerSDKAdapter+Lightbridge2.h"
//#import "DJIDecodeImageCalibrateControlLogic.h"
//#import <DJIWidget/DJIVTH264DecoderIFrameData.h>

// TODO: Define constant
//const static NSTimeInterval REFRESH_INTERVAL = 1.0;

/**
 *  Information needed by DJIVideoPreviewer includes:
 *  1. Product names.
 *  2. (Osmo only) Is digital zoom supported.
 *  3. (Mavic only) Is in portrait mode.
 *  4. Photo Ratio.
 *  5. Camera Mode.
 */

class VideoPreviewerSDKAdapter: NSObject, DJIVideoFeedSourceListener, DJIVideoFeedListener, DJIVideoPreviewerFrameControlDelegate {
    weak var videoPreviewer : DJIVideoPreviewer?
    weak var videoFeed : DJIVideoFeed?
    
    var refreshTimer : Timer?
    var productName : String?
    var cameraName : String?
    var isAircraft : Bool?
    var cameraMode : DJICameraMode?
    var photoRatio : DJICameraPhotoAspectRatio?
    var isForLightbridge2 : Bool
    var calibrateLogic : DJIDecodeImageCalibrateControlLogic?
    
    
    class func adapterWithDefaultSettings() -> VideoPreviewerSDKAdapter {
        //TODO: revisit force unwrap
        return Self.adapterWith(videoPreviewer:DJIVideoPreviewer.instance(), videoFeed:(DJISDKManager.videoFeeder()!.primaryVideoFeed))
    }
    
    class func adapterForLightbridge2() -> VideoPreviewerSDKAdapter {
        let adapter = self.adapterWithDefaultSettings()
        adapter.isForLightbridge2 = true
        return adapter
    }

    class func adapterWith(videoPreviewer:DJIVideoPreviewer, videoFeed:DJIVideoFeed) -> VideoPreviewerSDKAdapter {
        let adapter = VideoPreviewerSDKAdapter()
        adapter.videoPreviewer = videoPreviewer
        adapter.videoFeed = videoFeed
        adapter.videoPreviewer?.calibrateDelegate = adapter.calibrateLogic
        return adapter
    }
    
    override init() {
        self.cameraMode = DJICameraMode.unknown
        self.photoRatio = DJICameraPhotoAspectRatio.ratioUnknown
        
        //g_loadPrebuildIframeOverrideFunc defined in DJIVideoHelper...
        // TODO: figure out what this actually does...
        if g_loadPrebuildIframeOverrideFunc == nil {
            g_loadPrebuildIframeOverrideFunc = loadPrebuildIframePrivate
        }
        //---------------------------------
        
        self.isForLightbridge2 = false
        self.calibrateLogic = DJIDecodeImageCalibrateControlLogic()
        super.init()
    }
    
    func start() {
        self.startRefreshTimer()
        DJISDKManager.videoFeeder()?.add(self)
        if let videoFeed = self.videoFeed  {
            videoFeed.add(self, with: nil)
        }
        if self.isForLightbridge2 {
            //self.startLightbridgeListen()
        }
    }
    
    func stop() {
        self.stopRefreshTimer()
        DJISDKManager.videoFeeder()?.remove(self)
        if let videoFeed = self.videoFeed {
            videoFeed.remove(self)
        }
        if self.isForLightbridge2 {
            //TODO: uncomment once implemented by class extension (why is lighbridge stuff in an extension?)
            //self.stopLightbridgeListen()
        }
    }
    
    func startRefreshTimer() {
        DispatchQueue.main.async {
            if self.refreshTimer == nil {
                //TODO: use a (global?)constant for REFRESH_INTERVAL... I think it was 1 second...
                self.refreshTimer = Timer.scheduledTimer(timeInterval: 1.0,
                                                         target: self,
                                                         selector: #selector(self.updateInformation),
                                                         userInfo: nil,
                                                         repeats: true)
            }
        }
    }
    
    func stopRefreshTimer() {
        DispatchQueue.main.async {
            //TODO: go through with a debugger and make sure refreshTimer and self.refreshTimer refer to the same object in memory
            if let refreshTimer = self.refreshTimer {
                refreshTimer.invalidate()
                self.refreshTimer = nil //if I nil out refreshTimer would that do the same thing?
            }
        }
    }
    
    @objc func updateInformation() {
        if self.videoPreviewer == nil {
            return
        }

        // 1. check if the product is still connecting
        guard let product = DemoUtility.fetchProduct() else {
            return
        }

        // 2. Get product names and camera names
        self.productName = product.model
        if self.productName == nil {
            self.setDefaultConfiguration()
            return
        }

        self.isAircraft = type(of: product) == DJIAircraft.self
    
        // Set decode type
        self.updateEncodeType()
    
        // 3. Get camera work mode
        if let camera = DemoUtility.fetchCamera() {
            camera.getModeWithCompletion { [weak self] (mode:DJICameraMode, error:Error?) in
                if error == nil {
                    self?.cameraMode = mode
                    self?.updateContentRect()
                }
            }
            camera.getPhotoAspectRatio { [weak self] (ratio:DJICameraPhotoAspectRatio, error:Error?) in
                if error == nil {
                    self?.photoRatio = ratio
                    self?.updateContentRect()
                }
            }
            self.updateContentRect()
            self.calibrateLogic?.cameraName = camera.displayName
            
            if camera.displayName == DJICameraDisplayNameMavicProCamera {
                camera.getOrientationWithCompletion { (orientation:DJICameraOrientation, error:Error?) in
                    if error == nil {
                        if orientation == DJICameraOrientation.landscape {
                            DJIVideoPreviewer.instance()?.rotation = VideoStreamRotationType.default
                        } else {
                            DJIVideoPreviewer.instance()?.rotation = VideoStreamRotationType.CW90
                        }
                    }
                }
            }
        }
    }
    
    func setDefaultConfiguration() {
        self.videoPreviewer?.encoderType = H264EncoderType._unknown
        self.videoPreviewer?.rotation = VideoStreamRotationType.default
        self.videoPreviewer?.contentClipRect = CGRect(x: 0, y: 0, width: 1, height: 1)
    }
    
    // For Mavic 2
    func setupFrameControlHandler() {
        self.videoPreviewer?.frameControlHandler = self
    }

    func updateEncodeType() {
        // Check if Inspire 2 FPV
        if (self.videoFeed?.physicalSource == DJIVideoFeedPhysicalSource.fpvCamera) {
            self.videoPreviewer?.encoderType = H264EncoderType._1860_Inspire2_FPV
            return
        }

        // Check if Lightbridge 2
    //    if ([[self class] isUsingLightbridge2WithProductName:self.productName
    //                                              isAircraft:self.isAircraft
    //                                              cameraName:self.cameraName]) {
    //        [self.videoPreviewer setEncoderType:H264EncoderType_LightBridge2];
    //        return;
    //    }
        if Self.isUsingLightbridge2(with: self.productName, isAircraft: self.isAircraft, cameraName: self.cameraName) {
            self.videoPreviewer?.encoderType = H264EncoderType._LightBridge2
            return
        }

        let encodeType = Self.getDataSource(with: (self.cameraName ?? "") as NSString, isAircraft: self.isAircraft ?? false)

        self.videoPreviewer?.encoderType = encodeType
    }
    
    func updateContentRect() {
        if self.videoFeed?.physicalSource == DJIVideoFeedPhysicalSource.fpvCamera {
            self.setDefaultContentRect()
            return
        }

        if self.cameraName == DJICameraDisplayNameXT {
            self.updateContentRectForXT()
            return
        }

        if self.cameraMode == DJICameraMode.shootPhoto {
            self.updateContentRectInPhotoMode()
        } else {
            self.setDefaultContentRect()
        }
    }
    
    func updateContentRectForXT() {
        // Workaround: when M100 is setup with XT, there are 8 useless pixels on
        // the left and right hand sides.
        if self.productName == DJIAircraftModelNameMatrice100 {
            self.videoPreviewer?.contentClipRect = CGRect(x: 0.010869565217391, y: 0, width: 0.978260869565217, height: 1)
        }
    }
    
    func updateContentRectInPhotoMode() {
        var area = CGRect(x: 0, y: 0, width: 1, height: 1)
        var needFitToRate = false
        
        if self.cameraName == DJICameraDisplayNameX3 ||
            self.cameraName == DJICameraDisplayNameX5 ||
            self.cameraName == DJICameraDisplayNameX5R ||
            self.cameraName == DJICameraDisplayNamePhantom3ProfessionalCamera ||
            self.cameraName == DJICameraDisplayNamePhantom4Camera ||
            self.cameraName == DJICameraDisplayNameMavicProCamera {
            needFitToRate = true
        }
        
        if needFitToRate && (self.photoRatio != DJICameraPhotoAspectRatio.ratioUnknown) {
            var rateSize : CGSize
            switch self.photoRatio! { //TODO: reconsider force unwrap
            case DJICameraPhotoAspectRatio.ratio3_2:
                rateSize = CGSize(width: 3, height: 2)
            case DJICameraPhotoAspectRatio.ratio4_3:
                rateSize = CGSize(width: 4, height: 3)
            default:
                rateSize = CGSize(width: 16, height: 9)
                break
            }
            let streamRect = CGRect(x: 0, y: 0, width: 16, height: 9)
            let destRect = DJIVideoPresentViewAdjustHelper.aspectFit(withFrame: streamRect, size: rateSize)
            area = DJIVideoPresentViewAdjustHelper.normalizeFrame(destRect, withIdentityRect: streamRect)
        }
        
        if self.videoPreviewer?.contentClipRect == area {
            self.videoPreviewer?.contentClipRect = area
        }
    }
    
    func setDefaultContentRect() {
        self.videoPreviewer?.contentClipRect = CGRect(x: 0, y: 0, width: 1, height: 1)
    }
    
    //MARK - Helper Methods
    class func camera() -> DJICamera? { //TODO: replace usage of this function with fetchCamera, remove
        return DemoUtility.fetchCamera()
    }
    
    class func isUsingLightbridge2(with productName:String?, isAircraft:Bool?, cameraName:String?) -> Bool {
        guard let productName = productName, let isAircraft = isAircraft else {
            return false
        }
        
        if !isAircraft {
            return false
        }
        
        let productNameString = productName
        if productNameString == DJIAircraftModelNameA3 ||
            productNameString == DJIAircraftModelNameN3 ||
            productNameString == DJIAircraftModelNameMatrice600 ||
            productNameString == DJIAircraftModelNameMatrice600Pro {
            return true
        } else if productNameString == DJIAircraftModelNameUnknownAircraft {
            if cameraName == nil {
                return true
            }
        }
        
        return false;
    }
    
    class func getDataSource(with cameraName:NSString, isAircraft:Bool) -> H264EncoderType {
        let cameraNameString = cameraName as String
        if cameraNameString == DJICameraDisplayNameX3 {
            let camera = DemoUtility.fetchCamera()
            /**
             *  Osmo's video encoding solution is changed since a firmware version.
             *  X3 also began to support digital zoom since that version. Therefore,
             *  `isDigitalZoomSupported` is used to determine the correct
             *  encode type.
             */
            if (!isAircraft) && (camera?.isDigitalZoomSupported() ?? false) {
                return H264EncoderType._A9_OSMO_NO_368
            } else {
                return H264EncoderType._DM368_inspire
            }
        } else if cameraNameString == DJICameraDisplayNameZ3 {
            return H264EncoderType._A9_OSMO_NO_368
        } else if cameraNameString == DJICameraDisplayNameX5 ||
                    cameraNameString == DJICameraDisplayNameX5R {
            return H264EncoderType._DM368_inspire
        } else if cameraNameString == DJICameraDisplayNamePhantom3ProfessionalCamera {
            return H264EncoderType._DM365_phamtom3x
        } else if cameraNameString == DJICameraDisplayNamePhantom3AdvancedCamera {
            return H264EncoderType._A9_phantom3s
        } else if cameraNameString == DJICameraDisplayNamePhantom3StandardCamera {
            return H264EncoderType._A9_phantom3c
        } else if cameraNameString == DJICameraDisplayNamePhantom4Camera {
            return H264EncoderType._1860_phantom4x
        } else if cameraNameString == DJICameraDisplayNameMavicProCamera {
            let aircraft = DemoUtility.fetchAircraft()
            if aircraft?.airLink?.wifiLink != nil {
                return H264EncoderType._1860_phantom4x
            } else {
                return H264EncoderType._unknown
            }
        } else if cameraNameString == DJICameraDisplayNameSparkCamera {
            return H264EncoderType._1860_phantom4x
        } else if cameraNameString == DJICameraDisplayNameZ30 {
            return H264EncoderType._GD600
        } else if cameraNameString == DJICameraDisplayNamePhantom4ProCamera ||
                    cameraNameString == DJICameraDisplayNamePhantom4AdvancedCamera ||
                    cameraNameString == DJICameraDisplayNameX5S ||
                    cameraNameString == DJICameraDisplayNameX4S ||
                    cameraNameString == DJICameraDisplayNameX7 ||
                    cameraNameString == DJICameraDisplayNamePayload {
            return H264EncoderType._H1_Inspire2
        } else if cameraNameString == DJICameraDisplayNameMavicAirCamera {
            return H264EncoderType._MavicAir
        }
        return H264EncoderType._unknown
    }

    //MARK - video delegate
    func videoFeed(_ videoFeed: DJIVideoFeed, didUpdateVideoData videoData: Data) {
        let videoNSData = videoData as NSData //TODO: consider using Data not NSData
        if videoFeed !== self.videoFeed {
            print("ERROR: Wrong video feed update is received!")
        }
        
        self.videoPreviewer?.push(UnsafeMutablePointer(mutating:videoNSData.bytes.assumingMemoryBound(to: UInt8.self)), length: Int32(videoNSData.length))
    }
    
    func videoFeed(_ videoFeed: DJIVideoFeed, didChange physicalSource: DJIVideoFeedPhysicalSource) {
        if videoFeed === self.videoFeed {
            if physicalSource == DJIVideoFeedPhysicalSource.unknown {
                print("Video feed is disconnected. ")
                return
            } else {
                self.updateEncodeType()
                self.updateContentRect()
            }
        }
    }
    
    func parseDecodingAssistInfo(withBuffer buffer: UnsafeMutablePointer<UInt8>!, length: Int32, assistInfo: UnsafeMutablePointer<DJIDecodingAssistInfo>!) -> Bool {
        if let videoFeed = self.videoFeed {
            return videoFeed.parseDecodingAssistInfo(withBuffer: buffer, length: length, assistInfo: assistInfo)
        }
        return false
    }
    
    func isNeedFitFrameWidth() -> Bool {
        if let displayName = DemoUtility.fetchCamera()?.displayName {
            if displayName == DJICameraDisplayNameMavic2ZoomCamera ||
                displayName == DJICameraDisplayNameMavic2ProCamera {
                return true
            }
        }
        return false
    }
    
    func syncDecoderStatus(_ isNormal: Bool) {
        self.videoFeed?.syncDecoderStatus(isNormal)
    }
    
    func decodingDidSucceed(withTimestamp timestamp: UInt32) {
        self.videoFeed?.decodingDidSucceed(withTimestamp: UInt(timestamp))

    }
    
    func decodingDidFail() {
        self.videoFeed?.decodingDidFail()
    }
    

}
