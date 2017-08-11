//
//  AudiovisualViewController.swift
//  WuXiaGPS
//
//  Created by asdasd on 2017/8/8.
//  Copyright © 2017年 WuXia. All rights reserved.
//

import UIKit

class AudiovisualViewController: UIViewController {

    var car:Car_M!
    var socket:WXGSocket?
    var address:StreamAddress?
    var streamStatus:StreamStatus?
    
    var h264Decoder:H264HwDecoderImpl?
    
    var playLayer:AAPLEAGLLayer!
    
    @IBOutlet weak var openAVStream: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        playLayer = AAPLEAGLLayer(frame: CGRect(x: 0, y: 200, width: 300, height: 200))
        playLayer.backgroundColor = UIColor.black.cgColor
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        openAVStream.isEnabled = false
        NotificationCenter.default.addObserver(self, selector: #selector(AudiovisualViewController.notificationForAudiovisualAddress(notification:)), name: NSNotification.Name.audiovisualAddress, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AudiovisualViewController.notificationForAudiovisualStatus(notification:)), name: NSNotification.Name.audiovisualStreamStatusResponse, object: nil)
    }
    
    
    deinit {
        print(#function)
        NotificationCenter.default.removeObserver(self)
        socket?.close()
        NetWorking.share.disconnect()
    }
    

    @IBAction func tapForAVIP(_ sender: UIButton) {
        print(#function)
        NetWorking.share.set(ip: loginPlatform!.ip!, port: UInt16(loginPlatform!.port!)!)
        NetWorking.share.fetchAudiovisualIP(token: user!.token!, carID: UInt32(car.carID), channelID: 0, streamType: .low)
    }

    @IBAction func tapForAVStream(_ sender: UIButton) {
        print(#function)
        guard let address = address else {
            return
        }
        switch address.type {
        case .success:
            self.socket = WXGAudiovisualSocket(address: address)
            (self.socket as! WXGAudiovisualSocket).delegate = self
            self.socket?.open()
        case .failure:
            print("open av stream is failure -- PPF")
        }
        
        if h264Decoder == nil {
            h264Decoder = H264HwDecoderImpl()
            h264Decoder?.delegate = self
        }
        p_startPlay()
        
    }
    
    
    func notificationForAudiovisualAddress(notification:Notification){
        guard let address = notification.userInfo?[audiovisualAddressNotificationKey] as? StreamAddress else{
            fatalError()
        }
        self.address = address
        DispatchQueue.main.async {
            self.openAVStream.isEnabled = true;
        }
    }
    
    func notificationForAudiovisualStatus(notification:Notification){
        print(#function)
        guard let status = notification.userInfo?[audiovisualStreamStatusNotificationKey] as? StreamStatus else{
            fatalError()
        }
        streamStatus = status
        print(status.status)
    }
    
    
    func p_startPlay() {
        self.view.layer.addSublayer(playLayer)
    }
    
    fileprivate func p_stopPlay() {
        playLayer.removeFromSuperlayer()
    }
}

extension AudiovisualViewController:WXGAudiovisualSocketDelegate{
    func audiovisualSocket(socket: WXGAudiovisualSocket, h264: WXGH264) {
        //这里的h264的头已经处理掉了,h264Decoder的
        var array = Array<UInt8>(repeating: 0, count: h264.length + 4)
        array[3] = 0x01
        let pointer = UnsafeMutablePointer(mutating: array)
        h264.data.copyBytes(to: pointer + 4, count: h264.length)
        h264Decoder?.decodeNalu(pointer, withSize: UInt32(h264.length) + 4)
    }
}

extension AudiovisualViewController:H264HwDecoderImplDelegate {
    func displayDecodedFrame(_ imageBuffer: CVImageBuffer!) {
        guard let buffer = imageBuffer else{
            return
        }
        playLayer?.pixelBuffer = buffer
    }
}
