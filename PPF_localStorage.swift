//
//  PPF_localStorage.swift
//  YanXiuWang
//
//  Created by Liuming Qiu on 16/4/11.
//  Copyright © 2016年 ZW. All rights reserved.
//  APP 沙盒的操作

import UIKit

class PPF_localStorage: NSObject {
    // MARK: - 初始化
    private override init() {
        home = NSHomeDirectory()
        
        documents = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true).first!
        library = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.LibraryDirectory, NSSearchPathDomainMask.UserDomainMask, true).first!
        
        tmp = NSTemporaryDirectory()
        
        caches = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true).first!
        preferences = library.stringByAppendingString("/Preferences")
        super.init()
    }
    
    /**
     可以删除
     */
    func pri() {
        print("documents:\(documents)")
        print("cache:\(caches)")
    }
   
    // MARK: - property
    /// 单例
    static let share = PPF_localStorage()
    
    /// 文件管理器
    let fileManager = NSFileManager.defaultManager()
    
    /// 主目录 包抱 Documents,Library,tmp三个子目录
    let home:String
 
    ///Documents:最常用的目录，iTunes同步该应用时会同步此文件夹中的内容，适合存储重要数据
    let documents:String
    
    let library:String
    
     /// 保存应用运行时所需的临时数据,使用完毕后再将相应的文件从该目录删除。应用没有运行时，系统也可能会清除该目录下的文件。iTunes同步设备时不会备份该目录.
    let tmp:String
    
     /// 保存应用所有的偏好设置,iOS的Settings(设置)应用会在该目录中查找应用的设置信息,iTunes同步设备时会备份该目录,不能手动增加偏好
    let preferences:String
    
    /// 保存应用运行时所生成的需要持久化的数据 iTunes同步设备时不会备份 一般存储体积大、不需要备份非重要数据,(可以清空的,清空缓存指的就是这个)
    let caches:String

    
    /**
     生成唯一的字符串
     
     - returns: 字符串
     */
    func createUniqueString() -> String {
        let date = NSDate(timeIntervalSince1970: 0)
        return "\(Int(date.timeIntervalSince1970))"
    }
    
    /**
     删除文件
     
     - parameter path: 文件路径
     
     - returns: 删除成功:true  失败:false
     */
    func deleteFile(path:String) -> Bool {
        let fileManager = NSFileManager.defaultManager()
        if fileManager.fileExistsAtPath(path){
            do{
                try fileManager.removeItemAtPath(path)
                return true
            }catch let error as NSError{
                print("delete file error:\(error)")
                return false
            }
        }else{
            return true
        }
    }
    
    /**
     文件是否存在
     
     - parameter path: 文件路径
     
     - returns: 存在:true  不存在:false
     */
    func fileExistsAtPath(path:String) -> Bool {
        let fileManager = NSFileManager.defaultManager()
        return fileManager.fileExistsAtPath(path)
    }
}

// MARK: - 文件夹的增,查,删
extension PPF_localStorage{
    // MARK: - 增加文件夹
    /**
     创建文件夹
     
     - parameter path: 父目录
     - parameter name: 文件夹的名称
     
     - returns: 创建是否成功
     */
    func createFolderWithPath(path:String,withName name:String) -> Bool {
        guard !name.isEmpty else{
            print("name 是空的")
            return false
        }
        let fullPath = path.stringByAppendingString("/\(name)")
        do{
            try fileManager.createDirectoryAtPath(fullPath, withIntermediateDirectories: true, attributes: nil)
            return true
        }catch let error as NSError{
            print("createFolderInPath false error:\(error)")
            return false
        }
    }
    
    /**
     在 documents 里创建文件夹
     
     - parameter folderName: 文件夹的名字
     
     - returns: 创建是否成功
     */
    func createFolderInDocuments(folderName:String) -> Bool {
        return createFolderWithPath(documents, withName: folderName)
    }
    
    /**
     在 Caches 里创建文件夹
     
     - parameter folderName: 文件夹的名字
     
     - returns: 创建是否成功
     */
    func createFolderInCaches(folderName:String) -> Bool {
        return createFolderWithPath(caches, withName: folderName)
    }
    
    // MARK: - 删除文件夹
    /**
     删除一个文件
     
     - parameter path: 文件路径
     
     - returns: 删除是否成功
     */
    func deleteFileAtPath(path:String) -> Bool {
        do{
            try fileManager.removeItemAtPath(path)
            return true
        }catch let error as NSError{
            print("remove folder path failed:\(error)")
            return false
        }
        
    }
    
    /**
     删除一个文件夹下的全部文件
     
     - parameter path: 文件夹
     */
    func deleteItemInDirectory(path:String) {
        guard !path.isEmpty else{
            return
        }
        
        do {
            let a = try fileManager.subpathsOfDirectoryAtPath(path)
            for i in a {
                let subPath = path.stringByAppendingString("/\(i)")
                deleteFile(subPath)
            }
        }catch let error as NSError{
            print(error)
        }
    }
    
    
    // MARK: - 查
    /**
     文件夹是否存在,同名的文件也不行,一定要是文件夹(目录)
     
     - parameter path: 文件夹路径
     
     - returns: 文件夹是否存在
     */
    func folderExistsAtPath(path:String) -> Bool {
        var isDir = ObjCBool(false)
        let e = fileManager.fileExistsAtPath(path, isDirectory: &isDir)
        return e && isDir
    }
}
















