//
//  PPFKeyboardNotification.swift
//  wzer
//
//  Created by Liuming Qiu on 15/12/29.
//  Copyright © 2015年 ZYXiao_. All rights reserved.
//

import UIKit

@objc protocol PPFKeyboardNotification_delegate{
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
    
    ///键盘是否正在显示. true:显示   false:隐藏
    var isKeyboardShow = false
    ///代理
    var delegate:PPFKeyboardNotification_delegate?
    
    // MARK: life cycle
    private override init() {
        super.init()
    }
    
    // MARK: 数据处理
    ///加观察器
    func addObserver(){
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PPFKeyboardNotification.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PPFKeyboardNotification.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
    }
    /// 去除观察器
    func removeObserver(){
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardWillShow(noti:NSNotification){
        if !isKeyboardShow{
            //取keyboard的frame
            if let kbFrame = noti.userInfo?[UIKeyboardFrameEndUserInfoKey]?.CGRectValue{
                //keyboard 的动画时间
                if let duration = noti.userInfo?[UIKeyboardAnimationDurationUserInfoKey]?.doubleValue{
                    // keyboard 的动画选项
                    if let curveOption = noti.userInfo?[UIKeyboardAnimationCurveUserInfoKey]?.unsignedIntegerValue{
                        isKeyboardShow = true
                        delegate?.keyboardWillShowWithModul(self, rect: kbFrame, duration: duration, animationOption: UIViewAnimationOptions(rawValue: curveOption))
                    }
                }
            }
        }
    }
    func keyboardWillHide(noti:NSNotification){
        if isKeyboardShow{
            //取keyboard的frame
            if let kbFrame = noti.userInfo?[UIKeyboardFrameEndUserInfoKey]?.CGRectValue{
                //keyboard 的动画时间
                if let duration = noti.userInfo?[UIKeyboardAnimationDurationUserInfoKey]?.doubleValue{
                    // keyboard 的动画选项
                    if let curveOption = noti.userInfo?[UIKeyboardAnimationCurveUserInfoKey]?.unsignedIntegerValue{
                        isKeyboardShow = false
                        delegate?.keyboardWillHideWithModul(self, rect: kbFrame, duration: duration, animationOption: UIViewAnimationOptions(rawValue: curveOption))
                    }
                }
            }
        }
    }
}






