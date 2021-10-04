//
//  RNBridgeManager.m
//  BridgingDemo
//

#import <React/RCTViewManager.h>

@interface RCT_EXTERN_MODULE(NativeMLKitManager, RCTViewManager)
RCT_EXPORT_VIEW_PROPERTY(isEnableDetaction, BOOL)
RCT_EXPORT_VIEW_PROPERTY(onPoseDetect, RCTBubblingEventBlock)
@end
