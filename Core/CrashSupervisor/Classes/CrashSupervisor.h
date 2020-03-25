//
//  CSCrashManager.h
//  Supervisor
//
//  Created by 梁宪松 on 2020/3/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

//--------------------------------------------------------------------------
//  A tool to hook Object-c and Swift Errors， Thanks to CrashEye ： https://github.com/zixun/GodEye.git
//
//  Apple Offical Doc：
//  https://developer.apple.com/library/archive/technotes/tn2151/_index.html#//apple_ref/doc/uid/DTS40008184-CH1-ANALYZING_CRASH_REPORTS-EXCEPTION_CODES
//--------------------------------------------------------------------------

@class CSCrashModel;
@protocol CrashSupervisorDelegate <NSObject>

- (void)crashSupervisorDidCatchCrash:(CSCrashModel *)crashModel;

@end

@interface CrashSupervisorWeakDelegate : NSObject

@property (nonatomic, weak) id <CrashSupervisorDelegate> weakDelegate;

- (instancetype)initWithDelegate:(id <CrashSupervisorDelegate>) delegate;

@end

typedef NS_ENUM(NSUInteger, CSCrashType) {
    CSCrashType_Signal,
    CSCrashType_Exception,
};

@interface CSCrashModel : NSObject

/**
 crash type
 */
@property (nonatomic, assign) CSCrashType crashType;

/**
 crash name
 */
@property (nonatomic, strong) NSString *name;

/**
 crash reason
 */
@property (nonatomic, strong) NSString *reason;

/**
 app info
 include：os name， os info ，app version .etc
 */
@property (nonatomic, strong) NSString *appInfo;

/**
 Thread or Exception call stacl
 */
@property (nonatomic, strong) NSString *callStack;

/**
 CPU arch type
 */
@property (nonatomic, strong) NSString *cpuArchType;

/**
 dyld image loding address
 */
@property (nonatomic, strong) NSString *imageLoadingAdress;

@end

@interface CrashSupervisor : NSObject

/// open crash hook
+ (void)open;

/// stop carsh hook
+ (void)close;

/// kill App manually
+ (void)killApp;

@end

@interface CrashSupervisor(DelegateOperation)

+ (void)addDelegate:(id <CrashSupervisorDelegate>)delegate;
+ (void)removeDelegate:(id <CrashSupervisorDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
