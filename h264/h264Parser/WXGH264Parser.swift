//
//  WXGH264Parser.swift
//  WuXiaGPS
//
//  Created by asdasd on 2017/8/10.
//  Copyright © 2017年 WuXia. All rights reserved.
//

import UIKit


///H264类型
enum H264Type:UInt8 {
    case SLICE = 1
    case DPA
    case DPB
    case DPC
    case IDR
    case SEI
    case SPS
    case PPS
    case AUD
    case EOSEQ
    case EOSTREAM
    case FILL
}


class WXGH264:NSObject {
    let data:Data
    let type:H264Type
    var length:Int {
        return data.count
    }
    
    init?(data:Data){
        guard data.count > 1 else{
            return nil
        }
        
        var first = data[0]
        first &= 0x1f
        guard let type = H264Type(rawValue: first) else{
            return nil
        }
        
        self.type = type
        self.data = data
        super.init()
    }
}


class WXGH264Parser: NSObject {

    let queue:DispatchQueue!
    
    var data:Data?
    
    /// h264的头1 0x00000001
    fileprivate let head4:[UInt8] = [0x00,0x00,0x00,0x01]
    /// h264的头2 0x000001
    fileprivate let head3:[UInt8] = [0x00,0x00,0x01]
    
    override init() {
        queue = DispatchQueue(label: "wuxia.video.h264parser")
        super.init()
    }
    
    
//    /// 增加数据,并返回切过的带有h264头的数据数组
//    ///
//    /// - Parameter otherData: 要接上的数据
//    /// - Returns: return value description
//    func append(otherData:Data) -> [Data] {
//        
//        if self.data == nil {
//            self.data = Data()
//        }
//        
//        self.data!.append(otherData)
//        
//        guard self.data!.count >= 3 else{
//            return []
//        }
//        
//        /// 头在data里的位置列表
//        var headLocationList = [Int]()
//        /// 头的长度列表
//        var headLengthList   = [Int]()
//        
//        var subData = self.data!
//        
//        let block = { (location:Int,length:Int) in
//            headLocationList.append(location)
//            headLengthList.append(length)
//        }
//        
//        while true {
//            if (headLocationList.last ?? 0) + 3 >= self.data!.count {
//                print((headLocationList.last ?? 0) + 3)
//                print(self.data!.count)
//            }
//            let head4Range = p_headLocation(subData, head: head4,in: (headLocationList.last ?? 0) + 3 ..< self.data!.count )
//            let head3Range = p_headLocation(subData, head: head3,in: (headLocationList.last ?? 0) + 3 ..< self.data!.count)
//            if let head4Range = head4Range,
//                let head3Range = head3Range {//找到两个头
//                if head4Range.lowerBound < head3Range.lowerBound {
//                    block(head4Range.lowerBound, head4.count)
//                }else{
//                    block(head3Range.lowerBound,head3.count)
//                }
//            }else if let head4Range = head4Range {//只找到head4,注:不可能,因为head4本身就包含了head3
//                block(head4Range.lowerBound, head4.count)
//            }else if let head3Range = head3Range {//只找到head3
//                block(head3Range.lowerBound,head3.count)
//            }else{//没有找到头
//                break
//            }
//        }
//        
//        subData = self.data!
//        var resultsData = [Data]()
//        if headLocationList.count == 1 {//如果只找到一个,把没用的数据去掉(不带h264头的)
//            self.data = subData.subdata(in: headLocationList.last! ..< subData.count)
//        }else if headLocationList.count > 1{
//            
//            for i in 0 ..< headLocationList.count - 1 {
//                let sd = subData.subdata(in: headLocationList[i] ..< headLocationList[i + 1])
//                resultsData.append(sd)
//            }
//            self.data = subData.subdata(in: headLocationList.last! ..< subData.count)
//        }
//        
//        return resultsData
//    }

    /// 增加数据,并返回切过的带有h264头的数据数组
    ///
    /// - Parameter otherData: 要接上的数据
    /// - Returns: return value description
    func append(otherData:Data,completeBlock:@escaping (_ datas:[Data]) -> ()) {
        
        queue.async {[unowned self] in
            if self.data == nil {
                self.data = Data()
            }
            
            self.data!.append(otherData)
            
            guard self.data!.count >= 3 else{
                completeBlock([])
                return
            }
            
            /// 头在data里的位置列表
            var headLocationList = [Int]()
            /// 头的长度列表
            var headLengthList   = [Int]()
            
            var subData = self.data!
            
            let block = { (location:Int,length:Int) in
                headLocationList.append(location)
                headLengthList.append(length)
            }
            
            while true {
                if (headLocationList.last ?? 0) + 3 >= self.data!.count {
                    print((headLocationList.last ?? 0) + 3)
                    print(self.data!.count)
                }
                let head4Range = self.p_headLocation(subData, head: self.head4,in: (headLocationList.last ?? -3) + 3 ..< self.data!.count )
                let head3Range = self.p_headLocation(subData, head: self.head3,in: (headLocationList.last ?? -3) + 3 ..< self.data!.count)
                if let head4Range = head4Range,
                    let head3Range = head3Range {//找到两个头
                    if head4Range.lowerBound < head3Range.lowerBound {
                        block(head4Range.lowerBound, self.head4.count)
                    }else{
                        block(head3Range.lowerBound,self.head3.count)
                    }
                }else if let head4Range = head4Range {//只找到head4,注:不可能,因为head4本身就包含了head3
                    block(head4Range.lowerBound, self.head4.count)
                }else if let head3Range = head3Range {//只找到head3
                    block(head3Range.lowerBound,self.head3.count)
                }else{//没有找到头
                    break
                }
            }
            
            var resultsData = [Data]()
            if headLocationList.count == 1 && headLocationList.first != 0{//如果只找到一个,把没用的数据去掉(不带h264头的)
                self.data = subData.subdata(in: headLocationList.first! ..< subData.count)
            }else if headLocationList.count > 1{
                for i in 0 ..< headLocationList.count - 1 {
                    let sd = subData.subdata(in: headLocationList[i] ..< headLocationList[i + 1])
                    resultsData.append(sd)
                }
                self.data = subData.subdata(in: headLocationList.last! ..< subData.count)
            }
            
            
            completeBlock(resultsData)
        }
    }
}

extension WXGH264Parser{

    /// 找出head在data里的位置
    ///
    /// - Parameters:
    ///   - data: data description
    ///   - head: 头
    /// - Returns: return value description
    fileprivate func p_headLocation(_ data:Data,head:[UInt8],in range:Range<Int>? = nil) -> Range<Int>? {
        let headData = Data(bytes: head, count: head.count)
        return data.range(of: headData, in: range)
    }
}

extension WXGH264Parser {
//    func append1(otherData:Data) -> [WXGH264] {
//        let datas = append(otherData: otherData)
//        let results = datas.flatMap(){ (data) -> WXGH264? in
//            var headLength:Int
//            if let _ = self.p_headLocation(data, head: self.head4, in: 0 ..< self.head4.count){
//                headLength = 4
//            }else if let _ = self.p_headLocation(data, head: self.head3, in: 0 ..< self.head3.count) {
//                headLength = 3
//            }else{
//                return nil
//            }
//            let subData = data.subdata(in: headLength ..< data.count)
//            
//            return WXGH264(data: subData)
//            
//        }
//        
//        return results
//    }
    func append1(otherData:Data,completeBlock:@escaping ([WXGH264]) ->()) {
        
        append(otherData: otherData) { (datas:[Data]) in
            
            let results = datas.flatMap(){ (data) -> WXGH264? in
                var headLength:Int
                if let _ = self.p_headLocation(data, head: self.head4, in: 0 ..< self.head4.count){
                    headLength = 4
                }else if let _ = self.p_headLocation(data, head: self.head3, in: 0 ..< self.head3.count) {
                    headLength = 3
                }else{
                    return nil
                }
                let subData = data.subdata(in: headLength ..< data.count)
                
                return WXGH264(data: subData)
            }
            completeBlock(results)
        }
    }
}
