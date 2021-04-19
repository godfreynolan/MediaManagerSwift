//
//  MediaManagerViewController.swift
//  MediaManagerDemo
//
//  Created by Samuel Scherer on 4/16/21.
//  Copyright © 2021 DJI. All rights reserved.
//

import Foundation
import DJISDK
import DJIWidget

class MediaManagerViewController : UIViewController, DJICameraDelegate, DJIMediaManagerDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var cancelBtn: UIButton!
    @IBOutlet weak var displayImageView: UIImageView!
    @IBOutlet weak var editBtn: UIButton!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var mediaTableView: UITableView!
    @IBOutlet weak var positionTextField: UITextField!
    @IBOutlet weak var reloadBtn: UIButton!
    @IBOutlet weak var videoPreviewView: UIView!
    
    var showVideoPreivewView: UIView? //TODO: fix spelling, also how is this different from videoPreviewView?
    var previewerAdapter: VideoPreviewerSDKAdapter?
    
    weak var mediaManager : DJIMediaManager?
    var mediaList : [DJIMediaFile]?
    //@property(nonatomic, strong) NSMutableArray* mediaList;

    //TODO: need these?
    
    //@property(nonatomic, strong) AlertView *statusAlertView;
    var statusAlertView : AlertView?
    //@property(nonatomic) DJIMediaFile *selectedMedia;
    var selectedMedia : DJIMediaFile?
    //@property(nonatomic) NSUInteger previousOffset;
    var previousOffset : UInt?
    //@property(nonatomic) NSMutableData *fileData;
    var fileData : Data?
    //@property (nonatomic) DJIScrollView *statusView;
    var statusView : DJIScrollView?
    //@property (nonatomic, strong) NSIndexPath *selectedCellIndexPath;
    //@property (nonatomic, strong) DJIRTPlayerRenderView *renderView;
    var renderView : DJIRTPlayerRenderView?

    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("TODO")
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TEST", for: indexPath)
        print("TODO")
        return cell
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let optionalCamera = DemoUtility.fetchCamera()
        guard let camera = optionalCamera else {
            print("Couldn't fetch camera")
            return
        }
        camera.delegate = self
        self.mediaManager = camera.mediaManager
        self.mediaManager?.delegate = self
        camera.setMode(DJICameraMode.mediaDownload) { (error : Error?) in
            if let error = error {
                print("setMode failed: %@", error.localizedDescription)
            }
        }
        self.loadMediaList()
        
        if self.hasPlaybackFor(cameraName: camera.displayName) {
        

            self.setupRenderViewPlaybacker()
        } else {
            self.setupVideoPreviewer()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //TODO: can these two lines be consolidated?
        let optionalCamera = DemoUtility.fetchCamera()
        guard let camera = optionalCamera else {
            return
        }
        
        camera.setMode(DJICameraMode.shootPhoto, withCompletion: { (error: Error?) in
            if let error = error {
                DemoUtility.show(result: NSString(format: "Set CameraWorkModeShootPhoto Failed, %@", error.localizedDescription))
            }
        })
        

            
        if self.hasPlaybackFor(cameraName: camera.displayName) {
            self.cleanupRenderViewPlaybacker()
        } else {
            self.cleanupVideoPreviewer()
        }
        
        guard let cameraDelegate = camera.delegate else {
            return
        }
        if cameraDelegate.isEqual(self) {
            camera.delegate = nil
            self.mediaManager?.delegate = nil
        }
    }
    
    func hasPlaybackFor(cameraName:String) -> Bool {
        return cameraName == DJICameraDisplayNamePhantom4Camera ||
               cameraName == DJICameraDisplayNamePhantom4ProCamera ||
               cameraName == DJICameraDisplayNamePhantom4AdvancedCamera ||
               cameraName == DJICameraDisplayNameX4S ||
               cameraName == DJICameraDisplayNameX5S ||
               cameraName == DJICameraDisplayNameX7 ||
               cameraName == DJICameraDisplayNameX3 ||
               cameraName == DJICameraDisplayNameXT ||
               cameraName == DJICameraDisplayNameZ3 ||
               cameraName == DJICameraDisplayNameZ30 ||
               cameraName == DJICameraDisplayNameXT2Visual ||
               cameraName == DJICameraDisplayNameXT2Thermal ||
               cameraName == DJICameraDisplayNamePhantom3AdvancedCamera
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initData()
    }

    //TODO: can be property?
    func prefersStatusBarHidden() -> Bool {
        return false
    }
    
    //#pragma mark - Custom Methods
    func initData() {
        self.mediaList = [DJIMediaFile]()
        self.cancelBtn.isEnabled = false
        self.reloadBtn.isEnabled = false
        self.editBtn.isEnabled = false
        
        self.fileData = nil
        self.selectedMedia = nil
        self.previousOffset = 0
        
        self.statusView = DJIScrollView.viewWith(viewController: self)
        self.statusView?.isHidden = true
        
    }
    
    func setupRenderViewPlaybacker() {
        //Support Video Playback for Phantom 4 Professional, Inspire 2
        var encoderType = H264EncoderType._unknown
        if let camera = DemoUtility.fetchCamera() {
            if camera.displayName == DJICameraDisplayNamePhantom4ProCamera ||
               camera.displayName == DJICameraDisplayNamePhantom4AdvancedCamera ||
               camera.displayName == DJICameraDisplayNameX4S ||
               camera.displayName == DJICameraDisplayNameX5S { //Phantom 4 Professional, Phantom 4 Advanced and Inspire 2
                encoderType = H264EncoderType._H1_Inspire2
            }
        }
        self.renderView = DJIRTPlayerRenderView(decoderType: LiveStreamDecodeType.vtHardware,
                                                encoderType: encoderType)
        //TODO: better practice on unwrapping optional properties?
        guard self.renderView != nil else {
            return
        }
        self.renderView!.frame = self.videoPreviewView.bounds
        self.videoPreviewView.addSubview(self.renderView!)
        self.renderView?.isHidden = true
    }
    
    func cleanupRenderViewPlaybacker() {//TODO: how can you set an outlet view to nil? Why do you need to check for nil?
        self.videoPreviewView.removeFromSuperview()
        self.videoPreviewView = nil
        self.renderView = nil
    }
    
    //- (void)cleanupRenderViewPlaybacker
    //{
    //    if (self.videoPreviewView != nil) {
    //        [self.videoPreviewView removeFromSuperview];
    //        self.videoPreviewView = nil;
    //    }
    //
    //    self.renderView = nil;
    //}
    //
    
    func setupVideoPreviewer() {
        print("TODO: setupVideoPreviewer")
        self.showVideoPreivewView = UIView(frame: self.videoPreviewView.bounds)
        self.videoPreviewView.addSubview(self.showVideoPreivewView!)
        DJIVideoPreviewer.instance().type = DJIVideoPreviewerType.autoAdapt
        DJIVideoPreviewer.instance()?.start()
        DJIVideoPreviewer.instance()?.reset()
        DJIVideoPreviewer.instance()?.setView(self.showVideoPreivewView)
        self.previewerAdapter = VideoPreviewerSDKAdapter.withDefaultSettings()
        self.previewerAdapter?.start()
        //TODO: enable hardware decoding for simulator
        //#if !TARGET_IPHONE_SIMULATOR
        //    [DJIVideoPreviewer instance].enableHardwareDecode = YES;
        //#endif
        
        self.previewerAdapter?.setupFrameControlHandler()
    }
    
    func cleanupVideoPreviewer() {
        if let showVideoPreviewView = self.showVideoPreivewView {
            showVideoPreviewView.removeFromSuperview()
            self.showVideoPreivewView = nil
        }
        DJIVideoPreviewer.instance()?.unSetView()
    }


    func loadMediaList() {
        self.loadingIndicator.isHidden = false
        if self.mediaManager?.sdCardFileListState == DJIMediaFileListState.syncing ||
           self.mediaManager?.sdCardFileListState == DJIMediaFileListState.deleting {
            print("Media Manager is busy. ")
        } else {
            //TODO: use weak self
            self.mediaManager?.refreshFileList(of: DJICameraStorageLocation.sdCard, withCompletion: { (error:Error?) in
                //TODO: weak return
                if let error = error {
                    print("Fetch Media File List Failed: %@", error.localizedDescription)
                } else {
                    print("Fetch Media File List Success.")
                    if let mediaFileList = self.mediaManager?.sdCardFileListSnapshot() {
                        self.updateMediaList(mediaList:mediaFileList)
                    }
                }
            })
            
        }
    }

    //-(void) loadMediaList
    //{
    //    [self.loadingIndicator setHidden:NO];
    //    if (self.mediaManager.sdCardFileListState == DJIMediaFileListStateSyncing ||
    //             self.mediaManager.sdCardFileListState == DJIMediaFileListStateDeleting) {
    //        NSLog(@"Media Manager is busy. ");
    //    }else {
    //        WeakRef(target);
    //        [self.mediaManager refreshFileListOfStorageLocation:DJICameraStorageLocationSDCard withCompletion:^(NSError * _Nullable error) {
    //            WeakReturn(target);
    //            if (error) {
    //                //ShowResult(@"Fetch Media File List Failed: %@", error.localizedDescription);
    //            }
    //            else {
    //                NSLog(@"Fetch Media File List Success.");
    //                NSArray *mediaFileList = [target.mediaManager sdCardFileListSnapshot];
    //                [target updateMediaList:mediaFileList];
    //            }
    //            [target.loadingIndicator setHidden:YES];
    //        }];
    //
    //    }
    //}
    //
    
    func updateMediaList(mediaList:[DJIMediaFile]) {
        self.mediaList?.removeAll()
        self.mediaList?.append(contentsOf: mediaList)
        
        if let mediaTaskScheduler = DemoUtility.fetchCamera()?.mediaManager?.taskScheduler {
            mediaTaskScheduler.suspendAfterSingleFetchTaskFailure = false
            mediaTaskScheduler.resume(completion: nil)
            self.mediaList?.forEach({ (file:DJIMediaFile) in
                if file.thumbnail == nil {
                    //TODO: take weak self
                    let task = DJIFetchMediaTask(file: file, content: DJIFetchMediaTaskContent.thumbnail) { (file: DJIMediaFile, content: DJIFetchMediaTaskContent, error: Error?) in
                        //TODO: weak return
                        self.mediaTableView.reloadData()
                    }
                    mediaTaskScheduler.moveTask(toEnd: task)
                }
            })
        }
        self.reloadBtn.isEnabled = true
        self.editBtn.isEnabled = true
    }

    func showPhotoWithData(data:Data?) {
        if let data = data {
            let image = UIImage(data: data)
            self.displayImageView.image = image
            self.displayImageView.isHidden = false
        }
    }
    
    func statusToString(status:DJIMediaVideoPlaybackStatus) -> String? {
        switch status {
        case DJIMediaVideoPlaybackStatus.paused:
            return "Paused"
        case DJIMediaVideoPlaybackStatus.playing:
            return "Playing"
        case DJIMediaVideoPlaybackStatus.stopped:
            return "Stopped"
        default:
            return nil
        }
    }
    
    func orientationToString(orientation: DJICameraOrientation) -> String? {
        switch orientation {
        case DJICameraOrientation.landscape:
            return "Landscape"
        case DJICameraOrientation.portrait:
            return "Portrait"
        default:
            return nil
        }
    }
    
    @objc func dismissStatusAlertView() {
        self.statusAlertView?.dismissAlertView()
        self.statusAlertView = nil
    }
    
    // MARK - IBAction Methods
    
    
    @IBAction func backBtnAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }

    
    @IBAction func editBtnAction(_ sender: Any) {
        self.mediaTableView.setEditing(true, animated: true)
        self.cancelBtn.isEnabled = true
        self.editBtn.isEnabled = false
    }
    
    @IBAction func cancelBtnAction(_ sender: Any) {
        self.mediaTableView.setEditing(false, animated: true)
        self.editBtn.isEnabled = true
        self.cancelBtn.isEnabled = false
    }
    
    @IBAction func reloadBtnAction(_ sender: Any) {
        self.loadMediaList()
    }

    @IBAction func statusBtnAction(_ sender: Any) {
        self.statusView?.isHidden = false
        self.statusView?.show()
    }
    
    
    @IBAction func downloadBtnAction(_ sender: Any) {
        guard self.selectedMedia != nil else {
            return
        }
        let isPhoto = self.selectedMedia?.mediaType == DJIMediaType.JPEG || self.selectedMedia?.mediaType == DJIMediaType.TIFF
        //TODO: Weak self as target
        if (self.statusAlertView == nil) {
            //let message = String(format: "Fetch Media Data \n 0.0")
            let message = NSString(format: "Fetch Media Data \n 0.0")
                        
            /*self.statusAlertView = */AlertView.showAlertWith(message: message, titles: ["Cancel"], action: {(buttonIndex: Int) -> () in
                //TODO: weak return
                if (buttonIndex == 0) {
                    self.selectedMedia?.stopFetchingFileData(completion: { (error: Error?) in
                        self.statusAlertView = nil
                    })
                }
            })
        }
        if let previousOffset = self.previousOffset {
            self.selectedMedia?.fetchData(withOffset: previousOffset, update: DispatchQueue.main, update: { (data:Data?, isComplete: Bool, error:Error?) in
                //TODO: weak return self
                if let error = error {
                    //TODO: commented in original? why?
                    print("Download Media Failed:%@",error)
                    //[target.statusAlertView updateMessage:[[NSString alloc] initWithFormat:@"Download Media Failed:%@",error]];
                    self.perform(#selector(self.dismissStatusAlertView), with: nil, afterDelay: 2.0)
                } else {
                    if isPhoto {
                        if let data = data {
                            if self.fileData == nil {
                                self.fileData = data//TODO: mutable copy?
                                //                    target.fileData = [data mutableCopy];
                            } else {
                                    self.fileData?.append(data)//Again, mutable copy necessary?
                            }
                            self.previousOffset = self.previousOffset ?? 0 + UInt(data.count)
                        }
                    }
                    if let selectedFileSizeBytes = self.selectedMedia?.fileSizeInBytes {
                        let progress = Float(self.previousOffset ?? 0) * 100.0 / Float(selectedFileSizeBytes)
                        self.statusAlertView?.update(message: String(format: "Downloading: %0.1f%%", progress) as NSString)
                        if isComplete {
                            self.dismissStatusAlertView()
                            if (isPhoto) {
                                self.showPhotoWithData(data: self.fileData)
                                self.showPhotoWithData(data: self.fileData)
                            }
                        }
                    }
                }
            })
        }
    }
    
    //

    //
    //    [self.selectedMedia fetchFileDataWithOffset:self.previousOffset updateQueue:dispatch_get_main_queue() updateBlock:^(NSData * _Nullable data, BOOL isComplete, NSError * _Nullable error) {
    //        WeakReturn(target);
    //        if (error) {
    //            //[target.statusAlertView updateMessage:[[NSString alloc] initWithFormat:@"Download Media Failed:%@",error]];
    //            [target performSelector:@selector(dismissStatusAlertView) withObject:nil afterDelay:2.0];
    //        }
    //        else
    //        {
    //            if (isPhoto) {
    //                if (target.fileData == nil) {
    //                    target.fileData = [data mutableCopy];
    //                }
    //                else {
    //                    [target.fileData appendData:data];
    //                }
    //            }
    //            target.previousOffset += data.length;
    //            float progress = target.previousOffset * 100.0 / target.selectedMedia.fileSizeInBytes;
    //            //[target.statusAlertView updateMessage:[NSString stringWithFormat:@"Downloading: %0.1f%%", progress]];
    //            if (target.previousOffset == target.selectedMedia.fileSizeInBytes && isComplete) {
    //                [target dismissStatusAlertView];
    //                if (isPhoto) {
    //                    [target showPhotoWithData:target.fileData];
    //                    [target savePhotoWithData:target.fileData];
    //                }
    //            }
    //        }
    //    }];
    //}
    //
    //- (IBAction)playBtnAction:(id)sender {
    //
    //    [self.displayImageView setHidden:YES];
    //    [self.renderView setHidden:NO];
    //
    //    if ((self.selectedMedia.mediaType == DJIMediaTypeMOV) || (self.selectedMedia.mediaType == DJIMediaTypeMP4)) {
    //        [self.positionTextField setPlaceholder:[NSString stringWithFormat:@"%d sec", (int)self.selectedMedia.durationInSeconds]];
    //        [self.mediaManager playVideo:self.selectedMedia withCompletion:^(NSError * _Nullable error) {
    //            if (error) {
    //                //ShowResult(@"Play Video Failed: %@", error.description);
    //            }
    //        }];
    //    }
    //}
    //
    //- (IBAction)resumeBtnAction:(id)sender {
    //
    //    [self.mediaManager resumeWithCompletion:^(NSError * _Nullable error) {
    //        if (error) {
    //            //ShowResult(@"Resume failed: %@", error.description);
    //        }
    //    }];
    //}
    //
    //- (IBAction)pauseBtnAction:(id)sender {
    //    [self.mediaManager pauseWithCompletion:^(NSError * _Nullable error) {
    //        if (error) {
    //            //ShowResult(@"Pause failed: %@", error.description);
    //        }
    //    }];
    //}
    //
    //- (IBAction)stopBtnAction:(id)sender {
    //    [self.mediaManager stopWithCompletion:^(NSError * _Nullable error) {
    //        if (error) {
    //            //ShowResult(@"Stop failed: %@", error.description);
    //        }
    //    }];
    //}
    //
    //- (IBAction)moveToPositionAction:(id)sender {
    //    NSUInteger second = 0;
    //    if (self.positionTextField.text.length) {
    //        second = [self.positionTextField.text floatValue];
    //    }
    //
    //    WeakRef(target);
    //    [self.mediaManager moveToPosition:second withCompletion:^(NSError * _Nullable error) {
    //        WeakReturn(target);
    //        if (error) {
    //            //ShowResult(@"Move to position failed: %@", error.description);
    //        }
    //        [target.positionTextField setText: @""];
    //    }];
    //
    //}
    //
    //- (IBAction)showStatusBtnAction:(id)sender {
    //    [self.statusView setHidden:NO];
    //    [self.statusView show];
    //}
    //
    //#pragma mark Save Download Images
    //-(void) savePhotoWithData:(NSData*)data
    //{
    //    if (data) {
    //        NSString *tmpDir =  NSTemporaryDirectory();
    //        NSString *tmpImageFilePath = [tmpDir stringByAppendingPathComponent:@"tmpimage.jpg"];
    //        [data writeToFile:tmpImageFilePath atomically:YES];
    //
    //        NSURL *imageURL = [NSURL URLWithString:tmpImageFilePath];
    //        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
    //            __unused PHAssetChangeRequest *req = [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:imageURL];
    //        } completionHandler:^(BOOL success, NSError * _Nullable error) {
    //            NSLog(@"success = %d, error = %@", success, error);
    //        }];
    //    }
    //}
    //
    //- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
    //{
    //    NSString* message = @"";
    //    if (error != NULL)
    //    {
    //        //Show message when save image failed
    //        message = [NSString stringWithFormat:@"Save Image Failed! Error: %@", error];
    //    }
    //    else
    //    {
    //        //Show message when save image successfully
    //        message = [NSString stringWithFormat:@"Saved to Photo Album"];
    //    }
    //
    //    WeakRef(target);
    //    if (self.statusAlertView == nil) {
    ////        self.statusAlertView = [AlertView showAlertViewWithMessage:message titles:@[@"Dismiss"] action:^(NSUInteger buttonIndex) {
    ////            WeakReturn(target);
    ////            if (buttonIndex == 0) {
    ////                [target dismissStatusAlertView];
    ////            }
    ////        }];
    //    }
    //}
    //
    //#pragma mark - DJIMediaManagerDelegate Method
    //
    //- (void)manager:(DJIMediaManager *)manager didUpdateVideoPlaybackState:(DJIMediaVideoPlaybackState *)state {
    //    NSMutableString *stateStr = [NSMutableString string];
    //    if (state.playingMedia == nil) {
    //        [stateStr appendString:@"No media\n"];
    //    }
    //    else {
    //        [stateStr appendFormat:@"media: %@\n", state.playingMedia.fileName];
    //        [stateStr appendFormat:@"Total: %f\n", state.playingMedia.durationInSeconds];
    //        [stateStr appendFormat:@"Orientation: %@\n", [self orientationToString:state.playingMedia.videoOrientation]];
    //    }
    //    [stateStr appendFormat:@"Status: %@\n", [self statusToString:state.playbackStatus]];
    //    [stateStr appendFormat:@"Position: %f\n", state.playingPosition];
    //
    //    [self.statusView writeWithStatus:stateStr];
    //}
    //
    //-(void)manager:(DJIMediaManager *)manager didUpdateVideoPlaybackData:(uint8_t *)data length:(size_t)length forRendering:(BOOL)forRendering {
    //    [self.renderView decodeH264CompleteFrameData:data
    //                                      length:length
    //                                  decodeOnly:!forRendering];
    //}
    //
    //#pragma mark - Table view data source
    //
    //- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    //    return 1;
    //}
    //
    //- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //
    //    return self.mediaList.count;
    //}
    //
    //- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //
    //    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"mediaFileCell"];
    //    if (cell == nil) {
    //        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"mediaFileCell"];
    //    }
    //
    //    if (self.selectedCellIndexPath == indexPath) {
    //        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    //    }else
    //    {
    //        cell.accessoryType = UITableViewCellAccessoryNone;
    //    }
    //
    //    DJIMediaFile * media = [self.mediaList objectAtIndex:indexPath.row];
    //    cell.textLabel.text = media.fileName;
    //    cell.detailTextLabel.text = [NSString stringWithFormat:@"Create Date: %@ Size: %0.1fMB Duration:%f cusotmInfo:%@", media.timeCreated, media.fileSizeInBytes / 1024.0 / 1024.0,media.durationInSeconds, media.customInformation];
    //    if (media.thumbnail == nil) {
    //        [cell.imageView setImage:[UIImage imageNamed:@"dji.png"]];
    //    }
    //    else
    //    {
    //        [cell.imageView setImage:media.thumbnail];
    //    }
    //
    //    return cell;
    //
    //}
    //
    //- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //
    //    if (self.mediaTableView.isEditing) {
    //        return;
    //    }
    //
    //    self.selectedCellIndexPath = indexPath;
    //
    //    DJIMediaFile *currentMedia = [self.mediaList objectAtIndex:indexPath.row];
    //    if (![currentMedia isEqual:self.selectedMedia]) {
    //        self.previousOffset = 0;
    //        self.selectedMedia = currentMedia;
    //        self.fileData = nil;
    //    }
    //
    //    [tableView reloadData];
    //}
    //
    //-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
    //{
    //    return YES;
    //}
    //
    //-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    //    DJIMediaFile* currentMedia = [self.mediaList objectAtIndex:indexPath.row];
    //    [self.mediaManager deleteFiles:@[currentMedia] withCompletion:^(NSArray<DJIMediaFile *> * _Nonnull failedFiles, NSError * _Nullable error) {
    //        if (error) {
    //            //ShowResult(@"Delete File Failed:%@",error.description);
    //            for (DJIMediaFile * media in failedFiles) {
    //                NSLog(@"%@ delete failed",media.fileName);
    //            }
    //        }else
    //        {
    //            //ShowResult(@"Delete File Successfully");
    //            [self.mediaList removeObjectAtIndex:indexPath.row];
    //            [self.mediaTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
    //        }
    //
    //    }];
    //}
    //
    //@end
}
