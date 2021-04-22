//
//  DecodeImageCalibrateControlLogic.swift
//  MediaManagerDemo
//
//  Created by Samuel Scherer on 4/21/21.
//  Copyright © 2021 DJI. All rights reserved.
//

import Foundation
import DJISDK
import DJIWidget

class DecodeImageCalibrateControlLogic : NSObject, DJIImageCalibrateDelegate {
    
    //@property (nonatomic, assign) NSUInteger cameraIndex;
    var cameraIndex : UInt?
    //@property (nonatomic, copy) NSString* cameraName;
    var cameraName : String?
    
    
//    BOOL _calibrateNeeded;
    var calibrateNeeded : Bool?
//    BOOL _calibrateStandAlone;
    var calibrateStandAlone : Bool?
    //data source info
//    NSDictionary* _dataSourceInfo;
    var dataSourceInfo : NSDictionary? //TODO: Use Dictionary?
//    //helper for calibration
//    DJIImageCalibrateHelper* _helper;
    var helper : DJIImageCalibrateHelper?
//    //calibrate datasource
//    DJIImageCalibrateFilterDataSource* _dataSource;
    var dataSource : DJIImageCalibrateFilterDataSource?
//    //camera work mode
//    DJICameraMode _workMode;
    var workMode : DJICameraMode?
    
    deinit {
        self.releaseHelper()
    }
    //
    //- (instancetype)init{
    override init() {
        self.dataSourceInfo = [DJIMavic2ZoomCameraImageCalibrateFilterDataSource.self: DJICameraDisplayNameMavic2ZoomCamera,
                               DJIMavic2ProCameraImageCalibrateFilterDataSource.self: DJICameraDisplayNameMavicProCamera]
        super.init()
        self.initData()
    }

    func initData() {
        self.helper = nil
        self.dataSource = nil
        self.calibrateNeeded = false
        self.cameraIndex = 0
        self.calibrateStandAlone = false
    }
    
    func set(cameraName:String) {
        if self.cameraName == cameraName {
            return
        }
        self.cameraName = cameraName
        self.calibrateNeeded = (cameraName == DJICameraDisplayNameMavic2ZoomCamera) ||
                                (cameraName == DJICameraDisplayNameMavic2ProCamera)
        self.calibrateStandAlone = false
    }
    
    //-(Class)targetHelperClass{
    func targetHelperClass() -> AnyClass {
    //    if (_calibrateStandAlone){
        if let calibrateStandAlone = self.calibrateStandAlone {
            if calibrateStandAlone {
                return DJIDecodeImageCalibrateHelper.self
            }
        }
        return DJIImageCalibrateHelper.self
    }

    //MARK - calibration delegate
    func shouldCreateHelper() -> Bool {
        return self.calibrateNeeded ?? true//TODO: reconsider what to do on nil value
    }
    
    func destroyHelper() {
        self.releaseHelper()
    }
    //
    func helperCreated() -> DJIImageCalibrateHelper! {
        print("TODO: implement helperCreated!")
        return DJIImageCalibrateHelper()
        //    Class targetClass = [self targetHelperClass];
        //    if (_helper != nil){
        //        BOOL shouldRemoved = !_calibrateNeeded;
        //        if (targetClass == nil
        //            || ![_helper isMemberOfClass:targetClass]){
        //            shouldRemoved = YES;
        //        }
        //        if (shouldRemoved){
        //            _helper = nil;
        //        }
        //    }
        //    if (!_calibrateNeeded){
        //        return nil;
        //    }
        //    if (_helper){
        //        return _helper;
        //    }
        //    DJIImageCalibrateHelper* helper = [[targetClass alloc] initShouldCreateCalibrateThread:NO
        //                                                                           andRenderThread:NO];
        //    _helper = helper;
        //    return helper;
    }

    //
    func calibrateDataSource() -> DJIImageCalibrateFilterDataSource! {
        print("TODO: calibrateDataSource() -> DJIImageCalibrateFilterDataSource!")
        return DJIImageCalibrateFilterDataSource()
        //    Class targetClass = [_dataSourceInfo objectForKey:self.cameraName];
        //    if (!targetClass
        //        || ![targetClass isSubclassOfClass:[DJIImageCalibrateFilterDataSource class]]){
        //        targetClass = [DJIImageCalibrateFilterDataSource class];
        //    }
        //    if (_dataSource != nil
        //        && (![_dataSource isMemberOfClass:targetClass]
        //            || _dataSource.workMode != _workMode)){
        //        _dataSource = nil;
        //    }
        //    if (!_dataSource){
        //        _dataSource = [targetClass instanceWithWorkMode:_workMode];
        //    }
        //    return _dataSource;
    }

    
    //MARK - internal
    func releaseHelper() {
        print("TODO: releaseHelper")
    //    if (_helper != nil){
    //        _helper = nil;
    //    }
    //    if (_dataSource != nil){
    //        _dataSource = nil;
    //    }
    }
}
