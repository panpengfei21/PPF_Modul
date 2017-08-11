//
//  H264HwDecoderImpl.h
//  ShiPinHuiYi
//
//  Created by 徐杨 on 16/3/31.
//  Copyright (c) 2016年 feiyuxing. All rights reserved.
//

#import "H264HwEncoderImpl.h"

@import VideoToolbox;
//@import AVFoundation;

@implementation H264HwEncoderImpl
{
    NSString * yuvFile;
    VTCompressionSessionRef EncodingSession;
    dispatch_queue_t aQueue;
    CMFormatDescriptionRef  format;
    CMSampleTimingInfo * timingInfo;
    int  frameCount;
    NSData *sps;
    NSData *pps;
}


- (void) initWithConfiguration
{
    EncodingSession = nil;
    aQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    frameCount = 0;
    sps = NULL;
    pps = NULL;
    
}

void didCompressH264(void *outputCallbackRefCon, void *sourceFrameRefCon, OSStatus status, VTEncodeInfoFlags infoFlags,
                     CMSampleBufferRef sampleBuffer )
{
    if (status != 0) return;
    
    if (!CMSampleBufferDataIsReady(sampleBuffer))
    {
        NSLog(@"didCompressH264 data is not ready ");
        return;
    }
    H264HwEncoderImpl* encoder = (__bridge H264HwEncoderImpl*)outputCallbackRefCon;
    
    CFArrayRef array = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true);
    const void * value = CFArrayGetValueAtIndex(array, 0);
    bool keyframe = !CFDictionaryContainsKey(value, kCMSampleAttachmentKey_NotSync);
    
    if (keyframe)
    {
        CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
        
        size_t sparameterSetSize, sparameterSetCount;
        const uint8_t *sparameterSet;
        OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format,
                                                                                 0,
                                                                                 &sparameterSet,
                                                                                 &sparameterSetSize,
                                                                                 &sparameterSetCount,
                                                                                 NULL );
        if (statusCode == noErr)
        {
            size_t pparameterSetSize, pparameterSetCount;
            const uint8_t *pparameterSet;
            OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 1, &pparameterSet, &pparameterSetSize, &pparameterSetCount, 0 );
            if (statusCode == noErr)
            {
                encoder->sps = [NSData dataWithBytes:sparameterSet length:sparameterSetSize];
                encoder->pps = [NSData dataWithBytes:pparameterSet length:pparameterSetSize];
                if (encoder->_delegate)
                {
                    [encoder->_delegate gotSpsPps:encoder->sps pps:encoder->pps];
                }
            }
        }
    }
    CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    size_t length, totalLength;
    char *dataPointer;//拿出来数据的格式是,头四个字节是数据长度(但字节顺序是反的),后面就是数据..可能是由多个这样的格式组成.
    OSStatus statusCodeRet = CMBlockBufferGetDataPointer(dataBuffer, 0, &length, &totalLength, &dataPointer);
    if (statusCodeRet == noErr) {
        size_t bufferOffset = 0;
        static const int AVCCHeaderLength = 4;
        while (bufferOffset < totalLength - AVCCHeaderLength)
        {
            uint32_t NALUnitLength = 0;
            memcpy(&NALUnitLength, dataPointer + bufferOffset, AVCCHeaderLength);//取出头4个字节存到NALUintLength,
            NALUnitLength = CFSwapInt32BigToHost(NALUnitLength);//把字节顺序反转一下,得到数据长度.
            NSData* data = [[NSData alloc] initWithBytes:(dataPointer + bufferOffset + AVCCHeaderLength) length:NALUnitLength];
            [encoder->_delegate gotEncodedData:data isKeyFrame:keyframe];
            bufferOffset += AVCCHeaderLength + NALUnitLength;
        }
    }
}


- (void) initEncode:(int)width  height:(int)height
{
    dispatch_sync(aQueue, ^{
        OSStatus status = VTCompressionSessionCreate(NULL, width, height, kCMVideoCodecType_H264, NULL, NULL, NULL, didCompressH264, (__bridge void *)(self),  &EncodingSession);
        
        
        if (status != 0)
        {
            NSLog(@"Error by VTCompressionSessionCreate  ");
            return ;
        }
        
        VTSessionSetProperty(EncodingSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);//实时运行
        VTSessionSetProperty(EncodingSession, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Baseline_4_1);
        
        SInt32 bitRate = width*height*50;  //越高效果越屌  帧数据越大
        CFNumberRef ref = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &bitRate);
        VTSessionSetProperty(EncodingSession, kVTCompressionPropertyKey_AverageBitRate, ref);
        CFRelease(ref);

        int frameInterval = 10; //关键帧间隔 越低效果越屌 帧数据越大
        CFNumberRef  frameIntervalRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &frameInterval);
        VTSessionSetProperty(EncodingSession, kVTCompressionPropertyKey_MaxKeyFrameInterval,frameIntervalRef);
        CFRelease(frameIntervalRef);
        
        VTCompressionSessionPrepareToEncodeFrames(EncodingSession);
    });
}

- (void) encode:(CMSampleBufferRef )sampleBuffer
{
    if (EncodingSession==nil||EncodingSession==NULL)
    {
        return;
    }
    dispatch_sync(aQueue, ^{
        frameCount++;
        CVImageBufferRef imageBuffer = (CVImageBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
        CMTime presentationTimeStamp = CMTimeMake(frameCount, 1000);
        VTEncodeInfoFlags flags;
        OSStatus statusCode = VTCompressionSessionEncodeFrame(EncodingSession,
                                                              imageBuffer,
                                                              presentationTimeStamp,
                                                              kCMTimeInvalid,
                                                              NULL, NULL, &flags);
        if (statusCode != noErr)
        {
            if (EncodingSession!=nil||EncodingSession!=NULL)
            {
                VTCompressionSessionInvalidate(EncodingSession);
                CFRelease(EncodingSession);
                EncodingSession = NULL;
                return;
            }
        }
        
    });
    
}

@end
