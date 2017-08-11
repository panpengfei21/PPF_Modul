//
//  WXGAudiovisualSocket.swift
//  WuXiaGPS
//
//  Created by asdasd on 2017/8/9.
//  Copyright © 2017年 WuXia. All rights reserved.
//

import UIKit

protocol WXGAudiovisualSocketDelegate:class {
    func audiovisualSocket(socket:WXGAudiovisualSocket,h264:WXGH264)
}

class WXGAudiovisualSocket: WXGSocket {
    /// 车辆ID
    let carID:UInt32
    /// 用户ID
    let userID:UInt32
    /// 通道号
    let channelID:UInt8
    
    /// 请求数据的拼接
    fileprivate var request:VTeNetDataRequest!
    /// h264的分析模块
    fileprivate var response:WXGH264Parser!
    /// 心跳机制
    fileprivate var heartBeat:Heartbeat?
    
    /// 写入的串行队列
    fileprivate var writeQueue:DispatchQueue?
    /// 读取的串行队列
    fileprivate var readQueue:DispatchQueue?
    /// 是否是第一次登录操作
    fileprivate var isLoginOperationFirst = true
    /// 代理
    weak var delegate:WXGAudiovisualSocketDelegate?
    /// input是否已经打开,观察这个可以得到打开的通知
    dynamic var isInputOpen = false
    /// ouput是否已经打开,观察这个可以得到打开的通知
    dynamic var isOutputOpen = false
    /// 最新的错误信息
    dynamic var errorStr:String?
    
    
    init(ip: String, port: UInt16,carID:UInt32,userID:UInt32,channelID:UInt8) {
        self.carID = carID
        self.userID = userID
        self.channelID = channelID
        super.init(ip: ip, port: port)
    }
    
    convenience init(address:StreamAddress) {
        self.init(ip: address.ip, port: address.port, carID: address.carID, userID: address.userID, channelID: address.channelID)
    }
    
    /// 打开
    override func open() {
        super.open()
        response = WXGH264Parser()
        request = VTeNetDataRequest()
        writeQueue = DispatchQueue(label: "wuxia.video.writeQueue")
        readQueue = DispatchQueue(label: "wuxia.video.readQueue")
        p_startHearBeat()
    }
    /// 关闭
    override func close() {
        super.close()
    }
    
    /// 开始发送心跳
    private func p_startHearBeat() {
        heartBeat = Heartbeat()
        heartBeat?.startTimer(block: {[weak self] in
            self?.p_sendHeartBeat()
            self?.heartBeat?.restoreBeat()
        }, beatEnd: nil)
    }
}

// MARK: - write
extension WXGAudiovisualSocket {
    /// 发送心跳包
    fileprivate func p_sendHeartBeat() {
        guard let output = output,output.hasSpaceAvailable else{
            return
        }
        let data = self.request.heartbeatData()
        writeQueue?.async {
            output.write(Array(data), maxLength: data.count)
        }
    }
    
    /// 发送登录视频服务器的命令
    fileprivate func p_sendLogin() {
        guard isLoginOperationFirst else{
            return
        }
        guard let output = output,output.hasSpaceAvailable else{
            return
        }
        isLoginOperationFirst = false
        let data = self.request.loginAudiovisual(carID: self.carID, userID: self.userID, channelID: self.channelID)
        writeQueue?.async {
            output.write(Array(data), maxLength: data.count)
        }
    }
}

//MARK: - streamDelegate
extension WXGAudiovisualSocket {
    override func hasBytesAvailable(_ stream: Stream) {
        guard let input = stream as? InputStream else{
            fatalError()
        }
        var dataArray = Array<UInt8>(repeating: 0, count: 1024 * 1024)
        let dataLength = input.read(&dataArray, maxLength: dataArray.count)
        guard dataLength > 0 else{
            return
        }
        let data = Data(bytes: &dataArray, count: dataLength)
        
        response.append1(otherData: data) { (h264s:[WXGH264]) in
            DispatchQueue.main.async {
                for h264 in h264s {
                    self.delegate?.audiovisualSocket(socket: self, h264: h264)
                }
            }
        }
    }
    
    override func openCompleted(_ stream: Stream) {
        if stream is InputStream {
            isInputOpen = true
        } else if stream is OutputStream {
            isOutputOpen = true
        }
    }
    
    override func errorOccurred(_ stream: Stream) {
        errorStr = stream.streamError?.localizedDescription
    }
    
    override func hasSpaceAvailable(_ stream: Stream) {
        p_sendLogin()
    }
}
