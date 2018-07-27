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


// MARK: - md5加密扩展
extension String{
    /// md5加密返回32位小写的字符
    ///
    /// - Returns: 字符串
    func md5ForLower32Char() -> String {
        guard let cStr = (self as NSString).utf8String else {
            fatalError("无法找到UTF8元数据地址")
        }
        //分配内存,用来保存结果.
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(CC_MD5_DIGEST_LENGTH))
        
        CC_MD5(cStr, CC_LONG(strlen(cStr)), buffer)
        
        var res = "";
        for i in 0 ..< Int(CC_MD5_DIGEST_LENGTH){
            res = res.appendingFormat("%02x", buffer[i])
        }
        //释放内存
        free(buffer)
        return res;
    }
    
    
    /// md5加密返回16位小写字符
    ///
    /// - Returns: 符串
    func md5ForLower16Char() -> String {
        let res = self.md5ForLower32Char()
        let start = res.index(res.startIndex, offsetBy: 8)
        let end = res.index(res.startIndex, offsetBy: 24)
    
        return String(res[start ..< end])
    }
}
