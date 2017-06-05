//
//  ViewController.swift
//  videoRecording
//
//  Created by ev_mac18 on 31/05/17.
//  Copyright © 2017 ev_mac18. All rights reserved.
//

import UIKit
import AVFoundation
class ViewController: UIViewController,AVCaptureMetadataOutputObjectsDelegate, AVCaptureFileOutputRecordingDelegate {
    @IBOutlet weak var myView: UIView!

    @IBOutlet var durationTxt: UILabel!
    
    @IBOutlet var playBtn: UIButton!
    @IBOutlet var playerView: UIView!
    let captureSession = AVCaptureSession()
    
    let movieOutput = AVCaptureMovieFileOutput()
    
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    var activeInput: AVCaptureDeviceInput!
    
    var outputURL: URL!
    let avPlayer = AVPlayer()
    var avPlayerLayer: AVPlayerLayer!
    var url = NSURL()
    var seconds: Int!
    var durationTimer: Timer?
    /*var session: AVCaptureSession?
    var device: AVCaptureDevice?
    var input: AVCaptureDeviceInput?
    var output: AVCaptureMetadataOutput?
    var prevLayer: AVCaptureVideoPreviewLayer?
    var movieOutput = AVCaptureMovieFileOutput()
    let fileOutput = AVCaptureMovieFileOutput()
    var documentsPathurl = NSString()
    var outputPath = ""
    var outputURL = NSURL()*/
    // captureSession.addOutput(videoCaptureOutput)
    // documentsPathurl = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
    //let outputPath = "\(documentsPathurl)/output.mp4"
    //let outputFileUrl = NSURL(fileURLWithPath: outputPath)
    
    //var tmpdir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
    //var outputPath = NSString(format: "%@/output.mp4",tmpdir)//String(format: "%@/output.mp4",tmpdir)//"\(tmpdir)output.mp4"
    //var outputURL = NSURL(fileURLWithPath:outputPath as String)!
    //var captureSession = AVCaptureSession()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if setupSession() {
            setupPreview()
            startSession()
        }
        
        // Do any additional setup after loading the view, typically from a nib.
        
//        let videoCameraView = FSVideoCameraView.instance()
//        videoCameraView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
//        self.view.addSubview(videoCameraView)
        //createSession()//
    }
    
    func setupPreview() {
        // Configure previewLayer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = myView.bounds
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        myView.layer.addSublayer(previewLayer)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playBtn.setTitle("start", for: .normal)
        //prevLayer?.frame.size = myView.frame.size//
    }
    
    //MARK:- Setup Camera
    
    func setupSession() -> Bool {
        
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        //captureSession.startse
        // Setup Camera
        let camera = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                activeInput = input
            }
        } catch {
            print("Error setting device video input: \(error)")
            return false
        }
        
        // Setup Microphone
        let microphone = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
        
        do {
            let micInput = try AVCaptureDeviceInput(device: microphone)
            if captureSession.canAddInput(micInput) {
                captureSession.addInput(micInput)//addInput(micInput)
            }
        } catch {
            print("Error setting device audio input: \(error)")
            return false
        }
        movieOutput.maxRecordedDuration = CMTimeMake(9, 1)
        
        // Movie output
        if captureSession.canAddOutput(movieOutput) {
            captureSession.addOutput(movieOutput)
        }
        
        return true
    }
    
    func setupCaptureMode(_ mode: Int) {
        // Video Mode
        
    }
    
    //MARK:- Camera Session
    func startSession() {
        
        
        if !captureSession.isRunning {
            videoQueue().async {
                self.captureSession.startRunning()
            }
        }
    }
    
    func stopSession() {
        if captureSession.isRunning {
            videoQueue().async {
                self.captureSession.stopRunning()
            }
        }
    }
    
    func videoQueue() -> DispatchQueue {
        return DispatchQueue.main
    }
    
    
    
    func currentVideoOrientation() -> AVCaptureVideoOrientation {
        var orientation: AVCaptureVideoOrientation
        
        switch UIDevice.current.orientation {
        case .portrait:
            orientation = AVCaptureVideoOrientation.portrait
        case .landscapeRight:
            orientation = AVCaptureVideoOrientation.landscapeLeft
        case .portraitUpsideDown:
            orientation = AVCaptureVideoOrientation.portraitUpsideDown
        default:
            orientation = AVCaptureVideoOrientation.landscapeRight
        }
        
        return orientation
    }
    
    func startCapture() {
        
        startRecording()
        
    }
    
    //EDIT 1: I FORGOT THIS AT FIRST
    
    func tempURL() -> URL? {
        let directory = NSTemporaryDirectory() as NSString
        
        if directory != "" {
            let path = directory.appendingPathComponent(NSUUID().uuidString + ".mp4")
            return URL(fileURLWithPath: path)
        }
        
        return nil
    }
    
    
    func startRecording() {
        
        if movieOutput.isRecording == false {
        playBtn.setTitle("stop", for: .normal)
            let connection = movieOutput.connection(withMediaType: AVMediaTypeVideo)
            if (connection?.isVideoOrientationSupported)! {
                connection?.videoOrientation = currentVideoOrientation()
            }
            
            if (connection?.isVideoStabilizationSupported)! {
                connection?.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.auto
            }
            
            let device = activeInput.device
            if (device?.isSmoothAutoFocusSupported)! {
                do {
                    try device?.lockForConfiguration()
                    device?.isSmoothAutoFocusEnabled = false
                    device?.unlockForConfiguration()
                } catch {
                    print("Error setting configuration: \(error)")
                }
                
            }
            
            //EDIT2: And I forgot this
            outputURL = tempURL()
            movieOutput.startRecording(toOutputFileURL: outputURL, recordingDelegate: self)
            
            self.seconds = 10
            self.durationTimer = Timer(timeInterval: 1.0, target: self, selector: #selector(self.refreshDurationLabel), userInfo: nil, repeats: true)
            RunLoop.current.add(self.durationTimer!, forMode: RunLoopMode.commonModes)
            self.durationTimer?.fire()
            
        }
        else {
            playBtn.setTitle("start", for: .normal)
            self.durationTimer?.invalidate()
            self.durationTimer = nil
            self.seconds = 0
            self.durationTxt.text = secondsToFormatTimeFull(second: 0)
            stopRecording()
        }
    
    }
    
    func stopRecording() {
        
        if movieOutput.isRecording == true {
            movieOutput.stopRecording()
        }
    }
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
        
    }
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        if (error != nil) {
            print("Error recording movie: \(error!.localizedDescription)")
        } else {
            
            _ = outputURL as URL
            
        }
        outputURL = nil
        let pathString = outputFileURL.relativePath
        
        url = NSURL.fileURL(withPath: pathString) as NSURL
        print(url)
        self.durationTimer?.invalidate()
        self.durationTimer = nil
        self.seconds = 0
        self.durationTxt.text = secondsToFormatTimeFull(second: 0)
        playBtn.setTitle("start", for: .normal)
    }

    
    @IBAction func playStopAction(_ sender: Any) {
        startRecording()
    }


    @IBAction func closeAction(_ sender: Any) {
    }
    
    @IBAction func stopAction(_ sender: Any) {
        //stopRecording()
        if movieOutput.isRecording == true
        {
            self.durationTimer?.invalidate()
            self.durationTimer = nil
            self.seconds = 0
            self.durationTxt.text = secondsToFormatTimeFull(second: 0)
            stopRecording()
        }
    }
    
    @IBAction func play(_ sender: Any) {
        avPlayerLayer = AVPlayerLayer(player: avPlayer)
        avPlayerLayer.frame = playerView.bounds
        avPlayerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        playerView.layer.insertSublayer(avPlayerLayer, at: 0)
        
        view.layoutIfNeeded()
        
        let playerItem = AVPlayerItem(url: url as URL)
        avPlayer.replaceCurrentItem(with: playerItem)
        
        
        avPlayer.play()
        
    }
    
    func refreshDurationLabel() {
        
        self.durationTxt.text = secondsToFormatTimeFull(second: Double(self.seconds))
        seconds = seconds - 1
    }
    
    func secondsToFormatTimeFull(second: Double)->String
    {
        return "00:\(second)"
    }
    
    
    func changeCameraButtonClick(sender: AnyObject) {

        playBtn.setTitle("start", for: .normal)
        self.durationTimer?.invalidate()
        self.durationTimer = nil
        self.seconds = 0
        self.durationTxt.text = secondsToFormatTimeFull(second: 0)
        stopRecording()
        
        let currentCameraInput: AVCaptureInput = captureSession.inputs[0] as! AVCaptureInput
        captureSession.removeInput(currentCameraInput)
        var newCamera: AVCaptureDevice
        if (currentCameraInput as! AVCaptureDeviceInput).device.position == .back {
            newCamera = self.cameraWithPosition(position: .front)!
        } else {
            newCamera = self.cameraWithPosition(position: .back)!
        }
        do{
            let newVideoInput = try AVCaptureDeviceInput(device: newCamera)//AVCaptureDeviceInput(device: newCamera, error: nil)
            captureSession.addInput(newVideoInput)
        }
        catch {
            print(error)
        }
    }
    
    func cameraWithPosition(position: AVCaptureDevicePosition) -> AVCaptureDevice? {
        //let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo)
        if #available(iOS 10.0, *) {
            
            return AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera,
                                                 mediaType: AVMediaTypeVideo,
                                                 position: position)
        } else {
            // Fallback on earlier versions
            let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo)
            for device in devices! {
                if (device as AnyObject).position == position {
                    return device as? AVCaptureDevice
                }
            }
        }
        
        return nil
    }
    
    
    @IBAction func cameraToogleAction(_ sender: Any) {
        playBtn.setTitle("start", for: .normal)
        self.durationTimer?.invalidate()
        self.durationTimer = nil
        self.seconds = 0
        self.durationTxt.text = secondsToFormatTimeFull(second: 0)
        stopRecording()
        
        let currentCameraInput: AVCaptureInput = captureSession.inputs[0] as! AVCaptureInput
        captureSession.removeInput(currentCameraInput)
        var newCamera: AVCaptureDevice
        if (currentCameraInput as! AVCaptureDeviceInput).device.position == .back {
            newCamera = self.cameraWithPosition(position: .front)!
        } else {
            newCamera = self.cameraWithPosition(position: .back)!
        }
        do{
            let newVideoInput = try AVCaptureDeviceInput(device: newCamera)//AVCaptureDeviceInput(device: newCamera, error: nil)
            captureSession.removeInput(activeInput)
            captureSession.addInput(newVideoInput)
            activeInput = newVideoInput
        }
        catch {
            print(error)
        }
    }
//    class func deviceWithMediaType(mediaType: String, preferringPosition position: AVCaptureDevicePosition) -> AVCaptureDevice {
//        let devices = AVCaptureDevice.devices//devices(withMediaType: mediaType) as![AVCaptureDevice?]
//        var captureDevice = devices.first
//        for device in devices {
//            if device?.position == position {
//                captureDevice = device
//                break
//            }
//        }
//        return captureDevice!!
//    }
    
    /*func createSession() {
     session = AVCaptureSession()
     device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
     let error: NSError? = nil
     do{
     input = try AVCaptureDeviceInput(device: device)//AVCaptureDeviceInput(device: device, error: &error)
     if error == nil {
     session?.addInput(input)
     } else {
     NSLog("camera input error: \(error)")
     }
     
     prevLayer = AVCaptureVideoPreviewLayer(session: session)
     prevLayer?.frame.size = myView.frame.size
     prevLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
     
     prevLayer?.connection.videoOrientation = transformOrientation(orientation: UIInterfaceOrientation(rawValue: UIApplication.shared.statusBarOrientation.rawValue)!)
     
     myView.layer.addSublayer(prevLayer!)
     // add output movieFileOutput
     movieOutput.movieFragmentInterval = kCMTimeInvalid
     session?.addOutput(movieOutput)
     
     // start session
     session?.commitConfiguration()
     
     session?.startRunning()
     }
     catch {
     print(error)
     }
     }
     
     func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
     print("touch")
     // start capture
     //movieOutput.startRecordingToOutputFileURL(outputFileUrl, recordingDelegate: self)
     
     }
     
     func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
     print("release")
     //stop capture
     movieOutput.stopRecording()
     }
     
     func cameraWithPosition(position: AVCaptureDevicePosition) -> AVCaptureDevice? {
     //let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo)
     if #available(iOS 10.2, *) {
     
     return AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera,
     mediaType: AVMediaTypeVideo,
     position: position)
     } else {
     // Fallback on earlier versions
     let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo)
     for device in devices! {
     if (device as AnyObject).position == position {
     return device as? AVCaptureDevice
     }
     }
     }
     
     return nil
     }
     
     func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
     coordinator.animate(alongsideTransition: { (context) -> Void in
     self.prevLayer?.connection.videoOrientation = self.transformOrientation(orientation: UIInterfaceOrientation(rawValue: UIApplication.shared.statusBarOrientation.rawValue)!)
     self.prevLayer?.frame.size = self.myView.frame.size
     }, completion: { (context) -> Void in
     
     })
     //super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
     super.viewWillTransition(to: size, with: coordinator)
     }
     
     func transformOrientation(orientation: UIInterfaceOrientation) -> AVCaptureVideoOrientation {
     switch orientation {
     case .landscapeLeft:
     return .landscapeLeft
     case .landscapeRight:
     return .landscapeRight
     case .portraitUpsideDown:
     return .portraitUpsideDown
     default:
     return .portrait
     }
     }
     
     @IBAction func switchCameraSide(sender: AnyObject) {
     if let sess = session {
     let currentCameraInput: AVCaptureInput = sess.inputs[0] as! AVCaptureInput
     sess.removeInput(currentCameraInput)
     var newCamera: AVCaptureDevice
     if (currentCameraInput as! AVCaptureDeviceInput).device.position == .back {
     newCamera = self.cameraWithPosition(position: .front)!
     } else {
     newCamera = self.cameraWithPosition(position: .back)!
     }
     do{
     let newVideoInput = try AVCaptureDeviceInput(device: newCamera)//AVCaptureDeviceInput(device: newCamera, error: nil)
     session?.addInput(newVideoInput)
     }
     catch {
     print(error)
     }
     
     }
     }
     
     @IBAction func click(_ sender: Any) {
     if let sess = session {
     let currentCameraInput: AVCaptureInput = sess.inputs[0] as! AVCaptureInput
     sess.removeInput(currentCameraInput)
     var newCamera: AVCaptureDevice
     if (currentCameraInput as! AVCaptureDeviceInput).device.position == .back {
     newCamera = self.cameraWithPosition(position: .front)!
     } else {
     newCamera = self.cameraWithPosition(position: .back)!
     }
     do{
     let newVideoInput = try AVCaptureDeviceInput(device: newCamera)//AVCaptureDeviceInput(device: newCamera, error: nil)
     session?.addInput(newVideoInput)
     }
     catch {
     print(error)
     }
     
     }
     }
     override func didReceiveMemoryWarning() {
     super.didReceiveMemoryWarning()
     // Dispose of any resources that can be recreated.
     }
     
     func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
     print(outputFileURL)
     let pathString = outputFileURL.relativePath
     
     let url = NSURL.fileURL(withPath: pathString)
     print(url)
     stopRecording()
     }
     
     func startRecording() {
     
     ///stuff you'd do to start the recording including deleting
     ///your temp file if it exists from the last recording session
     ////SET OUTPUT URL AND PATH. DELETE ANY FILE THAT EXISTS THERE
     let tmpdir = NSTemporaryDirectory()
     outputPath = "\(tmpdir)output.mov"
     outputURL = NSURL(fileURLWithPath:outputPath as String)
     let filemgr = FileManager.default
     if filemgr.fileExists(atPath: outputPath) {
     //filemgr.removeItemAtPath(outputPath, error: nil)
     do{
     try filemgr.removeItem(atPath: outputPath)
     }
     catch
     {
     print(error)
     }
     }
     movieOutput.startRecording(toOutputFileURL: outputURL as URL!, recordingDelegate: self)
     }
     
     func stopRecording()
     {
     movieOutput.stopRecording()
     }*/
}

