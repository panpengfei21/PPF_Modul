//
//  TakePhotoWithCamera.swift
//  Test20150606
//
//  Created by 潘鹏飞 on 15/6/6.
//  Copyright (c) 2015年 panpengfei. All rights reserved.
//

import Foundation
import MobileCoreServices

// MARK:UIImagePickerControllerDelegate

//UINavigationControllerDelegate,UIImagePickerControllerDelegate
var picker = UIImagePickerController()
//这里能否拍照,如果可以选择类型
func cameraCanBeUsed(inout ipc:UIImagePickerController,mediaType:CFString,sourceType:UIImagePickerControllerSourceType) -> Bool{
    if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) || UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary){
        if let availableTypes = UIImagePickerController.availableMediaTypesForSourceType(.Camera){
            if (availableTypes as NSArray).containsObject(mediaType){
                ipc.sourceType = sourceType
                ipc.delegate = self
                ipc.mediaTypes = [mediaType]
                ipc.allowsEditing = true
                ipc.videoQuality = UIImagePickerControllerQualityType.TypeMedium
                return true
            }
        }
    }
    return false
}


//点击退出
func imagePickerControllerDidCancel(picker: UIImagePickerController) {
    presentedViewController?.dismissViewControllerAnimated(true, completion: nil)
}
//在这里获取照片
func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
    //        UIImagePickerControllerMediaType              kUTTypeImage or kUTTypeMovie
    //        UIImagePickerControllerOriginalImage          UIImage
    //        UIImagePickerControllerEditedImage            UIImage
    //        UIImagePickerControllerCropRect               CGRect (in an NSValue)
    //        UIImagePickerControllerMediaMetadata          Dictionaryinfoabouttheimage
    //        UIImagePickerControllerMediaURL               NSURL edited video
    //        UIImagePickerControllerReferenceURL           NSURL original (unedited) video
    if let editImage = info[UIImagePickerControllerEditedImage] as? UIImage{
        //TODO:编辑过的照片
    }else if let originImage = info[UIImagePickerControllerOriginalImage] as? UIImage{
        //TODO:原照片
    }
    presentedViewController?.dismissViewControllerAnimated(true, completion: nil)
}


//示例
//@IBAction func camera(sender: AnyObject) {
//    if cameraCanBeUsed(&picker, mediaType: kUTTypeImage, sourceType: UIImagePickerControllerSourceType.Camera){
//        self.presentViewController(picker, animated: true, completion: nil)
//    }
//}
//
//@IBAction func library(sender: AnyObject) {
//    if cameraCanBeUsed(&picker, mediaType: kUTTypeImage, sourceType: UIImagePickerControllerSourceType.SavedPhotosAlbum){
//        self.presentViewController(picker, animated: true, completion: nil)
//    }
//    
//}

