//
//  VTeNetDataRequest.swift
//  VideoTest
//
//  Created by asdasd on 2017/8/8.
//  Copyright © 2017年 WuXia. All rights reserved.
//

import UIKit

/// 发起请求时的信令类型
///
/// - login: 登录
enum RequestType:UInt32 {
    /// 登录
    case login = 0x20001001
    /// 重连
    case reconnect = 0x20001023
    /// 心跳
    case heartBeat  = 0x00001000
    /// 用token登录
    case loginWithToken = 0x20006010
    /// 订阅GPS
    case subscribeForGPS = 0x20006001
    /// 视听
    case audiovisual = 0x20003001
    /// 登陆视听服务器
    case loginAudiovisual = 0x20003004
}

/// 视听流的类型
///
/// - low: 子码流,低清
/// - high: 主码流,高清
enum AudiovisualStreamType:UInt8 {
    case low
    case high
}

class VTeNetDataRequest: VTeNetDataBase {
    /// 组装信令,后加字符串
    ///
    /// - Parameters:
    ///   - string: 内容
    ///   - type: 类型
    ///   - subData:子信令
    /// - Returns: 数据
    fileprivate func convert(string:String,type:RequestType,subData:Data? = nil) -> Data{
        var head = signallingHead
        var type0 = type.rawValue
        var length = string.utf8.count + contentHeadLength
        if let subData = subData{
            length += subData.count
        }
        var space:[UInt8] = [0,0]
        
        var data = Data(bytes: &head, count: 4)
        data.append(Data(bytes: &type0, count: 4))
        data.append(Data(bytes: &length, count: 4))
        data.append(&space, count: space.count)
        if let subData = subData {
            data.append(subData)
        }
        
        let content = string.data(using: String.Encoding.utf8)!
        data.append(content)
        return data
    }
    
    /// 组装信令,后加数字整型
    ///
    /// - Parameters:
    ///   - num: 数字
    ///   - type: 类型
    /// - Returns: 数据
    fileprivate func convert(num:Int,type:RequestType) -> Data{
        var head = signallingHead
        var type0 = type.rawValue
        var length = 4 + contentHeadLength
        var space:[UInt8] = [0,0]
        var content = num
        
        var data = Data(bytes: &head, count: 4)
        data.append(Data(bytes: &type0, count: 4))
        data.append(Data(bytes: &length, count: 4))
        data.append(&space, count: space.count)
        data.append(Data(bytes: &content, count: 4))
        
        return data
    }
    fileprivate func convert(data:Data,type:RequestType) -> Data {
        var head = signallingHead
        var type0 = type.rawValue
        var length = data.count + contentHeadLength
        var space:[UInt8] = [0,0]
        
        
        var resData = Data(bytes: &head, count: 4)
        resData.append(Data(bytes: &type0, count: 4))
        resData.append(Data(bytes: &length, count: 4))
        resData.append(&space, count: space.count)
        resData.append(data)
        return resData
    }

}

extension VTeNetDataRequest {
    func heartbeatData() -> Data {
        return convert(string: "", type: .heartBeat)
    }
    func login(name:String,pwd:String,type:String) -> Data {
        return convert(string: name + "," + pwd + "," + type, type: .login)
    }
    func login(token:String) -> Data {
        return convert(string: token, type: .loginWithToken)
    }
    func reconnect(id:Int) -> Data {
        return convert(num:id, type: .reconnect)
    }
    /// 订阅指定车的GPS
    ///
    /// - Parameters:
    ///   - token: token description
    ///   - carIDList: carIDList description
    func subscribeForGPS(token:String,carIDList:[Int]) -> Data{
        var content = "\(carIDList.count),"
        let list = carIDList.map(){"\($0)"}
        content += list.joined(separator: ",")
        
        let subSignaling:[UInt8] = [0x03,0x00]
        let subData = Data(bytes: subSignaling, count: 2)
        
        return convert(string: content, type: .subscribeForGPS, subData: subData)
    }

    /// 取消订阅车的GPS
    ///
    /// - Parameters:
    ///   - token: token description
    ///   - carIDList: carIDList description
    /// - Returns: return value description
    func cancelSubscribeForGPS(token:String,carIDList:[Int]) -> Data{
        var content = "\(carIDList.count),"
        let list = carIDList.map(){"\($0)"}
        content += list.joined(separator: ",")

        let subSignaling:[UInt8] = [0x02,0x01]
        let subData = Data(bytes: subSignaling, count: 2)

        return convert(string: content, type: .subscribeForGPS, subData: subData)
    }
    
    /// 获取视听流的地址
    ///
    /// - Parameters:
    ///   - carID: carID description
    ///   - channelID: channelID description
    ///   - StreamType: StreamType description
    /// - Returns: return value description
    func fetchAudiovisualAddress(carID:UInt32,channelID:UInt8,StreamType:AudiovisualStreamType) -> Data{
        var carIDRef = carID
        var data = Data(bytes: &carIDRef, count: 4)
        
        let bytes:[UInt8] = [channelID,StreamType.rawValue,0x00,0x00]
        data.append(contentsOf: bytes)
        return convert(data: data, type: .audiovisual)
    }
    
    /// 登录视频服务器
    func loginAudiovisual(carID:UInt32,userID:UInt32,channelID:UInt8) -> Data {
        var carIDRef = carID
        var userIDRef = userID
        
        var data = Data(bytes: &carIDRef, count: 4)
        data.append(Data(bytes: &userIDRef, count: 4))
        let bytes:[UInt8] = [channelID,0x00,0x00]
        data.append(contentsOf: bytes)
        
        return convert(data: data, type: .loginAudiovisual)
    }
}




















