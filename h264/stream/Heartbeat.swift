//
//  Heartbeat.swift
//  WuXiaGPS
//
//  Created by asdasd on 2017/5/17.
//  Copyright © 2017年 WuXia. All rights reserved.
//

import UIKit

class Heartbeat: NSObject {
    
    /// 心跳终止点,超过这个数值就说明心跳停止
    let beatEndNum = 3
    
//    static let share = Heartbeat()
    
    private weak var timer:Timer?
    let timerQueue = DispatchQueue.global()
    
    /// 是否活着
    var isLive:Bool{
        get{
            return beat < beatEndNum
        }
    }
    
    /// 用来循环的方法
    var block:(() -> ())?
    /// 当到达临界点时,执行的方法
    var beatEnd:(() -> ())?
    
    private var beat = 999
    
    
    /// 开始时间
    ///
    /// - Parameter block: 发送心跳
    func startTimer(block:@escaping ()->(),beatEnd:(() -> ())?){
        guard timer == nil else {
            return
        }
        objc_sync_enter(self)
        if timer == nil{
            self.block = block
            self.beatEnd = beatEnd
            self.beat = 0
            
            timerQueue.async {[weak self] in
                guard let s = self else{
                    return
                }
                s.timer = Timer.scheduledTimer(timeInterval: 30, target: s, selector: #selector(Heartbeat.sendHeartBeat(timer:)), userInfo: nil, repeats: true)
                RunLoop.current.add(s.timer!, forMode: RunLoopMode.commonModes)
                RunLoop.current.run()
                s.timer?.fire()
            }
        }
        objc_sync_exit(self)
    }
    
    
    /// 停止时间
    func stopTimer(){
        setBeat(num: 999)
        guard let timer = timer,timer.isValid else{
            return
        }
        timer.invalidate()
    }
    
    
    func sendHeartBeat(timer:Timer){
        setBeat(num: beat + 1)
        if isLive {
            block?()
        }else{
            stopTimer()
            beatEnd?()
        }
    }
    
    
    /// 设置心跳
    ///
    /// - Parameter num: 数量
    func setBeat(num:Int){
        objc_sync_enter(self)
        beat = num
        objc_sync_exit(self)
    }
    
    func restoreBeat(){
        setBeat(num: 0)
    }

}
