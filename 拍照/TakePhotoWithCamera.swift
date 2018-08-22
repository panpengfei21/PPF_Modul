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




var picker = UIImagePickerController()

// _________________以下swift 3.0__________________

//这里能否拍照,如果可以选择类型
func cameraCanBeUsed( ipc:inout UIImagePickerController,mediaType:CFString,sourceType:UIImagePickerControllerSourceType) -> Bool{
    if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) || UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary){
        if let availableTypes = UIImagePickerController.availableMediaTypes(for: .camera){
            if (availableTypes as NSArray).contains(mediaType){
                ipc.sourceType = sourceType
                ipc.delegate = self
                ipc.mediaTypes = [mediaType as String]
                ipc.allowsEditing = true
                ipc.videoQuality = UIImagePickerControllerQualityType.typeMedium
                return true
            }
        }
    }
    return false
}


//点击退出
func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    presentedViewController?.dismiss(animated: true, completion: nil)
}

//在这里获取照片
func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
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
    presentedViewController?.dismiss(animated: true, completion: nil)
}

// _________________以下swift 4.0__________________

//这里能否拍照,如果可以选择类型
func cameraCanBeUsed( ipc:inout UIImagePickerController,mediaType:CFString,sourceType:UIImagePickerControllerSourceType) -> Bool{
    if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) || UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary){
        if let availableTypes = UIImagePickerController.availableMediaTypes(for: .camera){
            if (availableTypes as NSArray).contains(mediaType){
                ipc.sourceType = sourceType
                ipc.delegate = self
                ipc.mediaTypes = [mediaType as String]
                ipc.allowsEditing = true
                ipc.videoQuality = UIImagePickerControllerQualityType.typeMedium
                return true
            }
        }
    }
    return false
}

//点击退出
func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    presentedViewController?.dismiss(animated: true, completion: nil)
}
func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    if let editImage = info[UIImagePickerControllerEditedImage] as? UIImage {
        
    }else if let originImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
        
    }
    presentedViewController?.dismiss(animated: true, completion: nil)
}

