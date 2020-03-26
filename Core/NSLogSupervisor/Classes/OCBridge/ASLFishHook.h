//
//  NSVFishHook.h
//  Supervisor
//
//  Created by 梁宪松 on 2020/3/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ASLFishHookInfoModel;
// hook message call back
typedef void(^ASLFishHookCallBack)(ASLFishHookInfoModel *infoModel);

typedef NS_ENUM(NSUInteger, ASLFishHookType) {
    ASLFishHookType_Fwrite,  // print
    ASLFishHookType_Fprintf, // fprintf
    ASLFishHookType_Writev,  // NSLog
};

@interface ASLFishHookInfoModel : NSObject

/// hook type :  print  or NSLog
@property (nonatomic, assign) ASLFishHookType hookType;

/// console message
@property (nonatomic, strong) NSString *message;

/// init class method
/// @param hookType hook type
/// @param message  console message
- (instancetype)initWithType:(ASLFishHookType)hookType message:(NSString *)message;

@end

@interface ASLFishHook : NSObject

/// hook NSLog and print
/// @param callBack messge call back
+ (void)hookWithBlock:(ASLFishHookCallBack)callBack;

@end

NS_ASSUME_NONNULL_END
