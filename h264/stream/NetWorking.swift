//
//  NetWorking.swift
//  WuXiaGPS
//
//  Created by asdasd on 2017/5/16.
//  Copyright © 2017年 WuXia. All rights reserved.
//

//import UIKit
//import CocoaAsyncSocket
//
//class NetWorking: NSObject {
//    
//    /// 发起请求时的信令类型
//    ///
//    /// - login: 登录
//    enum RequestType:UInt32 {
//        /// 登录
//        case login = 0x20001001
//        /// 重连
//        case reconnect = 0x20001023
//        /// 心跳
//        case heartBeat  = 0x00001000
//        /// 用token登录
//        case loginWithToken = 0x20006010
//        /// 订阅GPS
//        case subscribeForGPS = 0x20006001
//        /// 视听
//        case audiovisual = 0x20003001
//    }
//    
//    /// 应答时的信令类型
//    ///
//    /// - login: 登录
//    /// - heartBeat: 心跳
//    enum ResponseType:Int {
//        case login      = 0x10001001
//        ///心跳
//        case heartBeat  = 0x00001000
//        /// 重连
//        case reconnect  = 0x20001100
//        /// 车辆GPS
//        case carGPS     = 0x20001004
//        /// 车辆列表
//        case carList    = 0x20001005
//        /// 警报
//        case alarm      = 0x20001008
//        /// 用token登录
//        case loginWithToken = 0x10006010
//    }
//    
//    
//    
//    static let share:NetWorking = NetWorking()
//    
//    /// IP
////    private let hostIP = "192.168.10.78"
//    private var hostIP = "60.190.100.230"
//    /// 端口
////    private let hostPort:UInt16 = 9557
//    private var hostPort:UInt16 = 10035
//    /// 计时器
//    fileprivate weak var timer:Timer?
//
//    /// 信息头,有这个就说明是一段新的信令
//    let signallingHead:UInt32 = 0x9f9e9d9c
//    /// 包头部的长度
//    let contentHeadLength = 14
//    
//    /// 数据
//    var data:Data?
//    
//    /// 客户端的线程
//    let clientQueue = DispatchQueue.global()
//    
//    /// 正在等待执行的操作
//    var beWaitedRequests:[RequestType:()->()] = [:]
//    
//    private var _client:GCDAsyncSocket!
//    /// socket
//    var client:GCDAsyncSocket{
//        get{
//            if _client == nil{
//                _client = GCDAsyncSocket()
//                _client.delegate = self
//                _client.delegateQueue = clientQueue
//            }
//            return _client
//        }
//    }
//    
//    /// 客户端是否连接
//    fileprivate(set) var isConnected = true
//    
//    
//    /// 设置socket连接的IP和端口
//    ///
//    /// - Parameters:
//    ///   - ip: ip description
//    ///   - port: port description
//    func set(ip:String, port:UInt16){
//        hostIP = ip
//        hostPort = port
//    }
//    
//    /// 建立长连接
//    ///
//    /// - Parameters:
//    ///   - hostIP: IP地址
//    ///   - port: 端口
//    func connect(hostIP:String,port:UInt16) {
//        guard !client.isConnected else {
//            return
//        }
//        do{
//            try client.connect(toHost: hostIP, onPort: port)
//        }catch{
//            fatalError("不能连接host:\(hostIP),port:\(hostPort)")
//        }
//    }
//    func connect() {
//        connect(hostIP: hostIP, port: hostPort)
//    }
//    
//    /// 断开连接
//    func disconnect() {
//        guard client.isConnected else {
//            return
//        }
//        client.disconnect()
//        stopTimer()
//    }
//    
//    
//    /// 去读数据
//    ///
//    /// - Parameter tag: tag
//    /// - Returns: 是否成功
//    @discardableResult
//    func read(tag:Int) -> Bool{
//        guard client.isConnected else{
//            return false
//        }
//        client.readData(withTimeout: -1, tag: tag)
//        return true
//    }
//    
//    
//    
//    /// 组装信令,后加字符串
//    ///
//    /// - Parameters:
//    ///   - string: 内容
//    ///   - type: 类型
//    ///   - subData:子信令
//    /// - Returns: 数据
//    func convert(string:String,type:RequestType,subData:Data? = nil) -> Data{
//        var head = signallingHead
//        var type0 = type.rawValue
//        var length = string.utf8.count + contentHeadLength
//        if let subData = subData{
//            length += subData.count
//        }
//        var space:[UInt8] = [0,0]
//        
//        var data = Data(bytes: &head, count: 4)
//        data.append(Data(bytes: &type0, count: 4))
//        data.append(Data(bytes: &length, count: 4))
//        data.append(&space, count: space.count)
//        if let subData = subData {
//            data.append(subData)
//        }
//        
//        let content = string.data(using: String.Encoding.utf8)!
//        data.append(content)
//        return data
//    }
//    
//    /// 组装信令,后加数字整型
//    ///
//    /// - Parameters:
//    ///   - num: 数字
//    ///   - type: 类型
//    /// - Returns: 数据
//    func convert(num:Int,type:RequestType) -> Data{
//        var head = signallingHead
//        var type0 = type.rawValue
//        var length = 4 + contentHeadLength
//        var space:[UInt8] = [0,0]
//        var content = num
//        
//        var data = Data(bytes: &head, count: 4)
//        data.append(Data(bytes: &type0, count: 4))
//        data.append(Data(bytes: &length, count: 4))
//        data.append(&space, count: space.count)
//        data.append(Data(bytes: &content, count: 4))
//        
//        return data
//    }
//    
//    
//
//    
//    /// 数据是否完整
//    ///
//    /// - Parameter data: 数据
//    /// - Returns: 结果
//    func isComplete(data:Data) -> Bool{
//        guard let length = length(of: data) else {
//            return false
//        }
//        return data.count == length
//    }
//    
//    /// 解析完整的数据
//    ///
//    /// - Parameter data: 完整数据
//    /// - Returns: 结果 (数据类型,有效数据)
//    func results(from data: Data) -> (Int,Data)? {
//        
//        // 数据不够长
//        guard isComplete(data: data) else {
////            fatalError()
//            return nil
//        }
//        
//        var head:UInt32 = 0
//        (data as NSData).getBytes(&head, range: NSRange(location: 0, length: 4))
//        // 信令头不符合
//        guard head == signallingHead else {
//            fatalError("信令头不符合")
//        }
//        var type = 0
//        (data as NSData).getBytes(&type, range: NSRange(location: 4, length: 4))
//        
//        let resutls = data.subdata(in: contentHeadLength ..< data.count)
//        
//        return (type,resutls)
//    }
//    
//    
//    /// 一条数据的长度
//    ///
//    /// - Parameter data: 数据
//    /// - Returns: 长度
//    private func length(of data:Data) -> Int? {
//        guard data.count >= contentHeadLength else {
//            return nil
//        }
//        
//        var length = 0
//        (data as NSData).getBytes(&length, range: NSRange(location:8, length: 4))
//        return length
//    }
//    
//    
//    /// 增加数据到尾部
//    ///
//    /// - Parameter data: 数据
//    /// - Returns: 返回的数据
//    func append(other data:Data) -> [Data]{
//        if self.data == nil{
//            self.data = Data()
//        }
//        self.data!.append(data)
//        
//        guard let data = self.data else{
//            fatalError()
//        }
//        return split(data: data, separatedBy: signallingHead)
//    }
//    
//    
//    /// 把数据按一个标志分割开
//    ///
//    /// - Parameters:
//    ///   - data: 数据
//    ///   - sep: 标志
//    /// - Returns: 结果
//    func split(data:Data,separatedBy sep:UInt32) -> [Data] {
//
//        var head = sep
//        let headData = Data(bytes: &head, count: 4)
//        
//        var start = 0
//        let end   = data.count
//        
//        var startList:[Int] = []
//        while let range = data.range(of: headData, in: start ..< end) {
//            startList.append(range.lowerBound)
//            start = range.upperBound
//        }
//        
//        var resultsDataList = [Data]()
//        var subData:Data
//        for i in 0 ..< startList.count {
//            if i == startList.count - 1{
//                subData = data.subdata(in: startList.last! ..< data.count)
//            }else{
//                subData = data.subdata(in: startList[i] ..< startList[i + 1])
//            }
//            resultsDataList.append(subData)
//        }
//        
//        if let last = resultsDataList.last,!isComplete(data: last){
//            self.data = resultsDataList.removeLast()
//        }else{
//            self.data = nil
//        }
//        return resultsDataList
//    }
//}
//
//
//// MARK: - GCDAsyncSocketDelegate
//extension NetWorking:GCDAsyncSocketDelegate{
//    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
//        print(#function)
//        setConnected(connect: true)
//        startHeatBeat()
//        if let block  = beWaitedRequests[RequestType.login] {
//            block()
//        }else if let block = beWaitedRequests[RequestType.reconnect]{
//            block()
//        }else if let block = beWaitedRequests[RequestType.loginWithToken]{
//            block()
//        }
//        beWaitedRequests[RequestType.login] = nil
//        beWaitedRequests[RequestType.reconnect] = nil
//        beWaitedRequests[RequestType.loginWithToken] = nil
//    }
//    
//    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
//        print(#function)
//        print("error:\(err?.localizedDescription ?? "??" )")
//        stopTimer()
//        setConnected(connect: false)
//        Heartbeat.share.setBeat(num: 999)
//    }
//    
//    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
//        let dataList  = append(other: data)
//        
//        for components in dataList{
//            if let res = results(from: components){
//                analyze(type: res.0, data: res.1)
//            }
//        }
//        read(tag: 0)
//    }
//    
//    
//    /// 打印十六进制,可以删除
//    ///
//    /// - Parameter data: 数据
//    func printData(data:Data){
//        var array = Array(repeating: UInt8(0), count: data.count)
//        data.copyBytes(to: &array, count: data.count)
//        for  a in array{
//            print(String(format: "%02x ", a),terminator:"");
//        }
//    }
//}
//
//
//
//// MARK: - 计时器
//extension NetWorking{
//    func startHeatBeat(){
//        Heartbeat.share.startTimer(block: {[weak self] in
//            self?.sendHeartBeat()
//        }){ [weak self] in
//            self?.setConnected(connect: false)
//            self?.client.disconnect()
//        }
//    }
//    
//    func stopTimer(){
//        Heartbeat.share.stopTimer()
//    }
//    
//    func sendHeartBeat(){
//        if isConnected{
//            let data = convert(string: "", type: NetWorking.RequestType.heartBeat)
//            client.write(data, withTimeout: -1, tag: 1)
//        }
//    }
//    
//    
//    func setConnected(connect:Bool){
//        objc_sync_enter(self)
//        isConnected = connect
//        objc_sync_exit(self)
//        if connect{
//            NotificationCenter.default.post(name: NSNotification.Name.netConnect, object: nil)
//        }else{
//            NotificationCenter.default.post(name: NSNotification.Name.netDisconnect, object: nil)
//        }
//        
//    }
//    
//}
//
//// MARK: - 请求的方法
//extension NetWorking{
//    
//    
//    ///  执行block,如果发现是断线状态就先重连再执行.
//    ///
//    /// - Parameters:
//    ///   - id: 用户ID
//    ///   - block: 执行块
//    func executeOrReconnect(id:Int,type:RequestType,block:@escaping (()->())){
//        if client.isConnected && Heartbeat.share.isLive {
//            block()
//        }else{
//            beWaitedRequests[type] = block
//            reconnect(id: id)
//        }
//    }
//    
//    /// 执行block,如果发现是断线状态就先用token重连再执行
//    ///
//    /// - Parameters:
//    ///   - token: token description
//    ///   - type: type description
//    ///   - block: block description
//    func executeOrLogin(with token:String,type:RequestType,block:@escaping (()->())){
//        if client.isConnected && Heartbeat.share.isLive {
//            block()
//        }else{
//            beWaitedRequests[type] = block
//            login(token: token)
//        }
//    }
//    
//    
//    /// 执行所有正在等待的请求除了登录和重连请求,并清空
//    func executeAllBeWaitedBlock(){
//        for (key,block) in beWaitedRequests{
//            switch key {
//            case .login,.reconnect,.loginWithToken:
//                break
//            default:
//                block()
//            }
//        }
//        beWaitedRequests.removeAll()
//    }
//    
//    
//    /// 登录
//    ///
//    /// - Parameters:
//    ///   - name: 名字
//    ///   - pwd: 密码
//    ///   - type: 类型
//    func login(name:String,pwd:String,type:String = "0"){
//        let block = {[unowned self] in
//            let data = self.convert(string: name + "," + pwd + "," + type, type: RequestType.login)
//            self.client.write(data, withTimeout: 40, tag: 0)
//            self.read(tag: 0)
//        }
//        
//        if client.isConnected && Heartbeat.share.isLive {
//            block()
//        }else{
//            beWaitedRequests[RequestType.login] = block
//            connect()
//        }
//    }
//    
//    func login(token:String){
//        let block = {[unowned self] in
//            let data = self.convert(string: token, type: .loginWithToken)
//            self.client.write(data, withTimeout: 40, tag: 0)
//            self.read(tag: 0)
//        }
//        if client.isConnected && Heartbeat.share.isLive {
//            block()
//        }else{
//            beWaitedRequests[RequestType.loginWithToken] = block
//            connect()
//        }
//    }
//    
//    /// 重连
//    ///
//    /// - Parameters:
//    ///   - id: 用记ID
//    ///   - type: 类型
//    func reconnect(id:Int){
//        let block = {[unowned self] in
//            let data = self.convert(num:id, type: RequestType.reconnect)
//            self.client.write(data, withTimeout: 40, tag: 0)
//            self.read(tag: 0)
//        }
//        
//        if client.isConnected && Heartbeat.share.isLive {
//            block()
//        }else{
//            beWaitedRequests[RequestType.reconnect] = block
//            connect()
//        }
//    }
//    
//    
//    /// 获取车辆列表(目前没有这个的单独接口,先使用登录接口来获取车辆的初始GPS数据)
//    ///
//    /// - Parameters:
//    ///   - name: 用户句
//    ///   - pwd: 密码
//    func fetchCarList(name:String,pwd:String){
//        guard !client.isConnected || !Heartbeat.share.isLive else{
//            return
//        }
//        login(name: name, pwd: pwd)
//    }
//    
//    
//    /// 订阅指定车的GPS
//    ///
//    /// - Parameters:
//    ///   - token: token description
//    ///   - carIDList: carIDList description
//    func subscribeForGPS(token:String,carIDList:[Int]){
//        guard carIDList.count > 0 else {
//            return
//        }
//        let block = { [unowned self] in
//            var content = "\(carIDList.count),"
//            let list = carIDList.map(){"\($0)"}
//            content += list.joined(separator: ",")
//            
//            let subSignaling:[UInt8] = [0x03,0x00]
//            let subData = Data(bytes: subSignaling, count: 2)
//            
//            let data = self.convert(string: content, type: .subscribeForGPS, subData: subData)
//
//            self.client.write(data, withTimeout: 40, tag: 0)
//            self.read(tag: 0)
//        }
//        executeOrLogin(with: token, type: .subscribeForGPS, block: block)
//    }
//    
//    func cancelSubscribeForGPS(token:String,carIDList:[Int]){
//        guard carIDList.count > 0 else {
//            return
//        }
//        let block = { [unowned self] in
//            var content = "\(carIDList.count),"
//            let list = carIDList.map(){"\($0)"}
//            content += list.joined(separator: ",")
//            
//            let subSignaling:[UInt8] = [0x02,0x01]
//            let subData = Data(bytes: subSignaling, count: 2)
//            
//            let data = self.convert(string: content, type: .subscribeForGPS, subData: subData)
//            self.client.write(data, withTimeout: 40, tag: 0)
//            self.read(tag: 0)
//        }
//        executeOrLogin(with: token, type: .subscribeForGPS, block: block)
//    }
//    
//}
//
//
//
//
//// MARK: - 应答的数据
//extension NetWorking{
//    
//    
//    /// 分析数据内容,把返回数据是否成功解析出来 0x00成功 0x01 已登陆 0x02密码错误
//    ///
//    /// - Parameter data: 内容
//    /// - Returns: 结果
//    func analyze(type:Int, data:Data){
//        guard let res = ResponseType(rawValue:type) else {
//            print("未知信令类型:" + String(format:"%0x",type))
//            return
//        }
//        switch res {
//        case .login:
//            responseOfLogin(data: data)
//        case .heartBeat:
//            print("心跳")
//            Heartbeat.share.restoreBeat()
//        case .carGPS:
//            responseOfGPS(data: data)
//        case .reconnect:
//            print("重连")
//            respondseOfReconnect(data: data)
//        case .carList:
//            responseOfCarList(data: data)
//        case .alarm:
//            print("警报 未处理 -- PPF")
//        case .loginWithToken:
//            responseOfLoginWithToken(data: data)
//        }
//    }
//    
//    fileprivate func responseOfLoginWithToken(data:Data){
//        print(#function)
//        var res:UInt8 = UInt8.max
//        (data as NSData).getBytes(&res, range: NSRange(location: 0, length: 1))
//        if res == 0 {
//            print("登陆token成功")
//            executeAllBeWaitedBlock()
//            NotificationCenter.default.post(name: .LoginWithToken, object: nil, userInfo: nil)
//        }else{
//            print("登陆token失败")
//            beWaitedRequests.removeAll()
//            NotificationCenter.default.post(name: .needLogin, object: nil)
//        }
//    }
//    
//    fileprivate func responseOfCarList(data:Data){
//        print(#function)
//        let str = String(data: data, encoding: .utf8) ?? "?"
//        
//        var components = str.components(separatedBy: "|")
//        guard components.count >= 2  else{
//            fatalError()
//        }
//        guard let usrM = user else {
//            fatalError("没有登录")
//        }
//        usrM.carList = []
//        
//        let _ = components.removeFirst()//这里是组的信息,以后可能有用,现在没用.
//        guard let _ = Int(components.removeFirst()) else{
//            fatalError("车辆总数不是数字")
//        }
//        for item in components {//一辆汽车的信息
//            let carCom = item.components(separatedBy: ",")
//            guard  carCom.count == 9 else {
//                fatalError("车辆信息总数不是9条.")
//            }
//            
//            let car = Car_M()
//            car.carID = Int(carCom[0]) ?? emptyInt
//            car.equipmentID = carCom[1]
//            car.isOnline = carCom[2] == "0"
//            car.name    = carCom[3]
//            car.type    = carCom[4]
//            car.remark  = carCom[5]
//            car.phone   = carCom[6]
//            car.parentID = carCom[7]
//            car.oilConsumption = Int(carCom[8]) ?? emptyInt
//            usrM.carList!.append(car.carID)
//            DataBase.share.insertOrUpdate(car: car)
//        }
//        
//    }
//
//    fileprivate func responseOfGPS(data:Data){
//        guard let gpsStr = String(data: data, encoding: String.Encoding.utf8) else{
//            fatalError("GPS的数据不是字符串")
//        }
//        let components = gpsStr.components(separatedBy: ",")
//        let gps = CarGPS_M()
//        
//        gps.carID       = Int(components[0]) ?? emptyInt
//        gps.isOnline    = components[1] == "0"
//        gps.isValid     = components[2] == "0"
//        gps.direction   = Int(components[3]) ?? 0
//        gps.GPSVelocity = Int(components[4]) ?? 0
//        gps.longitude   = Double(components[5]) ?? 0
//        gps.latitude    = Double(components[6]) ?? 0
//        gps.dateAndTime = components[7]
//        gps.firmwareState  = components[8]
//        gps.oilConsumption = Int(components[9]) ?? 0
//        gps.mileage     = Int(components[10]) ?? 0
//        gps.alarm       = components[11]
//        gps.runningSpeed = Int(components[12]) ?? 0
//        gps.isLogin     = components[13] == "0"
//        gps.altitude    = Double(components[14]) ?? 0
//        gps.temperature01 = Int(components[15]) ?? 0
//        gps.temperature02 = Int(components[16]) ?? 0
//        gps.temperature03 = Int(components[17]) ?? 0
//        gps.temperature04 = Int(components[18]) ?? 0
//        gps.foreward = components[19] == "0"
//        
//        DataBase.share.insertOrUpdate(GPS: gps)
//        
//        
//        let gcj = ConvertWGS84ToGCJ02.transformFormWGSToGCJ(latitude: gps.latitude, longitude: gps.longitude)
//        gps.latitude = gcj.latitude
//        gps.longitude = gcj.longitude
//        
//        let userInfo = ["GPS":gps]
//        DispatchQueue.main.async {
//            NotificationCenter.default.post(name: .GPS, object: nil, userInfo: userInfo)
//        }
//    }
//    
//    /// 登录应答
//    ///
//    /// - Parameter data: 数据
//    fileprivate func responseOfLogin(data:Data){
//        print(#function)
//        
//        executeAllBeWaitedBlock()
//
//        // 登录状态
//        var type:UInt8 = 250
//        (data as NSData).getBytes(&type, range: NSRange(location: 0, length: 1))
//
//        //用户ID
//        var id:Int = 99999
//        (data as NSData).getBytes(&id, range: NSRange(location: 1, length: 4))
//        
//        //用户权限
//        let subData = data.subdata(in: 5 ..< data.count)
//        let _ = String(data: subData, encoding: String.Encoding.utf8)
//        
//        var dic = ["type":type,"id":id] as [String : Any]
//        dic["other"] = String(data: subData, encoding: String.Encoding.utf8)
//        NotificationCenter.default.post(name: NSNotification.Name.Login, object: nil, userInfo: dic)
//    }
//    
//    
//    /// 重连的应答
//    ///
//    /// - Parameter data: 数据
//    fileprivate func respondseOfReconnect(data:Data){
//        //判断一下是否是我发出的重连请求
//        var resNum:UInt32 = 0xffffffff
//        (data as NSData).getBytes(&resNum, range: NSRange(location: 4, length: 4))
//        guard resNum == RequestType.reconnect.rawValue else{
//            return
//        }
//        resNum = 0xff
//        (data as NSData).getBytes(&resNum, range: NSRange(location: 8, length: 1))
//        if resNum == 0x0{//重连成功
//            executeAllBeWaitedBlock()
//        }else {//重连失败,需要重新登录
//            NotificationCenter.default.post(name: NSNotification.Name.needLogin, object: nil)
//        }
//    }
//}
//
//extension Notification.Name{
//    /// 登录
//    static let Login:Notification.Name = Notification.Name(rawValue:"wuxia.login.NotificationName")
//    /// 用token登录
//    static let LoginWithToken:Notification.Name = Notification.Name(rawValue:"wuxia.loginWithToken.NotificationName")
//    /// 重连
//    static let reconnect:Notification.Name = Notification.Name(rawValue: "wuxia.reconnect.Notification")
//    /// 网络断开连接
//    static let netDisconnect:Notification.Name = Notification.Name(rawValue: "wuxia.netDisconnect.Notification")
//    /// 网络连接
//    static let netConnect:Notification.Name = Notification.Name(rawValue: "wuxia.netConnect.Notification")
//    /// 需要重新登录
//    static let needLogin:Notification.Name = Notification.Name(rawValue: "wuxia.needLogin.Notification")
//    /// 需要重新登录
//    static let GPS:Notification.Name = Notification.Name(rawValue: "wuxia.GPS.Notification")
//}
//



import UIKit
import CocoaAsyncSocket

class NetWorking: NSObject {
    
    static let share:NetWorking = NetWorking()
    var response:VTeNetDataResponse!
    var request:VTeNetDataRequest!
    var heartBeat:Heartbeat?
    
    /// IP
    //    private let hostIP = "192.168.10.78"
    private var hostIP = "60.190.100.230"
    /// 端口
    //    private let hostPort:UInt16 = 9557
    private var hostPort:UInt16 = 10035
    /// 计时器
    fileprivate weak var timer:Timer?
    
    /// 信息头,有这个就说明是一段新的信令
    let signallingHead:UInt32 = 0x9f9e9d9c
    /// 包头部的长度
    let contentHeadLength = 14
    
    /// 数据
    var data:Data?
    
    /// 客户端的线程
    let clientQueue = DispatchQueue.global()
    
    /// 正在等待执行的操作
    var beWaitedRequests:[RequestType:()->()] = [:]
    
    private var _client:GCDAsyncSocket!
    /// socket
    var client:GCDAsyncSocket{
        get{
            if _client == nil{
                _client = GCDAsyncSocket()
                _client.delegate = self
                _client.delegateQueue = clientQueue
            }
            return _client
        }
    }
    
    /// 客户端是否连接
    fileprivate(set) var isConnected = true
    
    
    override init() {
        super.init()
        
        request = VTeNetDataRequest()
        response = VTeNetDataResponse()

        NotificationCenter.default.addObserver(self, selector: #selector(NetWorking.notificationForLoginWithToken), name: NSNotification.Name.LoginWithToken, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(NetWorking.notificationForNeedLogin), name: NSNotification.Name.needLogin, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(NetWorking.notificationForSuccessfulReconnect), name: NSNotification.Name.successfulReconnect, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(NetWorking.notificationForHearBeat(notification:)), name: NSNotification.Name.receiveHearBeatResponse, object: nil)
        
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    /// 设置socket连接的IP和端口
    ///
    /// - Parameters:
    ///   - ip: ip description
    ///   - port: port description
    func set(ip:String, port:UInt16){
        hostIP = ip
        hostPort = port
    }
    
    /// 建立长连接
    ///
    /// - Parameters:
    ///   - hostIP: IP地址
    ///   - port: 端口
    func connect(hostIP:String,port:UInt16) {
        guard !client.isConnected else {
            return
        }
        do{
            try client.connect(toHost: hostIP, onPort: port)
        }catch{
            fatalError("不能连接host:\(hostIP),port:\(hostPort)")
        }
    }
    func connect() {
        connect(hostIP: hostIP, port: hostPort)
    }
    
    /// 断开连接
    func disconnect() {
        guard client.isConnected else {
            return
        }
        client.disconnect()
        stopTimer()
    }
    
    
    /// 去读数据
    ///
    /// - Parameter tag: tag
    /// - Returns: 是否成功
    @discardableResult
    func read(tag:Int) -> Bool{
        guard client.isConnected else{
            return false
        }
        client.readData(withTimeout: -1, tag: tag)
        return true
    }
}

//MARK: - notification
extension NetWorking {
    func notificationForHearBeat(notification:Notification){
        heartBeat?.restoreBeat()
    }
    func notificationForSuccessfulReconnect(){
        self.executeAllBeWaitedBlock()
    }
    func notificationForLoginWithToken() {
        self.executeAllBeWaitedBlock()
    }
    func notificationForNeedLogin() {
        self.beWaitedRequests.removeAll()
    }
}



// MARK: - GCDAsyncSocketDelegate
extension NetWorking:GCDAsyncSocketDelegate{
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        print(#function)
        setConnected(connect: true)
        startHeatBeat()
        if let block  = beWaitedRequests[RequestType.login] {
            block()
        }else if let block = beWaitedRequests[RequestType.reconnect]{
            block()
        }else if let block = beWaitedRequests[RequestType.loginWithToken]{
            block()
        }
        beWaitedRequests[RequestType.login] = nil
        beWaitedRequests[RequestType.reconnect] = nil
        beWaitedRequests[RequestType.loginWithToken] = nil
        
    }
    
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        print(#function)
        print("error:\(err?.localizedDescription ?? "??" )")
        stopTimer()
        setConnected(connect: false)
        heartBeat?.setBeat(num: 999)
    }
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        response.append(other: data)
        read(tag: 0)
    }
    
    
    /// 打印十六进制,可以删除
    ///
    /// - Parameter data: 数据
    func printData(data:Data){
        var array = Array(repeating: UInt8(0), count: data.count)
        data.copyBytes(to: &array, count: data.count)
        for  a in array{
            print(String(format: "%02x ", a),terminator:"");
        }
    }
}



// MARK: - 计时器
extension NetWorking{
    func startHeatBeat(){
        heartBeat = Heartbeat()
        heartBeat!.startTimer(block: {[weak self] in
            self?.sendHeartBeat()
        }){ [weak self] in
            self?.setConnected(connect: false)
            self?.client.disconnect()
        }
    }
    
    func stopTimer(){
        heartBeat?.stopTimer()
    }
    
    func sendHeartBeat(){
        if isConnected{
            let data = request.heartbeatData()
            client.write(data, withTimeout: -1, tag: 1)
        }
    }
    
    
    func setConnected(connect:Bool){
        objc_sync_enter(self)
        isConnected = connect
        objc_sync_exit(self)
        if connect{
            NotificationCenter.default.post(name: NSNotification.Name.netConnect, object: nil)
        }else{
            NotificationCenter.default.post(name: NSNotification.Name.netDisconnect, object: nil)
        }
        
    }
    
}

// MARK: - 请求的方法
extension NetWorking{
    
    
    ///  执行block,如果发现是断线状态就先重连再执行.
    ///
    /// - Parameters:
    ///   - id: 用户ID
    ///   - block: 执行块
    //    func executeOrReconnect(id:Int,type:RequestType,block:@escaping (()->())){
    //        if client.isConnected && Heartbeat.share.isLive {
    //            block()
    //        }else{
    //            beWaitedRequests[type] = block
    //            reconnect(id: id)
    //        }
    //    }
    
    private func p_executeOrConnect(type:RequestType,block:@escaping ()->()){
        if client.isConnected && heartBeat!.isLive {
            block()
        }else{
            beWaitedRequests[type] = block
            connect()
        }
    }
    
    /// 执行block,如果发现是断线状态就先用token重连再执行
    ///
    /// - Parameters:
    ///   - token: token description
    ///   - type: type description
    ///   - block: block description
    func executeOrLogin(with token:String,type:RequestType,block:@escaping (()->())){
        if client.isConnected && heartBeat!.isLive {
            block()
        }else{
            beWaitedRequests[type] = block
            login(token: token)
        }
    }
    
    
    /// 执行所有正在等待的请求除了登录和重连请求,并清空
    func executeAllBeWaitedBlock(){
        for (key,block) in beWaitedRequests{
            switch key {
            case .login,.reconnect,.loginWithToken:
                break
            default:
                print(key)
                block()
            }
        }
        beWaitedRequests.removeAll()
    }
    
    
    /// 登录
    ///
    /// - Parameters:
    ///   - name: 名字
    ///   - pwd: 密码
    ///   - type: 类型
    func login(name:String,pwd:String,type:String = "0"){
        let block = {[unowned self] in
            let data = self.request.login(name: name, pwd: pwd, type: type)
            self.client.write(data, withTimeout: 40, tag: 0)
            self.read(tag: 0)
        }
        
        p_executeOrConnect(type: RequestType.login, block: block)
    }
    
    func login(token:String){
        let block = {[unowned self] in
            let data = self.request.login(token: token)
            self.client.write(data, withTimeout: 40, tag: 0)
            self.read(tag: 0)
        }
        p_executeOrConnect(type: .loginWithToken, block: block)
    }
    
    /// 重连
    ///
    /// - Parameters:
    ///   - id: 用记ID
    ///   - type: 类型
    func reconnect(id:Int){
        let block = {[unowned self] in
            let data = self.request.reconnect(id: id)
            self.client.write(data, withTimeout: 40, tag: 0)
            self.read(tag: 0)
        }
        p_executeOrConnect(type: .reconnect, block: block)
    }
    
    
    /// 获取车辆列表(目前没有这个的单独接口,先使用登录接口来获取车辆的初始GPS数据)
    ///
    /// - Parameters:
    ///   - name: 用户句
    ///   - pwd: 密码
    func fetchCarList(name:String,pwd:String){
        guard !client.isConnected || !heartBeat!.isLive else{
            return
        }
        login(name: name, pwd: pwd)
    }
    
    
    /// 订阅指定车的GPS
    ///
    /// - Parameters:
    ///   - token: token description
    ///   - carIDList: carIDList description
    func subscribeForGPS(token:String,carIDList:[Int]){
        guard carIDList.count > 0 else {
            return
        }
        let block = { [unowned self] in
            let data = self.request.subscribeForGPS(token: token, carIDList: carIDList)
            
            self.client.write(data, withTimeout: 40, tag: 0)
            self.read(tag: 0)
        }
        executeOrLogin(with: token, type: .subscribeForGPS, block: block)
    }
    
    func cancelSubscribeForGPS(token:String,carIDList:[Int]){
        guard carIDList.count > 0 else {
            return
        }
        let block = { [unowned self] in
            let data = self.request.cancelSubscribeForGPS(token: token, carIDList: carIDList)
            self.client.write(data, withTimeout: 40, tag: 0)
            self.read(tag: 0)
        }
        executeOrLogin(with: token, type: .subscribeForGPS, block: block)
    }
    
    /// 获取视听流的IP地址
    ///
    /// - Parameters:
    ///   - token: token description
    ///   - carID: carID description
    ///   - channelID: channelID description
    ///   - streamType: streamType description
    func fetchAudiovisualIP(token:String,carID:UInt32,channelID:UInt8,streamType:AudiovisualStreamType){
        let block = { [unowned self] in
            let data = self.request.fetchAudiovisualAddress(carID: carID, channelID: channelID, StreamType: streamType)
            self.client.write(data, withTimeout: 40, tag: 0)
            self.read(tag: 0)
        }
        executeOrLogin(with: token, type: .audiovisual, block: block)
    }
}

extension Notification.Name{
    /// 登录
    static let Login:Notification.Name = Notification.Name(rawValue:"wuxia.login.NotificationName")
    /// 用token登录
    static let LoginWithToken:Notification.Name = Notification.Name(rawValue:"wuxia.loginWithToken.NotificationName")
    /// 重连
    static let reconnect:Notification.Name = Notification.Name(rawValue: "wuxia.reconnect.Notification")
    /// 网络断开连接
    static let netDisconnect:Notification.Name = Notification.Name(rawValue: "wuxia.netDisconnect.Notification")
    /// 网络连接
    static let netConnect:Notification.Name = Notification.Name(rawValue: "wuxia.netConnect.Notification")
    /// 需要重新登录
    static let needLogin:Notification.Name = Notification.Name(rawValue: "wuxia.needLogin.Notification")
    /// 需要重新登录
    static let GPS:Notification.Name = Notification.Name(rawValue: "wuxia.GPS.Notification")
}



