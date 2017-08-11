//
//  VTeNetDataResponse.swift
//  VideoTest
//
//  Created by asdasd on 2017/8/8.
//  Copyright © 2017年 WuXia. All rights reserved.
//

import UIKit

class VTeNetDataResponse: VTeNetDataBase {
    /// 数据
    var data:Data?

    /// 应答时的信令类型
    ///
    /// - login: 登录
    /// - heartBeat: 心跳
    enum ResponseType:Int {
        case login      = 0x10001001
        ///心跳
        case heartBeat  = 0x00001000
        /// 重连
        case reconnect  = 0x20001100
        /// 车辆GPS
        case carGPS     = 0x20001004
        /// 车辆列表
        case carList    = 0x20001005
        /// 警报
        case alarm      = 0x20001008
        /// 用token登录
        case loginWithToken = 0x10006010
        /// 视听地址
        case audiovisualAddress = 0x20003001
        /// 视听状态
        case audiovisualStatus = 0x20003007
    }

    /// 一条数据的长度
    ///
    /// - Parameter data: 数据
    /// - Returns: 长度
    private func length(of data:Data) -> Int? {
        guard data.count >= contentHeadLength else {
            return nil
        }
        
        var length = 0
        (data as NSData).getBytes(&length, range: NSRange(location:8, length: 4))
        return length
    }
    
    /// 数据是否完整
    ///
    /// - Parameter data: 数据
    /// - Returns: 结果
    private func isComplete(data:Data) -> Bool{
        guard let length = length(of: data) else {
            return false
        }
        return data.count == length
    }


    /// 把数据按一个标志分割开
    ///
    /// - Parameters:
    ///   - data: 数据
    ///   - sep: 标志
    /// - Returns: 结果
    private func split(data:Data,separatedBy sep:UInt32) -> [Data] {
        
        var head = sep
        let headData = Data(bytes: &head, count: 4)
        
        var start = 0
        let end   = data.count
        
        var startList:[Int] = []
        while let range = data.range(of: headData, in: start ..< end) {
            startList.append(range.lowerBound)
            start = range.upperBound
        }
        
        var resultsDataList = [Data]()
        var subData:Data
        for i in 0 ..< startList.count {
            if i == startList.count - 1{
                subData = data.subdata(in: startList.last! ..< data.count)
            }else{
                subData = data.subdata(in: startList[i] ..< startList[i + 1])
            }
            resultsDataList.append(subData)
        }
        
        if let last = resultsDataList.last,!isComplete(data: last){
            self.data = resultsDataList.removeLast()
        }else{
            self.data = nil
        }
        return resultsDataList
    }
    
    /// 增加数据到尾部
    ///
    /// - Parameter data: 数据
    /// - Returns: 返回的数据
    func append(other data:Data){
        if self.data == nil{
            self.data = Data()
        }
        self.data!.append(data)
        let dataList = split(data: self.data!, separatedBy: signallingHead)
        for components in dataList{
            if let res = results(from: components){
                analyze(type: res.0, data: res.1)
            }
        }
    }

    /// 解析完整的数据
    ///
    /// - Parameter data: 完整数据
    /// - Returns: 结果 (数据类型,有效数据)
    func results(from data: Data) -> (Int,Data)? {
        
        // 数据不够长
        guard isComplete(data: data) else {
            return nil
        }
        
        var head:UInt32 = 0
        (data as NSData).getBytes(&head, range: NSRange(location: 0, length: 4))
        // 信令头不符合
        guard head == signallingHead else {
            fatalError("信令头不符合")
        }
        var type = 0
        (data as NSData).getBytes(&type, range: NSRange(location: 4, length: 4))
        
        let resutls = data.subdata(in: contentHeadLength ..< data.count)
        
        return (type,resutls)
    }
}

extension VTeNetDataResponse {
    /// 分析数据内容,把返回数据是否成功解析出来 0x00成功 0x01 已登陆 0x02密码错误
    ///
    /// - Parameter data: 内容
    /// - Returns: 结果
    func analyze(type:Int, data:Data){
        guard let res = ResponseType(rawValue:type) else {
            print("未知信令类型:" + String(format:"%0x",type))
            return
        }
        switch res {
        case .login:
            responseOfLogin(data: data)
        case .heartBeat:
            print("心跳")
            responseOfHeartBeat()
        case .carGPS:
            responseOfGPS(data: data)
        case .reconnect:
            print("重连")
            respondseOfReconnect(data: data)
        case .carList:
            responseOfCarList(data: data)
        case .alarm:
            print("警报 未处理 -- PPF")
        case .loginWithToken:
            responseOfLoginWithToken(data: data)
        case .audiovisualAddress:
            responseOfAudiovisualAddress(data: data)
        case .audiovisualStatus:
            responseOfAudiovisualStatus(data: data)
        }
    }
    
    fileprivate func responseOfHeartBeat(){
        NotificationCenter.default.post(name: NSNotification.Name.receiveHearBeatResponse, object: nil)
    }
    
    fileprivate func responseOfAudiovisualStatus(data:Data){
        var carID:UInt32        = UInt32.max
        var userID:UInt32       = UInt32.max
        var channelID:UInt8     = UInt8.max
        var type:UInt8          = UInt8.max
        
        let d = data as NSData
        d.getBytes(&carID, length: 4)
        d.getBytes(&userID, range:NSRange(location: 4, length: 4))
        d.getBytes(&channelID, range: NSRange(location: 8, length: 1))
        d.getBytes(&type, range: NSRange(location: 11, length: 1))
        
        guard let status = StreamStatus.Status(rawValue: type) else{
            fatalError()
        }
        let streamStatus = StreamStatus(carID: carID, userID: userID, channelID: channelID, status: status)
        let dic = [audiovisualStreamStatusNotificationKey:streamStatus]
        NotificationCenter.default.post(name: NSNotification.Name.audiovisualStreamStatusResponse, object: nil, userInfo: dic)
    }
    
    fileprivate func responseOfAudiovisualAddress(data:Data){
        print(#function)
        var carID:UInt32        = UInt32.max
        var userID:UInt32       = UInt32.max
        var channelID:UInt8     = UInt8.max
        var streamType:UInt8    = UInt8.max
        var type:UInt8          = UInt8.max
        var factoryID:UInt8     = UInt8.max
        var ipPosition:UInt8    = UInt8.max
        
        let d = data as NSData
        d.getBytes(&carID, length: 4)
        d.getBytes(&userID, range: NSRange(location: 4, length: 4))
        d.getBytes(&channelID, range: NSRange(location: 8, length: 1))
        d.getBytes(&streamType, range: NSRange(location: 9, length: 1))
        d.getBytes(&type, range: NSRange(location: 10, length: 1))
        d.getBytes(&factoryID, range: NSRange(location: 11, length: 1))
        d.getBytes(&ipPosition, range: NSRange(location: 16, length: 1))
        
        let ipData = data.subdata(in: (Int(ipPosition) - 14) ..< data.count)

        guard let st = AudiovisualStreamType(rawValue: streamType) else {
            fatalError("流类型不识别,\(streamType)")
        }
        guard let rst = ResponseStreamType(rawValue: type) else{
            fatalError("流应答类型不识别,\(type)")
        }
        guard let ip = String(data: ipData, encoding: String.Encoding.utf8) else{
            fatalError("ip地址不是字符串")
        }
        
        let ipList = ip.components(separatedBy: ":")
        
        let address = StreamAddress(carID: carID, userID: userID, channelID: channelID, streamType: st, type: rst, factoryID: factoryID, ip: ipList[0], port: UInt16(ipList[1])!)
        NotificationCenter.default.post(name: NSNotification.Name.audiovisualAddress, object: nil, userInfo: [audiovisualAddressNotificationKey:address])
    }
    
    fileprivate func responseOfLoginWithToken(data:Data){
        print(#function)
        var res:UInt8 = UInt8.max
        (data as NSData).getBytes(&res, range: NSRange(location: 0, length: 1))
        if res == 0 {
            print("登陆token成功")
            NotificationCenter.default.post(name: .LoginWithToken, object: nil, userInfo: nil)
        }else{
            print("登陆token失败")
            NotificationCenter.default.post(name: .needLogin, object: nil)
        }
    }
    
    /// 登录应答
    ///
    /// - Parameter data: 数据
    fileprivate func responseOfLogin(data:Data){
        // 登录状态
        var type:UInt8 = 250
        (data as NSData).getBytes(&type, range: NSRange(location: 0, length: 1))
        
        //用户ID
        var id:Int = 99999
        (data as NSData).getBytes(&id, range: NSRange(location: 1, length: 4))
        
        //用户权限
        let subData = data.subdata(in: 5 ..< data.count)
        let _ = String(data: subData, encoding: String.Encoding.utf8)
        
        var dic = ["type":type,"id":id] as [String : Any]
        dic["other"] = String(data: subData, encoding: String.Encoding.utf8)
        NotificationCenter.default.post(name: NSNotification.Name.Login, object: nil, userInfo: dic)
    }
    
    
    /// 重连的应答
    ///
    /// - Parameter data: 数据
    fileprivate func respondseOfReconnect(data:Data){
        print(#function)
        //判断一下是否是我发出的重连请求
        var resNum:UInt32 = 0xffffffff
        (data as NSData).getBytes(&resNum, range: NSRange(location: 4, length: 4))
        guard resNum == RequestType.reconnect.rawValue else{
            return
        }
        resNum = 0xff
        (data as NSData).getBytes(&resNum, range: NSRange(location: 8, length: 1))
        if resNum == 0x0{//重连成功
            NotificationCenter.default.post(name: NSNotification.Name.successfulReconnect, object: nil)
        }else {//重连失败,需要重新登录
            NotificationCenter.default.post(name: NSNotification.Name.needLogin, object: nil)
        }
    }
    
    
    /// 车列表的应答
    ///
    /// - Parameter data: data description
    fileprivate func responseOfCarList(data:Data){
        print(#function)
        let str = String(data: data, encoding: .utf8) ?? "?"

        var components = str.components(separatedBy: "|")
        guard components.count >= 2  else{
            fatalError()
        }
        guard let usrM = user else {
            fatalError("没有登录")
        }
        usrM.carList = []

        let _ = components.removeFirst()//这里是组的信息,以后可能有用,现在没用.
        guard let _ = Int(components.removeFirst()) else{
            fatalError("车辆总数不是数字")
        }
        for item in components {//一辆汽车的信息
            let carCom = item.components(separatedBy: ",")
            guard  carCom.count == 9 else {
                fatalError("车辆信息总数不是9条.")
            }

            let car = Car_M()
            car.carID = Int(carCom[0]) ?? emptyInt
            car.equipmentID = carCom[1]
            car.isOnline = carCom[2] == "0"
            car.name    = carCom[3]
            car.type    = carCom[4]
            car.remark  = carCom[5]
            car.phone   = carCom[6]
            car.parentID = carCom[7]
            car.oilConsumption = Int(carCom[8]) ?? emptyInt
            usrM.carList!.append(car.carID)
            DataBase.share.insertOrUpdate(car: car)
        }
    }

    fileprivate func responseOfGPS(data:Data){
        guard let gpsStr = String(data: data, encoding: String.Encoding.utf8) else{
            fatalError("GPS的数据不是字符串")
        }
        let components = gpsStr.components(separatedBy: ",")
        let gps = CarGPS_M()

        gps.carID       = Int(components[0]) ?? emptyInt
        gps.isOnline    = components[1] == "0"
        gps.isValid     = components[2] == "0"
        gps.direction   = Int(components[3]) ?? 0
        gps.GPSVelocity = Int(components[4]) ?? 0
        gps.longitude   = Double(components[5]) ?? 0
        gps.latitude    = Double(components[6]) ?? 0
        gps.dateAndTime = components[7]
        gps.firmwareState  = components[8]
        gps.oilConsumption = Int(components[9]) ?? 0
        gps.mileage     = Int(components[10]) ?? 0
        gps.alarm       = components[11]
        gps.runningSpeed = Int(components[12]) ?? 0
        gps.isLogin     = components[13] == "0"
        gps.altitude    = Double(components[14]) ?? 0
        gps.temperature01 = Int(components[15]) ?? 0
        gps.temperature02 = Int(components[16]) ?? 0
        gps.temperature03 = Int(components[17]) ?? 0
        gps.temperature04 = Int(components[18]) ?? 0
        gps.foreward = components[19] == "0"

        DataBase.share.insertOrUpdate(GPS: gps)


        let gcj = ConvertWGS84ToGCJ02.transformFormWGSToGCJ(latitude: gps.latitude, longitude: gps.longitude)
        gps.latitude = gcj.latitude
        gps.longitude = gcj.longitude

        let userInfo = ["GPS":gps]
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .GPS, object: nil, userInfo: userInfo)
        }
    }
}

extension Notification.Name {
    static let successfulReconnect = Notification.Name("wuxia.video.successfulReconnect")
    static let audiovisualAddress  = Notification.Name("wuxia.video.audiovisualAddress")
    static let audiovisualStreamStatusResponse = Notification.Name("wuxia.video.streamStatus")
    static let receiveHearBeatResponse = Notification.Name("wuxia.video.heartBeat")
}

/// 视听地址的通知键
let audiovisualAddressNotificationKey = "audiovisualAddressNotificationKey"
/// 视听流的状态通知键
let audiovisualStreamStatusNotificationKey = "audiovisualStreamStatusNotificationKey"












