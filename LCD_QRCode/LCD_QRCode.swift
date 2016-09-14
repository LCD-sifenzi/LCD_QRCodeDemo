//
//  LCD_QRCode.swift
//  LCD_QRCodeDemo
//
//  Created by 刘才德 on 16/9/13.
//  Copyright © 2016年 sifenzi. All rights reserved.
//

import UIKit
import AVFoundation
import AudioToolbox



class LCD_QRCode: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    class func show(parentVC:UIViewController, block:(strQR:String)->Void) {
        
        if AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo) == .Restricted || AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo) == .Denied {
            let aler = UIAlertController(title: "温馨提示", message: "相机权限受限，请在设置->隐私->相机 中进行设置！", preferredStyle: .Alert)
            let one = UIAlertAction.init(title: "取消", style: .Default, handler: { (UIAlertAction) in
            })
            let two = UIAlertAction.init(title: "设置", style: .Default, handler: { (UIAlertAction) in
                UIApplication.sharedApplication().openURL(NSURL(string: "prefs:root=Privacy")!)
            })
            
            aler.addAction(one)
            aler.addAction(two)
            parentVC.presentViewController(aler, animated: true, completion: nil)
            
        }else{
            let vc = LCD_QRCode(nibName: "LCD_QRCode", bundle: nil)
            vc.LCD_QRCodeBlock = { result in
                block(strQR: result)
            }
            parentVC.presentViewController(vc, animated: true) {
                
            }
        }
        
    }
    
    private var LCD_QRCodeBlock: ((result:String)->Void)?
    private var _captureSession : AVCaptureSession?
    private var _deviceInput : AVCaptureDeviceInput?
    private var _deviceOutPut : AVCaptureMetadataOutput!
    private let _device:AVCaptureDevice? = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo);
    //屏幕宽高
    let qrScreenHeight = UIScreen.mainScreen().bounds.size.height
    let qrScreenWidth = UIScreen.mainScreen().bounds.size.width
    
    @IBOutlet weak var leftViewConstaint_W: NSLayoutConstraint!
    @IBOutlet weak var scanView: UIView!
    @IBOutlet weak var scanLineImage: UIImageView!
    @IBOutlet weak var scanLineConstraint_T: NSLayoutConstraint!
    
    //MARK:----------- 禁止屏幕旋转
    override func shouldAutorotate() -> Bool {
        return false
    }
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return .Portrait
    }
    //MARK:----------- 将状态栏颜色置白，或隐藏
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        scanView.layer.borderColor = UIColor.orangeColor().CGColor
        scanView.layer.borderWidth = 0.5
        
        setDataSource { (isOk) in
            if isOk {
                self.scanStart()
                self.setScanRect()
                self.scanLineAnimate()
            }
            
        }
        
        
    }
    
    //MARK:----------- 创建扫描需要的条件
    private func setDataSource(block:(Bool) -> Void) {
        _captureSession = AVCaptureSession()
        _captureSession?.sessionPreset = AVCaptureSessionPresetHigh
        //输入流
        do {
            _deviceInput = try AVCaptureDeviceInput(device: _device)
        } catch let error as NSError{
            print("错误: \(error.code)")
            block(false)
            return
            
        }
        if _deviceInput != nil {
            _captureSession?.addInput(_deviceInput)
        }
        
        _deviceOutPut = AVCaptureMetadataOutput()

        if _device == nil {
            block(false)
            return
        }
        //参数
        _deviceOutPut.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
        _captureSession?.addOutput(_deviceOutPut)
        
        // 支持二维码和条形码
        _deviceOutPut.metadataObjectTypes = [AVMetadataObjectTypeQRCode,AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code]
        
        //采集质量
        _captureSession?.sessionPreset = AVCaptureSessionPresetHigh
        let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: _captureSession)
        videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        videoPreviewLayer?.frame = CGRectMake(0, 0, qrScreenWidth, qrScreenHeight)
        self.view.layer.insertSublayer(videoPreviewLayer!, atIndex: 0)
        
        //聚焦
        if _device!.focusPointOfInterestSupported && _device!.isFocusModeSupported(AVCaptureFocusMode.ContinuousAutoFocus) {
            do {
                try _deviceInput?.device.lockForConfiguration()
                _deviceInput?.device.focusMode = AVCaptureFocusMode.ContinuousAutoFocus
                _deviceInput?.device.unlockForConfiguration()
            }catch let error as NSError {
                print("错误: \(error)")
                block(false)
                return
            }
        }
        block(true)
        return
    }
    //MARK:----------- 修正扫描区域
    private func setScanRect() {
        let w_h = qrScreenWidth - leftViewConstaint_W.constant*2
        let xx = (qrScreenWidth - w_h) / 2 / qrScreenWidth
        let yy = (qrScreenHeight - w_h) / 2 / qrScreenHeight
        let ww = w_h / qrScreenWidth
        let hh = w_h / qrScreenHeight
        
        _deviceOutPut.rectOfInterest = CGRectMake(yy, xx, hh, ww)
    }
    
    //MARK:----------- 扫描线动画
    private lazy var scanView_HH:CGFloat = 0.0
    //这里用递归函数，必须有一个状态来停止动画，否则即使disimiss，依然还会执行这个递归函数。这样写可能会影响部分性能问题，但是影响不大，这个控制器也不是常开的。当然这个动画还有其他的写法。
    private lazy var _scanViewStop = false
    private func scanLineAnimate() {
        if !_scanViewStop {
            scanView_HH  = scanView_HH > 0 ? 0 : qrScreenWidth - 100 - 2
            scanLineConstraint_T.constant = scanView_HH
            self.scanView.setNeedsLayout()
            UIView.animateWithDuration(1.5, animations: {
                self.scanView.layoutIfNeeded()
            }) { (_) in
                self.scanLineAnimate()
                
            }
        }
        
    }
    //MARK:----------- 开始扫描
    private func scanStart() {
        _captureSession?.startRunning()
    }
    //MARK:----------- 停止扫描
    private func scanStop() {
        _captureSession?.stopRunning()
    }
    
    //MARK:----------- 扫描结果
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        
        if metadataObjects.count > 0 {
            let metadataObject = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
            
            //播放声音/震动
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            
            scanStop()
            _scanViewStop = true
            self.dismissViewControllerAnimated(true, completion: {
                //因为这里是控制器，最好就让控制器disimiss完后再传值,以防止上一级控制器接受二维码信息后跳转冲突
                self.LCD_QRCodeBlock?(result:metadataObject.stringValue)
            })
            
            
        }
    }
    
    //MARK:----------- 关闭
    @IBAction func disimissClick(sender: AnyObject) {
        scanStop()
        _scanViewStop = true
        self.dismissViewControllerAnimated(true, completion: {
        })
    }
    //MARK:----------- 开灯按钮响应事件
    @IBOutlet weak var lightImage: UIImageView!
    @IBOutlet weak var lightLabel: UILabel!
    @IBOutlet weak var lightButton: UIButton!
    @IBAction func lightClick(sender: UIButton) {
        sender.selected = sender.selected ? false : true
        setLightStatus(sender.selected)
        switch sender.selected {
        case false:
            lightImage.image = UIImage(named: "QR_灯关")
            lightLabel.text = "开灯"
        case true:
            lightImage.image = UIImage(named: "QR_灯开")
            lightLabel.text = "关灯"
        }
    }
    private func setLightStatus(turnLight : Bool){
        if _device != nil && _device!.hasTorch {
            do{
                try _deviceInput?.device.lockForConfiguration()
                _deviceInput?.device.torchMode = turnLight ? AVCaptureTorchMode.On : AVCaptureTorchMode.Off
                _deviceInput?.device.unlockForConfiguration()
            }catch let error as NSError {
                print(error)
            }
        }
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
