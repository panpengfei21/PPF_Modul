//
//  String+Extension.swift
//  MD5
//
//  Created by 潘鹏飞 on 16/10/5.
//  Copyright © 2016年 panpengfei. All rights reserved.
//

// 在 <工程名>-Bridging-Header.h 里加以下库
// #import <CommonCrypto/CommonDigest.h>

import Foundation


extension String{
    
    /// md5加密
    ///
    /// - returns: 加密后的字符串
    func md5() -> String{
        let cStr = (self as NSString).utf8String
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 16)
        CC_MD5(cStr, (CC_LONG)(strlen(cStr!)), buffer)
        
        var md5String = ""
        
        for i in 0 ..< 16{
            md5String = md5String.appendingFormat("%02X", buffer[i])
        }
        free(buffer)
        return md5String
    }
}
