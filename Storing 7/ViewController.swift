//
//  ViewController.swift
//  Storing 7
//
//  Created by Massimo Milan on 15/07/15.
//  Copyright © 2015 Massimo Milan. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    @IBOutlet weak var label: UILabel!
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var qrCodeFrameView:UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        var captureSession:AVCaptureSession?

        
        let captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)

        let input: AnyObject! = try! AVCaptureDeviceInput.init(device: captureDevice) as AVCaptureDeviceInput
        
        captureSession = AVCaptureSession()
        captureSession?.addInput(input as! AVCaptureInput)
        
        let captureMetadataOutput = AVCaptureMetadataOutput()
        captureSession?.addOutput(captureMetadataOutput)
        
        captureMetadataOutput.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
        captureMetadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]


        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        videoPreviewLayer?.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer!)

        captureSession?.startRunning()
        
        view.bringSubviewToFront(label)
        
        qrCodeFrameView = UIView()
        qrCodeFrameView?.layer.borderColor = UIColor.greenColor().CGColor
        qrCodeFrameView?.layer.borderWidth = 2
        view.addSubview(qrCodeFrameView!)
        view.bringSubviewToFront(qrCodeFrameView!)


        let installationId = NSUserDefaults.standardUserDefaults().stringForKey("installationId")
        if let id = installationId {
            label.text = id
        }
        else {
            let url = NSURL(string: "https://authid.asp.lifeware.ch/v0App/newInstallation?deviceName=iphone6")
            let task = NSURLSession.sharedSession().dataTaskWithURL(url!) {(data, response, error) in
                let id = NSString(data: data!, encoding: NSUTF8StringEncoding)
                NSUserDefaults.standardUserDefaults().setObject(id, forKey: "installationId")
                NSUserDefaults.standardUserDefaults().synchronize()
                self.label.text = id as? String
            }
            
            task!.resume()
        }
        
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        if metadataObjects == nil || metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRectZero
            return
        }
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        if metadataObj.type == AVMetadataObjectTypeQRCode {
            let barCodeObject = videoPreviewLayer?.transformedMetadataObjectForMetadataObject(metadataObj as AVMetadataMachineReadableCodeObject) as!AVMetadataMachineReadableCodeObject
            qrCodeFrameView?.frame = barCodeObject.bounds;
            if metadataObj.stringValue != nil {
                label.text = metadataObj.stringValue
            }
        }
    }
    
    func mapOriention(orientation: UIInterfaceOrientation) -> AVCaptureVideoOrientation {
        switch (orientation) {
            case .Portrait: return .Portrait;
            case .PortraitUpsideDown: return .PortraitUpsideDown;
            case .LandscapeLeft: return .LandscapeLeft;
            case .LandscapeRight: return .LandscapeRight;
            default: return .Portrait;
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        videoPreviewLayer!.connection.videoOrientation = self.mapOriention(UIApplication.sharedApplication().statusBarOrientation)
        videoPreviewLayer?.frame = view.layer.bounds
    }
    
    @IBAction func tapped(sender: UITapGestureRecognizer) {
        let label = sender.view as! UILabel
        let token = NSURL(string: label.text!)?.lastPathComponent
        let installationId = NSUserDefaults.standardUserDefaults().stringForKey("installationId")

        let request = "https://authid.asp.lifeware.ch/v0App/authenticateBarcode?barcodeToken=\(token!)&installationId=\(installationId!)"
        let url = NSURL(string: request)
        
        
        let task = NSURLSession.sharedSession().dataTaskWithURL(url!) {(data, response, error) in
            let response = NSString(data: data!, encoding: NSUTF8StringEncoding)
            print("response \(response)")
        }
        
        task!.resume()

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func longpress(sender: UILongPressGestureRecognizer) {
        NSUserDefaults.standardUserDefaults().removeObjectForKey("installationId")
        print("long press")
    }

}

