//
//  FlyNetWorking.swift
//  HumanFaceRecognition
//
//  Created by Liuming Qiu on 2017/3/30.
//  Copyright © 2017年 ZW. All rights reserved.
//

import UIKit
import AFNetworking

enum FaceAttribute:String{
    case gender = "gender"
    case age    = "age"
    case smiling = "smiling"
    case headpose = "headpose"
    ///人脸质量判断结果，value值为人脸的质量判断的分数，是一个浮点数，范围[0,100], 小数点后3位有效数字。threshold表示人脸质量基本合格的一个阈值，超过该阈值的人脸适合用于人脸比对。
    case facequality = "facequality"
    case blur = "blur"
    case eyestatus = "eyestatus"
    case ethnicity = "ethnicity"
}

/// 成功的手柄
typealias SuccessfulHandle = (Any,Int?)-> Void
/// 失败手柄
typealias FailureHandle = (String)->Void
typealias ProgressHandle = ((Progress) -> Void)

class FlyNetWorking: NSObject {
    let sessionManager:AFHTTPSessionManager
    
    fileprivate let api_key = "????"
    fileprivate let api_secret = "??????"
    
    /// 当请求失败时才会返回此字符串，具体返回内容见后续错误信息章节。否则此字段不存在。
    fileprivate let requestErrorKey = "error_message"
    
    static var share = FlyNetWorking()
    private override init(){
        let url = URL(string: "https://api-cn.faceplusplus.com/facepp/v3/")
        sessionManager = AFHTTPSessionManager(baseURL: url, sessionConfiguration: URLSessionConfiguration.ephemeral)
        sessionManager.responseSerializer = AFHTTPResponseSerializer()
        sessionManager.requestSerializer = AFHTTPRequestSerializer()

        super.init()
    }
}


// MARK: - 工具
extension FlyNetWorking{
    /// 生成发起请求的参数。
    ///
    /// - Parameters:
    ///   - name:人脸集合的名字，最长256个字符，不能包括字符^@,&=*'"
    ///   - outer_id: 账号下全局唯一的FaceSet自定义标识，可以用来管理FaceSet对象。最长255个字符，不能包括字符^@,&=*'"
    ///   - tags: FaceSet自定义标签组成的字符串，用来对FaceSet分组。最长255个字符，多个tag用逗号分隔，每个tag不能包括字符^@,&=*'"
    ///   - face_tokens: 人脸标识face_token，可以是一个或者多个，用逗号分隔。最多不超过5个face_token
    ///   - user_data: 自定义用户信息，不大于16KB，不能包括字符^@,&=*'"
    ///   - new_outer_id: 在api_key下全局唯一的FaceSet自定义标识，可以用来管理FaceSet对象。最长255个字符，不能包括字符^@,&=*'"
    ///   - force_merge: 在传入outer_id的情况下，如果outer_id已经存在，是否将face_token加入已经存在的FaceSet中
    ///   - faceset_token: FaceSet的标识
    //      0：不将face_tokens加入已存在的FaceSet中，直接返回FACESET_EXIST错误
    //      1：将face_tokens加入已存在的FaceSet中
    //      默认值为0
    //    - check_empty: 删除时是否检查FaceSet中是否存在face_token，默认值为1
    //                    0：不检查
    //                    1：检查
    //                    如果设置为1，当FaceSet中存在face_token则不能删除
    //    - start:  传入参数start，控制从第几个Faceset开始返回。返回的Faceset按照创建时间排序，每次返回1000个FaceSets。默认值为1。
    fileprivate func generatedParametersWith(display_name:String? = nil,outer_id:String? = nil,tags:String? = nil,face_tokens:String? = nil,user_data:String? = nil,force_merge:Int? = nil,faceset_token:String? = nil,new_outer_id:String? = nil,check_empty:Int? = nil,start:Int? = nil,return_attributes:[FaceAttribute]? = nil,face_token1:String? = nil,face_token2:String? = nil,face_token:String? = nil,return_result_count:Int? = nil) -> [String:Any]{
        var parameters:[String:Any] = ["api_key":api_key,"api_secret":api_secret]
        
        parameters["display_name"]  = display_name
        parameters["outer_id"]      = outer_id
        parameters["tags"]          = tags
        parameters["face_tokens"]   = face_tokens
        parameters["user_data"]     = user_data
        parameters["force_merge"]   = force_merge
        parameters["faceset_token"] = faceset_token
        parameters["new_outer_id"]  = new_outer_id
        parameters["start"]         = start
        parameters["face_token1"]   = face_token1
        parameters["face_token2"]   = face_token2
        parameters["face_token"]    = face_token
        parameters["return_result_count"] = return_result_count
        
        if let attri = return_attributes,!attri.isEmpty{
            let attriString = attri.flatMap(){return $0.rawValue}
            parameters["return_attributes"] = attriString.joined(separator: ",")
        }
        
        return parameters
    }
    
    
    

    
    /// 处理服务器返回的数据
    ///
    /// - Parameters:
    ///   - data: 数据
    ///   - success: 成功手柄
    ///   - failure: 失败手柄
    fileprivate func processData(data:Any?,success:SuccessfulHandle,failure:FailureHandle){
        guard let d = data as? Data else{
            return
        }
        do{
            guard let json = try JSONSerialization.jsonObject(with: d, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String:Any] else{
                failure("服务器返回的格式不是[String:Any]--PPF")
                return
            }
            
            if let errorMSG = json[requestErrorKey] as? String {
                failure(errorMSG)
            }else{
                success(json, nil)
            }
            
        }catch {
            failure(error.localizedDescription)
        }
    }
    
    fileprivate func POST(_ URLString: String, parameters: Any?,constructingBodyWith constructingBlock: ((AFMultipartFormData) -> Void)? = nil,progress:ProgressHandle? = nil, success:@escaping SuccessfulHandle, failure:@escaping FailureHandle){
        sessionManager.post(URLString, parameters: parameters, constructingBodyWith: constructingBlock, progress: progress, success: { (task:URLSessionDataTask, data:Any?) in
            self.processData(data: data, success: success, failure: failure)
        }) { (task:URLSessionDataTask?, error:Error) in
            failure(error.localizedDescription)
        }
        
    }
    
}


// MARK: - 请求
extension FlyNetWorking{
    
    // MARK: - face set
    
    /// 创建一个脸集合,一个FaceSet最多存储1,000个face_token。
    ///
    /// - Parameters:
    ///   - name: 人脸集合的名字，最长256个字符，不能包括字符^@,&=*'"
    ///   - outer_id: 账号下全局唯一的FaceSet自定义标识，可以用来管理FaceSet对象。最长255个字符，不能包括字符^@,&=*'"
    ///   - tags: FaceSet自定义标签组成的字符串，用来对FaceSet分组。最长255个字符，多个tag用逗号分隔，每个tag不能包括字符^@,&=*'"
    func faceset(create name:String?,outer_id:String?,tags:String?,success:@escaping SuccessfulHandle,failure:@escaping FailureHandle){
        let parameters = generatedParametersWith(display_name: name, outer_id: outer_id, tags: tags)
        POST("faceset/create", parameters: parameters, success: success, failure: failure)
    }
    
    
    /// faceSet里增加face_token
    ///
    /// - Parameters:
    ///   - token: FaceSet的标识
    ///   - faceTokens: 人脸标识face_token组成的字符串，可以是一个或者多个，用逗号分隔。最多不超过5个face_token
    ///   - success: success description
    ///   - failure: failure description
    func faceset(_ set:String,add faceTokens:String,success:@escaping SuccessfulHandle,failure:@escaping FailureHandle){
        let parameters = generatedParametersWith(face_tokens: faceTokens,faceset_token: set)
        POST("faceset/addface", parameters: parameters, success: success, failure: failure)
    }
    /// faceSet里移除face_token
    ///
    /// - Parameters:
    ///   - token: FaceSet的标识
    ///   - faceTokens: 人脸标识face_token组成的字符串，可以是一个或者多个，用逗号分隔。最多不超过5个face_token
    ///   - success: success description
    ///   - failure: failure description
    func faceset(_ set:String,remove faceTokens:String,success:@escaping SuccessfulHandle,failure:@escaping FailureHandle){
        let parameters = generatedParametersWith(face_tokens: faceTokens,faceset_token: set)
        POST("faceset/removeface", parameters: parameters, success: success, failure: failure)
    }
    
    
    /// 更新faceset信息
    ///
    /// - Parameters:
    ///   - token: faceset_token
    ///   - newOuterID: 在api_key下全局唯一的FaceSet自定义标识，可以用来管理FaceSet对象。最长255个字符，不能包括字符^@,&=*'"
    ///   - displayName: 人脸集合的名字，256个字符
    ///   - userData: 自定义用户信息，不大于16KB, 1KB=1024B 且不能包括字符^@,&=*'"
    ///   - tags: FaceSet自定义标签组成的字符串，用来对FaceSet分组。最长255个字符，多个tag用逗号分隔，每个tag不能包括字符^@,&=*'"
    ///   - success: success description
    ///   - failure: failure description
    func faceset(update setToken:String,newOuterID:String?,displayName:String?,userData:String?,tags:String?,success:@escaping SuccessfulHandle,failure:@escaping FailureHandle){
        guard newOuterID != nil || displayName != nil || userData != nil || tags != nil else{
            failure("无更新信息--PPF")
            return
        }
        let parameters = generatedParametersWith(display_name: displayName,tags: tags, user_data: userData, faceset_token:setToken, new_outer_id: newOuterID)
        POST("faceset/update", parameters: parameters, success: success, failure: failure)
        
    }
    
    
    /// 获取faceset的详细信息
    ///
    /// - Parameters:
    ///   - token: faceset token
    ///   - success: success description
    ///   - failure: failure description
    func faceset(getDetails token:String,success:@escaping SuccessfulHandle,failure:@escaping FailureHandle){
        let parameters = generatedParametersWith(faceset_token: token)
        POST("faceset/getdetail", parameters: parameters, success: success, failure: failure)
    }
    
    
    /// 删除一个faceset
    ///
    /// - Parameters:
    ///   - setToken: faceset token
    ///   - checkEmpty: 删除时是否检查FaceSet中是否存在face_token，默认值为1,如果设置为1，当FaceSet中存在face_token则不能删除
    ///   - success: success description
    ///   - failure: failure description
    func faceset(delete setToken:String,checkEmpty:Bool = true,success:@escaping SuccessfulHandle,failure:@escaping FailureHandle){
        let parameters = generatedParametersWith(faceset_token: setToken,check_empty:checkEmpty ? 1 : 0)
        POST("faceset/delete", parameters: parameters, success: success, failure: failure)
    }
    
    
    /// 获取有tags标识的facesets
    ///
    /// - Parameters:
    ///   - tags: tags description
    ///   - start: 传入参数start，控制从第几个Faceset开始返回。返回的Faceset按照创建时间排序，每次返回1000个FaceSets。默认值为1。
    ///   - success: success description
    ///   - failure: failure description
    func faceset(getFacesetsWithTags tags:String?,start:Int?,success:@escaping SuccessfulHandle,failure:@escaping FailureHandle){
        let parameters = generatedParametersWith(tags: tags,start: start)
        POST("faceset/getfacesets", parameters: parameters, success: success, failure: failure)
    }
    
    // MARK: 查找face
    
    /// 查找人脸。
    ///
    /// - Parameters:
    ///   - filePath: filePath description
    ///   - return_attributes: return_attributes description
    ///   - progress: progress description
    ///   - success: success description
    ///   - failure: failure description
    func detect(face filePath:String,return_attributes:[FaceAttribute] = [.facequality],progress:ProgressHandle?,success:@escaping SuccessfulHandle,failure:@escaping FailureHandle){
        let parameters = generatedParametersWith(return_attributes: return_attributes)
        POST("detect", parameters: parameters, constructingBodyWith: { (data:AFMultipartFormData) in
            let fileURL = URL(fileURLWithPath: filePath)
            guard fileURL.isFileURL else{
                return
            }            
            try? data.appendPart(withFileURL: fileURL, name: "image_file")
        }, progress: progress, success: success, failure: failure)
    }
    
    // MARK: 对比两张脸
    
    /// 对比两张人脸
    ///
    /// - Parameters:
    ///   - ft1: 脸1 face token
    ///   - ip1: 脸1 image path
    ///   - ft2: 脸2 face token
    ///   - ip2: 脸2 image path
    ///   - progress: progress description
    ///   - success: success description
    ///   - failure: failure description
    func compare(faceToken1 ft1:String?,orImagePath1 ip1:String?,andFaceToken2 ft2:String?,orImagePath2 ip2:String?,progress:ProgressHandle?,success:@escaping SuccessfulHandle,failure:@escaping FailureHandle){
        guard nil != ft1 || nil != ip1 else {
            failure("缺少第一张人脸--PPF")
            return
        }
        guard nil != ft2 || nil != ip2 else {
            failure("需要第二张人脸进行对比--PPF")
            return
        }
        
        let parameters = generatedParametersWith(face_token1: ft1, face_token2: ft2)
        POST("compare", parameters: parameters, constructingBodyWith: { (data) in
            if let path1 = ip1,ft1 == nil{
                let url = URL(fileURLWithPath: path1)
                if url.isFileURL{
                    try? data.appendPart(withFileURL: url, name: "image_file1")
                }
            }
            
            if let path2 = ip2,ft2 == nil{
                let url = URL(fileURLWithPath: path2)
                if url.isFileURL{
                    try? data.appendPart(withFileURL: url, name: "image_file2")
                }
            }
            
        }, progress: progress, success: success, failure: failure)
    }
    
    // MARK: 搜索
    
    
    /// 在一个faceset里搜索对比相似的人脸。
    ///
    /// - Parameters:
    ///   - faceToken: faceToken description
    ///   - imagePath: imagePath description
    ///   - set: set description
    ///   - progress: progress description
    ///   - success: success description
    ///   - failure: failure description
    func search(faceToken:String?,imagePath:String?,return_result_count:Int? = nil,inFaceSet set:String,progress:ProgressHandle?,success:@escaping SuccessfulHandle,failure:@escaping FailureHandle){
        guard faceToken != nil || imagePath != nil else {
            failure("没有对比对象--PPF")
            return
        }
        if let count = return_result_count,count >= 1 , count <= 5{
            failure("返回的对比结果，大于等于1,小于等于5--PPF")
            return
        }
        let parameters = generatedParametersWith(faceset_token: set,face_token:faceToken,return_result_count:return_result_count)
        POST("search", parameters: parameters, constructingBodyWith: { (data) in
            guard let path = imagePath, faceToken == nil else{
                return
            }
            let url = URL(fileURLWithPath: path)
            guard url.isFileURL else{
                return
            }
            try? data.appendPart(withFileURL: url, name: "image_file")
        }, progress: progress, success: success, failure: failure)
    }
}
