//
//  Assets_Share.swift
//  YanXiuWang
//
//  Created by Liuming Qiu on 16/3/31.
//  Copyright © 2016年 ZW. All rights reserved.
//  资源的访问,相册

import AssetsLibrary

class Assets_Share: NSObject {
    /// 单例
    static let share = Assets_Share()
    private override init() {
        super.init()
    }
    
    /// ALAssetsLibrary
    let library = ALAssetsLibrary()
    /// 资源组
    var groups:[ALAssetsGroup]?
    
    /// 被选择的资源
    private var _selectedAssets:[ALAsset]?
    
    var selectedAssets:[ALAsset] {
        get{
            if _selectedAssets == nil{
                _selectedAssets = []
            }
            return _selectedAssets!
        }
        set{
            if _selectedAssets == nil{
                _selectedAssets = []
            }
            _selectedAssets = newValue
        }
    }
    
    // MARK: - 访问相册
    /**
    访问照片库
    
    - parameter completioin: 访问完成
    - parameter errorHandle: 访问出错
    */
    func accessPhotoAlbum(completioin:((assetsGroups:[ALAssetsGroup]?)->())?,errorHandle:((errorMessage:String)->())?){
        let failureBlock:ALAssetsLibraryAccessFailureBlock = {(error:NSError!) in
            
            var errorMessage = ""
            switch error.code{
            case ALAssetsLibraryAccessGloballyDeniedError:
                fallthrough
            case ALAssetsLibraryAccessUserDeniedError:
                errorMessage = "您拒绝访问相册"
            default:
                errorMessage = "未知原因,不能访问相册"
            }
            
            errorHandle?(errorMessage: errorMessage)
        }
        
        let listGroupBlock:ALAssetsLibraryGroupsEnumerationResultsBlock = {[unowned self](group:ALAssetsGroup!, stop:UnsafeMutablePointer<ObjCBool>) in
            guard group != nil else{
                completioin?(assetsGroups: self.groups)
                return
            }
            self.groups = []

            let onlyphotosFilter = ALAssetsFilter.allPhotos()
            group.setAssetsFilter(onlyphotosFilter)
            if group.numberOfAssets() > 0 {
                self.groups?.append(group)
            }
        }
        
        let groupTypes = ALAssetsGroupAlbum | ALAssetsGroupEvent | ALAssetsGroupFaces | ALAssetsGroupSavedPhotos;
        self.library.enumerateGroupsWithTypes(groupTypes, usingBlock: listGroupBlock, failureBlock: failureBlock)
    }
    
    
    /**
     返回一个资源组里的全部资源
     
     - parameter group: 资源组
     
     - returns: 全部资源
     */
    func assestsOfGroup(group:ALAssetsGroup) -> [ALAsset]{
        let onlyPhotosFilter = ALAssetsFilter.allPhotos()
        group.setAssetsFilter(onlyPhotosFilter)
        var assets = [ALAsset]()
        
        group.enumerateAssetsUsingBlock {(result, index, stop) in
            if let r = result{
                assets.append(r)
            }
        }
        return assets
    }
    
    /**
     还原单例
     */
    func restoreAssets_Share(){
        groups = nil
        _selectedAssets = nil
    }

    /**
     保存图片
     
     - parameter image:        要保存的图片
     - parameter resultBlock:  保存成功成调用
     - parameter failureBlock: 保存失败时调用
     */
    func saveImageToAlbum(image:UIImage,
                          resultBlock: ALAssetsLibraryAssetForURLResultBlock!,
                          failureBlock: ALAssetsLibraryAccessFailureBlock!) {
        let orientation = ALAssetOrientation(rawValue: image.imageOrientation.rawValue)
        library.writeImageToSavedPhotosAlbum(image.CGImage, orientation: orientation!) { [unowned self](url:NSURL!, error:NSError!) in
            if error != nil{
                failureBlock(error)
            }else{
                self.library.assetForURL(url, resultBlock: resultBlock, failureBlock: failureBlock)
            }
        }
    }
    
}
