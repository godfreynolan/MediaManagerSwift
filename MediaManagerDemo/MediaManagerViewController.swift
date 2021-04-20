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
    //@property(nonatomic, strong) NSMutableArray* mediaList;
    var mediaList : [DJIMediaFile]?
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
    var selectedCellIndexPath : IndexPath?
    //@property (nonatomic, strong) DJIRTPlayerRenderView *renderView;
    var renderView : DJIRTPlayerRenderView?

    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.mediaList?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "mediaFileCell", for: indexPath)
        
//        if cell == nil {//TODO: necessary? not an optional type...
//            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"mediaFileCell"];
//        }
        if let selectedCellIndexPath = self.selectedCellIndexPath {
            if selectedCellIndexPath == indexPath {
                cell.accessoryType = UITableViewCell.AccessoryType.checkmark
            } else {
                cell.accessoryType = UITableViewCell.AccessoryType.none
            }
        }
        
        if let media = self.mediaList?[indexPath.row] {
            cell.textLabel?.text = media.fileName;
            cell.detailTextLabel?.text = String(format: "Create Date: %@ Size: %0.1fMB Duration:%f cusotmInfo:%@", media.timeCreated, Double(media.fileSizeInBytes) / 1024.0 / 1024.0,media.durationInSeconds, media.customInformation ?? "none")
            
            if let thumbnail = media.thumbnail {
                cell.imageView?.image = thumbnail
            } else {
                cell.imageView?.image = UIImage.init(named: "dji.png")
            }
        }
        
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
            self.mediaManager?.refreshFileList(of: DJICameraStorageLocation.sdCard, withCompletion: {[weak self] (error:Error?) in
                if let error = error {
                    print("Fetch Media File List Failed: %@", error.localizedDescription)
                } else {
                    print("Fetch Media File List Success.")
                    if let mediaFileList = self?.mediaManager?.sdCardFileListSnapshot() {
                        self?.updateMediaList(mediaList:mediaFileList)
                    }
                }
            })
            
        }
    }
    
    func updateMediaList(mediaList:[DJIMediaFile]) {
        self.mediaList?.removeAll()
        self.mediaList?.append(contentsOf: mediaList)
        
        if let mediaTaskScheduler = DemoUtility.fetchCamera()?.mediaManager?.taskScheduler {
            mediaTaskScheduler.suspendAfterSingleFetchTaskFailure = false
            mediaTaskScheduler.resume(completion: nil)
            self.mediaList?.forEach({ (file:DJIMediaFile) in
                if file.thumbnail == nil {
                    let task = DJIFetchMediaTask(file: file, content: DJIFetchMediaTaskContent.thumbnail) {[weak self] (file: DJIMediaFile, content: DJIFetchMediaTaskContent, error: Error?) in
                        self?.mediaTableView.reloadData()
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
        if (self.statusAlertView == nil) {
            let message = String(format: "Fetch Media Data \n 0.0")
                        
            self.statusAlertView = AlertView.showAlertWith(message: message, titles: ["Cancel"], action: {[weak self] (buttonIndex: Int) -> () in
                if (buttonIndex == 0) {
                    self?.selectedMedia?.stopFetchingFileData(completion: {[weak self] (error: Error?) in
                        self?.statusAlertView = nil
                    })
                }
            })
        }
        if let previousOffset = self.previousOffset {
            self.selectedMedia?.fetchData(withOffset: previousOffset, update: DispatchQueue.main, update: {[weak self] (data:Data?, isComplete: Bool, error:Error?) in
                if let error = error {
                    //TODO: commented in original? why?
                    print("Download Media Failed:%@",error)
                    //[target.statusAlertView updateMessage:[[NSString alloc] initWithFormat:@"Download Media Failed:%@",error]];
                    if let unwrappedSelf = self {
                        unwrappedSelf.perform(#selector(unwrappedSelf.dismissStatusAlertView), with: nil, afterDelay: 2.0)
                    }
                } else {
                    if isPhoto {
                        if let data = data {
                            if self?.fileData == nil {
                                self?.fileData = data//TODO: mutable copy?
                                //                    target.fileData = [data mutableCopy];
                            } else {
                                self?.fileData?.append(data)//Again, mutable copy necessary?
                            }
                            self?.previousOffset = self?.previousOffset ?? 0 + UInt(data.count)
                        }
                    }
                    if let selectedFileSizeBytes = self?.selectedMedia?.fileSizeInBytes {
                        let progress = Float(self?.previousOffset ?? 0) * 100.0 / Float(selectedFileSizeBytes)
                        self?.statusAlertView?.update(message: String(format: "Downloading: %0.1f%%", progress) as NSString)
                        if isComplete {
                            self?.dismissStatusAlertView()
                            if (isPhoto) {
                                self?.showPhotoWithData(data: self?.fileData)
                                self?.showPhotoWithData(data: self?.fileData)
                            }
                        }
                    }
                }
            })
        }
    }
    
    //From downloadBtnAction...

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
    
    @IBAction func playBtnAction(_ sender: Any) {
        self.displayImageView.isHidden = true
        self.renderView?.isHidden = false
        
        if let mediaType = self.selectedMedia?.mediaType {
            if (mediaType == DJIMediaType.MOV || mediaType == DJIMediaType.MP4) {
                if let selectedMedia = self.selectedMedia {
                    self.positionTextField.placeholder = String(format: "%d sec", Int(selectedMedia.durationInSeconds))
                    self.mediaManager?.playVideo(selectedMedia, withCompletion: { (error:Error?) in
                        if let error = error {
                            DemoUtility.show(result: String(format:"Play Video Failed: %@", error.localizedDescription) as NSString)//TODO: use String, convert DemoUtility function to swift
                        }
                    })
                }
            }
        }
    }
    
    @IBAction func resumeBtnAction(_ sender: Any) {
        self.mediaManager?.resume(completion: { (error:Error?) in
            if let error = error {
                DemoUtility.show(result: String(format: "Resume failed: %@", error.localizedDescription) as NSString)
            }
        })
    }
    
    @IBAction func pauseBtnAction(_ sender: Any) {
        self.mediaManager?.pause(completion: { (error:Error?) in
            if let error = error {
                DemoUtility.show(result: String(format: "Pause failed: %@", error.localizedDescription) as NSString)
            }
        })
    }
    
    @IBAction func stopBtnAction(_ sender: Any) {
        self.mediaManager?.stop(completion: { (error: Error?) in
            if let error = error {
                DemoUtility.show(result: String(format:"Stop failed: %@", error.localizedDescription) as NSString)
            }
        })
    }
    
    
    //TODO: where's this action coming from? DJIScrollView.nib?
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
    
    @IBAction func showStatusBtnAction(_ sender: Any) {
        self.statusView?.isHidden = false
        self.statusView?.show()
    }

    //MARK - Save Download Images
    
    func savePhotoWithData(data:NSData?) {
        if let data = data {
            let tmpDir = NSTemporaryDirectory() as NSString //TODO: how to do this with String?
            let tmpImageFilePath = tmpDir.appendingPathComponent("tmpimage.jpg")
            data.write(toFile: tmpImageFilePath, atomically: true)
            
            guard let imageURL = URL(string: tmpImageFilePath) else {
                print("Failed to load a filepath to save to")
                return
            }
            PHPhotoLibrary.shared().performChanges {
                //__unused PHAssetChangeRequest *req = [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:imageURL];
                _ = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: imageURL)
            } completionHandler: { (success:Bool, error: Error?) in
                print("success = %d, error = %@", success, error?.localizedDescription ?? "no")
            }
        }
    }
    
    func imageDidFinishSaving(error:NSError?, contextInfo:Any) {// void* = Any? Data?
        var message = ""
        if let error = error {
            //Show message when save image failed
            message = String(format:"Save Image Failed! Error: %@", error.description);
        } else {
            //Show message when save image successfully
            message = "Saved to Photo Album";
        }

        if self.statusAlertView == nil {
            self.statusAlertView = AlertView.showAlertWith(message:message, titles:["Dismiss"], action: {[weak self] (buttonIndex:Int) in
                if buttonIndex == 0 {
                    self?.dismissStatusAlertView()
                }
            })
        }
    }

    //MARK - DJIMediaManagerDelegate Method
    
    func manager(_ manager: DJIMediaManager, didUpdate state: DJIMediaVideoPlaybackState) {
        var stateString = ""
        if state.playingMedia == nil {//TODO: should state be an optional?
            stateString.append("No media \n")
        } else {
            stateString.append(String(format:"media: %@\n", state.playingMedia.fileName))
            stateString.append(String(format:"Total: %f\n", state.playingMedia.durationInSeconds))
            stateString.append(String(format:"Orientation: %@\n", self.orientationToString(orientation: state.playingMedia.videoOrientation) ?? "nil"))
        }
        stateString.append(String(format:"Status: %@\n", self.statusToString(status:state.playbackStatus) ?? "nil"))
        stateString.append(String(format:"Position: %f\n", state.playingPosition))
    
        self.statusView?.write(status: stateString as NSString)//TODO: use String
    }
    
    func manager(_ manager: DJIMediaManager, didUpdateVideoPlaybackData data: UnsafeMutablePointer<UInt8>, length: Int, forRendering: Bool) {
        //    [self.renderView decodeH264CompleteFrameData:data
        //                                      length:length
        //                                  decodeOnly:!forRendering];
        self.renderView?.decodeH264RawData(data, length: UInt(length))
    }

    //MARK - Table view data source
    //
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
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
