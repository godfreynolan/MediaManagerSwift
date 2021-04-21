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
import DJIWidget//TODO how to import one header?

//#import "VideoPreviewerSDKAdapter.h"
//#import "VideoPreviewerSDKAdapter+Lightbridge2.h"
//#import "DJIDecodeImageCalibrateControlLogic.h"
//#import <DJIWidget/DJIVTH264DecoderIFrameData.h>
//#import <DJISDK/DJISDK.h>

// TODO: Define constant
//const static NSTimeInterval REFRESH_INTERVAL = 1.0;

/**
 *  Information needed by DJIVideoPreviewer includes:
 *  1. Product names.
 *  2. (Osmo only) Is digital zoom supported.
 *  3. (Marvik only) Is in portrait mode.
 *  4. Photo Ratio.
 *  5. Camera Mode.
 */

class VideoPreviewerSDKAdapter: NSObject, DJIVideoFeedSourceListener, DJIVideoFeedListener, DJIVideoPreviewerFrameControlDelegate {
    
    weak var videoPreviewer : DJIVideoPreviewer?
    weak var videoFeed : DJIVideoFeed?
    
    var refreshTimer : Timer?
    var productName : NSString?
    var cameraName : NSString?
    var isAircraft : Bool?
    var cameraMode : DJICameraMode?
    var photoRatio : DJICameraPhotoAspectRatio?
    var isForLightbridge2 : Bool?
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
        super.init()
        self.cameraMode = DJICameraMode.unknown
        self.photoRatio = DJICameraPhotoAspectRatio.ratioUnknown
        
        //g_loadPrebuildIframeOverrideFunc defined in DJIVideoHelper...
//        if (g_loadPrebuildIframeOverrideFunc == NULL) {
//            g_loadPrebuildIframeOverrideFunc = loadPrebuildIframePrivate;
//        }
//        _isForLightbridge2 = NO;
//        _calibrateLogic = [[DJIDecodeImageCalibrateControlLogic alloc] init];
    }
    
    func start() {
//    [self startRefreshTimer];
//    [[DJISDKManager videoFeeder] addVideoFeedSourceListener:self];
//    if (self.videoFeed) {
//        [self.videoFeed addListener:self withQueue:nil];
//    }
//    if (self.isForLightbridge2) {
//        [self startLightbridgeListen];
//    }
    }
    
    func stop() {
        //    [self stopRefreshTimer];
        //    [[DJISDKManager videoFeeder] removeVideoFeedSourceListener:self];
        //    if (self.videoFeed) {
        //        [self.videoFeed removeListener:self];
        //    }
        //    if (self.isForLightbridge2) {
        //        [self stopLightbridgeListen];
        //    }
    }
    
    func startRefreshTimer() {
        //    dispatch_async(dispatch_get_main_queue(), ^{
        //        if (!self.refreshTimer) {
        //            self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:REFRESH_INTERVAL
        //                                                                 target:self
        //                                                               selector:@selector(updateInformation)
        //                                                               userInfo:nil
        //                                                                repeats:YES];
        //        }
        //    });
    }
    
    func stopRefreshTimer() {
        //    dispatch_async(dispatch_get_main_queue(), ^{
        //        if (self.refreshTimer) {
        //            [self.refreshTimer invalidate];
        //            self.refreshTimer = nil;
        //        }
        //    });
    }
    
    func updateInformation() {
        //    if (!self.videoPreviewer) {
        //        return;
        //    }
        //
        //    // 1. check if the product is still connecting
        //    DJIBaseProduct *product = [DJISDKManager product];
        //    if (product == nil) {
        //        return;
        //    }
        //
        //    // 2. Get product names and camera names
        //    self.productName = product.model;
        //    if (!self.productName) {
        //        [self setDefaultConfiguration];
        //        return;
        //    }
        //    self.isAircraft = [product isKindOfClass:[DJIAircraft class]];
        //    self.cameraName = [[self class] camera].displayName;
        //
        //    // Set decode type
        //    [self updateEncodeType];
        //
        //    // 3. Get camera work mode
        //    DJICamera *camera = [[self class] camera];
        //    if (camera) {
        //        weakSelf(target);
        //        [camera getModeWithCompletion:^(DJICameraMode mode, NSError * _Nullable error) {
        //            weakReturn(target);
        //            if (error == nil) {
        //                target.cameraMode = mode;
        //                [target updateContentRect];
        //            }
        //        }];
        //        [camera getPhotoAspectRatioWithCompletion:^(DJICameraPhotoAspectRatio ratio, NSError * _Nullable error) {
        //            weakReturn(target);
        //            if (error == nil) {
        //                target.photoRatio = ratio;
        //                [target updateContentRect];
        //            }
        //        }];
        //        [self updateContentRect];
        //        self.calibrateLogic.cameraName = camera.displayName;
        //    }
        //
        //    if ([camera.displayName isEqual:DJICameraDisplayNameMavicProCamera]) {
        //        [camera getOrientationWithCompletion:^(DJICameraOrientation orientation, NSError * _Nullable error) {
        //            if (error == nil) {
        //                if (orientation == DJICameraOrientationLandscape) {
        //                    [DJIVideoPreviewer instance].rotation = VideoStreamRotationDefault;
        //                }
        //                else {
        //                    [DJIVideoPreviewer instance].rotation = VideoStreamRotationCW90;
        //                }
        //            }
        //        }];
        //    }
    }
    
    func setDefaultConfiguration() {
        //    [self.videoPreviewer setEncoderType:H264EncoderType_unknown];
        //    self.videoPreviewer.rotation = VideoStreamRotationDefault;
        //    self.videoPreviewer.contentClipRect = CGRectMake(0, 0, 1, 1);
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
    //
    //    H264EncoderType encodeType = [[self class] getDataSourceWithCameraName:self.cameraName
    //                                                             andIsAircraft:self.isAircraft];;
    //
    //    [self.videoPreviewer setEncoderType:encodeType];
    //}
    }
    
    func updateContentRect() {
        //    if (self.videoFeed.physicalSource == DJIVideoFeedPhysicalSourceFPVCamera) {
        //        [self setDefaultContentRect];
        //        return;
        //    }
        //
        //    if ([self.cameraName isEqual:DJICameraDisplayNameXT]) {
        //        [self updateContentRectForXT];
        //        return;
        //    }
        //
        //    if (self.cameraMode == DJICameraModeShootPhoto) {
        //        [self updateContentRectInPhotoMode];
        //    }
        //    else {
        //        [self setDefaultContentRect];
        //    }
    }
    
    
    //
    func updateContentRectForXT() {
        //    // Workaround: when M100 is setup with XT, there are 8 useless pixels on
        //    // the left and right hand sides.
        //    if ([self. productName isEqual:DJIAircraftModelNameMatrice100]) {
        //        self.videoPreviewer.contentClipRect = CGRectMake(0.010869565217391, 0
        //                                                         , 0.978260869565217, 1);
        //    }
    }
    
    func updateContentRectInPhotoMode() {
        //    CGRect area = CGRectMake(0, 0, 1, 1);
        //    BOOL needFitToRate = NO;
        //
        //    if ([self.cameraName isEqualToString:DJICameraDisplayNameX3] ||
        //        [self.cameraName isEqualToString:DJICameraDisplayNameX5] ||
        //        [self.cameraName isEqualToString:DJICameraDisplayNameX5R] ||
        //        [self.cameraName isEqualToString:DJICameraDisplayNamePhantom3ProfessionalCamera] ||
        //        [self.cameraName isEqualToString:DJICameraDisplayNamePhantom4Camera] ||
        //        [self.cameraName isEqualToString:DJICameraDisplayNameMavicProCamera]) {
        //        needFitToRate = YES;
        //    }
        //
        //    if (needFitToRate && self.photoRatio != DJICameraPhotoAspectRatioUnknown) {
        //        CGSize rateSize;
        //
        //        switch (self.photoRatio) {
        //            case DJICameraPhotoAspectRatio3_2:
        //                rateSize = CGSizeMake(3, 2);
        //                break;
        //            case DJICameraPhotoAspectRatio4_3:
        //                rateSize = CGSizeMake(4, 3);
        //                break;
        //            default:
        //                rateSize = CGSizeMake(16, 9);
        //                break;
        //        }
        //
        //        CGRect streamRect = CGRectMake(0, 0, 16, 9);
        //        CGRect destRect = [DJIVideoPresentViewAdjustHelper aspectFitWithFrame:streamRect size:rateSize];
        //        area = [DJIVideoPresentViewAdjustHelper normalizeFrame:destRect withIdentityRect:streamRect];
        //    }
        //
        //    if (!CGRectEqualToRect(self.videoPreviewer.contentClipRect, area)) {
        //        self.videoPreviewer.contentClipRect = area;
        //    }
    }
    
    func setDefaultContentRect() {
        //    self.videoPreviewer.contentClipRect = CGRectMake(0, 0, 1, 1);

    }
    
    //MARK Helper Methods
    class func camera() -> DJICamera? { //TODO: replace usage of this function with fetchCamera, remove
        return DemoUtility.fetchCamera()
    }
    
    class func isUsingLightbridge2(with productName:NSString, isAircraft:Bool, cameraName:NSString?) -> Bool {
        if !isAircraft {
            return false
        }
        
        let productNameString = productName as String
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
    
    func getDataSource(with cameraName:NSString, isAircraft:Bool) -> H264EncoderType {
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
        }
    //    else if ([cameraName isEqualToString:DJICameraDisplayNameX5] ||
    //             [cameraName isEqualToString:DJICameraDisplayNameX5R]) {
    //        return H264EncoderType_DM368_inspire;
    //    }
    //    else if ([cameraName isEqualToString:DJICameraDisplayNamePhantom3ProfessionalCamera]) {
    //        return H264EncoderType_DM365_phamtom3x;
    //    }
    //    else if ([cameraName isEqualToString:DJICameraDisplayNamePhantom3AdvancedCamera]) {
    //        return H264EncoderType_A9_phantom3s;
    //    }
    //    else if ([cameraName isEqualToString:DJICameraDisplayNamePhantom3StandardCamera]) {
    //        return H264EncoderType_A9_phantom3c;
    //    }
    //    else if ([cameraName isEqualToString:DJICameraDisplayNamePhantom4Camera]) {
    //        return H264EncoderType_1860_phantom4x;
    //    }
    //    else if ([cameraName isEqualToString:DJICameraDisplayNameMavicProCamera]) {
    //        DJIAircraft *product = (DJIAircraft *)[DJISDKManager product];
    //        if (product.airLink.wifiLink) {
    //            return H264EncoderType_1860_phantom4x;
    //        }
    //        else {
    //            return H264EncoderType_unknown;
    //        }
    //    }
    //    else if ([cameraName isEqualToString:DJICameraDisplayNameSparkCamera]) {
    //        return H264EncoderType_1860_phantom4x;
    //    }
    //    else if ([cameraName isEqualToString:DJICameraDisplayNameZ30]) {
    //        return H264EncoderType_GD600;
    //    }
    //    else if ([cameraName isEqualToString:DJICameraDisplayNamePhantom4ProCamera] ||
    //             [cameraName isEqualToString:DJICameraDisplayNamePhantom4AdvancedCamera] ||
    //             [cameraName isEqualToString:DJICameraDisplayNameX5S] ||
    //             [cameraName isEqualToString:DJICameraDisplayNameX4S] ||
    //             [cameraName isEqualToString:DJICameraDisplayNameX7] ||
    //             [cameraName isEqualToString:DJICameraDisplayNamePayload]) {
    //        return H264EncoderType_H1_Inspire2;
    //    }
    //    else if ([cameraName isEqualToString:DJICameraDisplayNameMavicAirCamera]) {
    //        return H264EncoderType_MavicAir;
    //    }
    //
        return H264EncoderType._unknown
    }

    //MARK - video delegate

    func videoFeed(_ videoFeed: DJIVideoFeed, didUpdateVideoData videoData: Data) {
        print("TODO: videoFeed(_ videoFeed: DJIVideoFeed, didUpdateVideoData")
        //    if (videoFeed != self.videoFeed) {
        //        NSLog(@"ERROR: Wrong video feed update is received!");
        //    }
        //    [self.videoPreviewer push:(uint8_t *)[videoData bytes] length:(int)videoData.length];
    }
    
    func videoFeed(_ videoFeed: DJIVideoFeed, didChange physicalSource: DJIVideoFeedPhysicalSource) {
        print("TODO: videoFeed(_ videoFeed: DJIVideoFeed, didChange physicalSource")
        //    if (videoFeed == self.videoFeed) {
        //        if (physicalSource == DJIVideoFeedPhysicalSourceUnknown) {
        //            NSLog(@"Video feed is disconnected. ");
        //            return;
        //        }
        //        else {
        //            [self updateEncodeType];
        //            [self updateContentRect];
        //        }
        //    }
    }
    
    
    

    
    func parseDecodingAssistInfo(withBuffer buffer: UnsafeMutablePointer<UInt8>!, length: Int32, assistInfo: UnsafeMutablePointer<DJIDecodingAssistInfo>!) -> Bool {
        print("TODO: parseDecodingAssistInfo")
        //    return [self.videoFeed parseDecodingAssistInfoWithBuffer:buffer length:length assistInfo:(void *)assistInfo];
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
        print("TODO: syncDecoderStatus")
        //    [self.videoFeed syncDecoderStatus:isNormal];

    }
    
    func decodingDidSucceed(withTimestamp timestamp: UInt32) {
        print("TODO: decodingDidSucceed")
        //    [self.videoFeed decodingDidSucceedWithTimestamp:(NSUInteger)timestamp];

    }
    
    func decodingDidFail() {
        print("TODO: decodingDidFail")
        //    [self.videoFeed decodingDidFail];

    }
    

}
