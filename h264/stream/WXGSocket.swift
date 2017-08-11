//
//  WXGSocket.swift
//  WuXiaGPS
//
//  Created by asdasd on 2017/8/9.
//  Copyright © 2017年 WuXia. All rights reserved.
//

import UIKit

class WXGSocket: NSObject {

    let ip:String
    let port:UInt16
    
    
    fileprivate(set) var input:InputStream?
    fileprivate(set) var output:OutputStream?
    
    init(ip:String,port:UInt16) {
        self.ip = ip
        self.port = port
        super.init()
    }
    
    /// 找开流
    func open() {
        Stream.getStreamsToHost(withName: ip, port: Int(port), inputStream: &input, outputStream: &output)
        input?.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
        output?.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
        input?.delegate = self
        output?.delegate = self
        
        input?.open()
        output?.open()
    }
    
    /// 关闭流
    func close() {
        input?.close()
        output?.close()
    }
}
//MARK: - StreamDelegate
extension WXGSocket:StreamDelegate {
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case Stream.Event.openCompleted:
            openCompleted(aStream)
        case Stream.Event.endEncountered:
            endEncountered(aStream)
        case Stream.Event.errorOccurred:
            errorOccurred(aStream)
        case Stream.Event.hasBytesAvailable:
            hasBytesAvailable(aStream)
        case Stream.Event.hasSpaceAvailable:
            hasSpaceAvailable(aStream)
        default:
            print("other eventCode : \(eventCode)")
        }
    }
    
    func openCompleted(_ stream:Stream){
        
    }
    func endEncountered(_ stream:Stream){
        
    }
    func errorOccurred(_ stream:Stream){
        
    }
    func hasBytesAvailable(_ stream:Stream){
        
    }
    func hasSpaceAvailable(_ stream:Stream){
        
    }
}
