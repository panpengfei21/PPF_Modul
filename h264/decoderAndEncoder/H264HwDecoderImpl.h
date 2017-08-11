//
//  H264HwDecoderImpl.h
//  ShiPinHuiYi
//
//  Created by 徐杨 on 16/3/31.
//  Copyright (c) 2016年 feiyuxing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVSampleBufferDisplayLayer.h>


@protocol H264HwDecoderImplDelegate <NSObject>

- (void)displayDecodedFrame:(CVImageBufferRef )imageBuffer;

@end

@interface H264HwDecoderImpl : NSObject
@property (weak, nonatomic) id<H264HwDecoderImplDelegate> delegate;

//-(BOOL)initH264Decoder;

/**
 frame的头四个字节要被长度信息来取取代的,所以frame的头4个字节可以是无用的信息.但一定是可以被废弃的.
 
 @param frame 帧
 @param frameSize 帧长度
 */
-(void)decodeNalu:(uint8_t *)frame withSize:(uint32_t)frameSize;
@end
