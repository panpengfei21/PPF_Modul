//
//  VTeNetDataBase.swift
//  VideoTest
//
//  Created by asdasd on 2017/8/8.
//  Copyright © 2017年 WuXia. All rights reserved.
//

import UIKit

class VTeNetDataBase: NSObject {
    /// 信息头,有这个就说明是一段新的信令
    let signallingHead:UInt32 = 0x9f9e9d9c
    /// 包头部的长度
    let contentHeadLength = 14
}
