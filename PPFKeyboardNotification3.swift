//
//  PPFKeyboardNotification.swift
//  wzer
//
//  Created by Liuming Qiu on 15/12/29.
//  Copyright © 2015年 ZYXiao_. All rights reserved.
//

import UIKit

protocol PPFKeyboardNotification_delegate:class{
    /**
     键盘将要出现
     
     - parameter modul:           模型的类
     - parameter rect:            键盘的框架尺寸
     - parameter duration:        键盘出现的动画时间
     - parameter animationOption: 键盘出现的动画选项
     */
    func keyboardWillShowWithModul(modul:PPFKeyboardNotification, rect:CGRect,duration:Double,animationOption:UIViewAnimationOptions)
    
    /**
     键盘将要消失
     
     - parameter modul:           模型的类
     - parameter rect:            键盘的框架尺寸
     - parameter duration:        键盘消失的动画时间
     - parameter animationOption: 键盘消失的动画选项
     */
    func keyboardWillHideWithModul(modul:PPFKeyboardNotification,rect:CGRect,duration:Double,animationOption:UIViewAnimationOptions)
}

class PPFKeyboardNotification: NSObject {
    // MARK: stored propertices
    ///单例
    static let share:PPFKeyboardNotification = PPFKeyboardNotification()
    
    ///代理
    weak var delegate:PPFKeyboardNotification_delegate?
    
    // MARK: life cycle
    private override init() {
        super.init()
    }
    
    // MARK: 数据处理
    ///加观察器
    func addObserver(){
        NotificationCenter.default.addObserver(self, selector: #selector(PPFKeyboardNotification.keyboardWillShow(noti:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PPFKeyboardNotification.keyboardWillHide(noti:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    /// 去除观察器
    func removeObserver(){
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func keyboardWillShow(noti:NSNotification){
        //取keyboard的frame
        if let kbFrame = noti.userInfo?[UIKeyboardFrameEndUserInfoKey] as? CGRect{
            //keyboard 的动画时间
            if let duration = noti.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? Double{
                // keyboard 的动画选项
                if let curveOption = noti.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as? UInt{
                    delegate?.keyboardWillShowWithModul(modul: self, rect: kbFrame, duration: duration, animationOption: UIViewAnimationOptions(rawValue: curveOption))
                }
            }
        }
    }
    
    func keyboardWillHide(noti:NSNotification){
        //取keyboard的frame
        if let kbFrame = noti.userInfo?[UIKeyboardFrameEndUserInfoKey] as? CGRect{
            //keyboard 的动画时间
            if let duration = noti.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? Double{
                // keyboard 的动画选项
                if let curveOption = noti.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as? UInt{
                    delegate?.keyboardWillHideWithModul(modul: self, rect: kbFrame, duration: duration, animationOption: UIViewAnimationOptions(rawValue: curveOption))
                }
            }
        }
    }
}






