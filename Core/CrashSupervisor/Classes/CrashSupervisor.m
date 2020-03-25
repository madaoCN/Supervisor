//
//  CSCrashManager.m
//  Supervisor
//
//  Created by 梁宪松 on 2020/3/25.
//

#import "CrashSupervisor.h"
#import <sys/utsname.h>
#import <mach-o/dyld.h>

typedef struct {
    unsigned int rhcrashManagerDidCatchCrash: 1;
} RHWeakDelegateFlag;

static inline NSString * __privateGetDeviceCpuArch()
{
    NSString *strSystemArch =nil;
    
    /// CFBundleName
    NSDictionary *dicInfo =   [[NSBundle mainBundle] infoDictionary];
    if (!dicInfo)
    {
        return strSystemArch;
    }
    
    NSString *strAppName = dicInfo[@"CFBundleName"];
    if (!strAppName)
    {
        return strSystemArch;
    }
    
    /// cpu type
    uint32_t count = _dyld_image_count();
    cpu_type_t cpuType = -1;
    cpu_type_t cpuSubType =-1;
    
    for(uint32_t iImg = 0; iImg < count; iImg++)
    {
        const char* szName = _dyld_get_image_name(iImg);
        if (strstr(szName, strAppName.UTF8String) != NULL)
        {
            const struct mach_header* machHeader = _dyld_get_image_header(iImg);
            cpuType = machHeader->cputype;
            cpuSubType = machHeader->cpusubtype;
            break;
        }
    }
    
    if(cpuType < 0 ||  cpuSubType <0)
    {
        return  strSystemArch;
    }
    ///  transform CPU type to String
    switch(cpuType)
    {
        case CPU_TYPE_ARM:
        {
            strSystemArch = @"arm";
            switch (cpuSubType)
            {
                case CPU_SUBTYPE_ARM_V6:
                    strSystemArch = @"armv6";
                    break;
                case CPU_SUBTYPE_ARM_V7:
                    strSystemArch = @"armv7";
                    break;
                case CPU_SUBTYPE_ARM_V7F:
                    strSystemArch = @"armv7f";
                    break;
                case CPU_SUBTYPE_ARM_V7K:
                    strSystemArch = @"armv7k";
                    break;
#ifdef CPU_SUBTYPE_ARM_V7S
                case CPU_SUBTYPE_ARM_V7S:
                    strSystemArch = @"armv7s";
                    break;
#endif
            }
            break;
        }
#ifdef CPU_TYPE_ARM64
        case CPU_TYPE_ARM64:
            strSystemArch = @"arm64";
            break;
#endif
        case CPU_TYPE_X86:
            strSystemArch = @"i386";
            break;
        case CPU_TYPE_X86_64:
            strSystemArch = @"x86_64";
            break;
    }
    return strSystemArch;
}

static inline NSString * __getDeviceCpuArch()
{
    static NSString *cpuArch = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        cpuArch = __privateGetDeviceCpuArch();
    });
    return cpuArch;
}

static inline NSString * __privateGetImageLoadAddress()
{
    NSString *strLoadAddress =nil;
    
    NSString * strAppName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    if (!strAppName)
    {
        return strLoadAddress;
    }
    
    ///获取应用程序的load address
    uint32_t count = _dyld_image_count();
    for(uint32_t iImg = 0; iImg < count; iImg++)
    {
        const char* szName = _dyld_get_image_name(iImg);
        if (strstr(szName, strAppName.UTF8String) != NULL)
        {
            const struct mach_header* header = _dyld_get_image_header(iImg);
            strLoadAddress = [NSString stringWithFormat:@"0x%lX",(uintptr_t)header];
            break;
        }
    }
    return strLoadAddress;
}

static inline NSString * __getImageLoadAddress()
{
    static NSString *loadAdress = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        loadAdress = __privateGetImageLoadAddress();
    });
    return loadAdress;
}

static inline NSString * __crashTypeDes(CSCrashType crashType) {
    
    switch (crashType) {
            case CSCrashType_Exception:
            return @"EXCEPTION";
            case CSCrashType_Signal:
            return @"SIGNAL";
        default:
            return @"UNKOWN";
    }
}

@implementation CrashSupervisorWeakDelegate
{
    RHWeakDelegateFlag _delegateFlag;
}

- (instancetype)initWithDelegate:(id <CrashSupervisorDelegate>)delegate
{
    if (self = [super init]) {
        _weakDelegate = delegate;
        if ([delegate respondsToSelector:@selector(crashSupervisorDidCatchCrash:)]) {
            _delegateFlag.rhcrashManagerDidCatchCrash = YES;
        }
    }
    return self;
}

- (RHWeakDelegateFlag)flag
{
    return _delegateFlag;
}
@end


@implementation CSCrashModel

- (NSString *)description
{
    return [NSString stringWithFormat:@"CRASH: %@\r\n [NAME]: %@ \r\n [REASON]: %@ \r\n [APP INFO]:%@ \r\n [CPU ARCH]: %@ \r\n [LOADING ADDRESS]: %@ \r\n [CALLSTACK]: %@ \r\n", __crashTypeDes(self.crashType), self.name, self.reason, self.appInfo, self.cpuArchType, self.imageLoadingAdress, self.callStack];
}

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"CRASH: %@\r\n [NAME]: %@ \r\n [REASON]: %@ \r\n [APP INFO]:%@ \r\n [CPU ARCH]: %@ \r\n [LOADING ADDRESS]: %@ \r\n [CALLSTACK]: %@ \r\n", __crashTypeDes(self.crashType), self.name, self.reason, self.appInfo, self.cpuArchType, self.imageLoadingAdress, self.callStack];
}

@end

static NSUncaughtExceptionHandler *_old_exception_handler = nil;
static NSMutableArray <CrashSupervisorWeakDelegate *>*_delegateList;
static BOOL _isCrashManagerOpen = NO;

static inline NSString *nameOfSignal(int32_t signal) {
    switch (signal) {
            case SIGABRT:
            return @"SIGABRT";
            case SIGILL:
            return @"SIGILL";
            case SIGSEGV:
            return @"SIGSEGV";
            case SIGFPE:
            return @"SIGFPE";
            case SIGBUS:
            return @"SIGBUS";
            case SIGPIPE:
            return @"SIGPIPE";
        default:
            return @"OTHER";
    }
}

static inline NSString *AppInfo()
{
    NSString *displayName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    NSString *shortVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSString *model =  [UIDevice currentDevice].model;
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceModel = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    NSString *systemName =  [UIDevice currentDevice].systemName;
    NSString *systemVersion =  [UIDevice currentDevice].systemVersion;
    
    return [NSString stringWithFormat:@"App: %@, %@, %@ Device: %@, %@ OS System: %@ %@", displayName, shortVersion, version, model, deviceModel, systemName, systemVersion];
}

static inline void ExceptionHandler(NSException *exception) {
    
    // invoke original exception handler
    if (_old_exception_handler) {
        _old_exception_handler(exception);
    }
    
    if (!_isCrashManagerOpen) {
        return;
    }
    
    NSString *name = exception.name;
    NSString *reason = exception.reason;
    NSString *appinfo = AppInfo();
    NSArray *callSymbols = [exception callStackSymbols];
    NSString *callStack = [callSymbols componentsJoinedByString:@"\r\n"];
    NSString *cpuArch = __getDeviceCpuArch();
    NSString *loadAddress = __getImageLoadAddress();

    CSCrashModel *crashModel = [[CSCrashModel alloc] init];
    crashModel.name = name;
    crashModel.crashType = CSCrashType_Exception;
    crashModel.reason = reason;
    crashModel.appInfo = appinfo;
    crashModel.callStack = callStack;
    crashModel.cpuArchType = cpuArch;
    crashModel.imageLoadingAdress = loadAddress;
    
    [_delegateList enumerateObjectsUsingBlock:^(CrashSupervisorWeakDelegate * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (obj.weakDelegate && [obj flag].rhcrashManagerDidCatchCrash) {
            [obj.weakDelegate crashSupervisorDidCatchCrash:crashModel];
        }
    }];
}

@class CrashSupervisor;
static inline void SignalHandler(int32_t signal) {
    
    if (!_isCrashManagerOpen) {
        return;
    }
    
    NSString *name = nameOfSignal(signal);
    NSString *reason = [NSString stringWithFormat:@"Signal %@: %d was raised", name, signal];
    NSString *appinfo = AppInfo();
    NSArray<NSString *> *callStackSymbols = [NSThread callStackSymbols];
    NSString *callStack = [callStackSymbols componentsJoinedByString:@"\r\n"];
    NSString *cpuArch = __getDeviceCpuArch();
    NSString *loadAddress = __getImageLoadAddress();
    
    CSCrashModel *crashModel = [[CSCrashModel alloc] init];
    crashModel.name = name;
    crashModel.crashType = CSCrashType_Signal;
    crashModel.reason = reason;
    crashModel.appInfo = appinfo;
    crashModel.callStack = callStack;
    crashModel.cpuArchType = cpuArch;
    crashModel.imageLoadingAdress = loadAddress;
    
    [_delegateList enumerateObjectsUsingBlock:^(CrashSupervisorWeakDelegate * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (obj.weakDelegate && [obj flag].rhcrashManagerDidCatchCrash) {
            [obj.weakDelegate crashSupervisorDidCatchCrash:crashModel];
        }
    }];
    
    // kill app
    [CrashSupervisor killApp];
}

@interface CrashSupervisor()

@end

@implementation CrashSupervisor

+ (void)open
{
    if (_isCrashManagerOpen) {
        return;
    }
    _isCrashManagerOpen = YES;
    // save original exception handler
    _old_exception_handler = NSGetUncaughtExceptionHandler();
    NSSetUncaughtExceptionHandler(ExceptionHandler);
    [self setCrashSignalHandler];
}

+ (void)close
{
    if (!_isCrashManagerOpen) {
        return;
    }
    _isCrashManagerOpen = NO;
    NSSetUncaughtExceptionHandler(_old_exception_handler);
}

+ (void)setCrashSignalHandler
{
    signal(SIGABRT, SignalHandler);
    signal(SIGILL, SignalHandler);
    signal(SIGSEGV, SignalHandler);
    signal(SIGFPE, SignalHandler);
    signal(SIGBUS, SignalHandler);
    signal(SIGPIPE, SignalHandler);
    //http://stackoverflow.com/questions/36325140/how-to-catch-a-swift-crash-and-do-some-logging
    signal(SIGTRAP, SignalHandler);
}

+ (void)killApp
{
    NSSetUncaughtExceptionHandler(nil);
    
    signal(SIGABRT, SIG_DFL);
    signal(SIGILL, SIG_DFL);
    signal(SIGSEGV, SIG_DFL);
    signal(SIGFPE, SIG_DFL);
    signal(SIGBUS, SIG_DFL);
    signal(SIGPIPE, SIG_DFL);

    kill(getpid(), SIGKILL);
}

+ (NSMutableArray <CrashSupervisorWeakDelegate *>*)delegateList
{
    if (!_delegateList) {
        _delegateList = [[NSMutableArray alloc] init];
    }
    return _delegateList;
}
@end

@implementation CrashSupervisor(DelegateOperation)

+ (void)addDelegate:(id <CrashSupervisorDelegate>)delegate
{
    NSMutableArray <CrashSupervisorWeakDelegate *>*delegates = [[NSMutableArray alloc] init];
    // delete null week delegate
    [_delegateList enumerateObjectsUsingBlock:^(CrashSupervisorWeakDelegate * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (obj.weakDelegate) {
            [delegates addObject:obj];
        }
    }];
    _delegateList = delegates;
    
    // judge if existed the delegte from parameter
    static BOOL contain = NO;
    [delegates enumerateObjectsUsingBlock:^(CrashSupervisorWeakDelegate * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ([obj.weakDelegate hash] == delegate.hash) {
            contain = YES;
        }
    }];
    
    // if not contian， append it with weak wrapped
    if (!contain) {
        CrashSupervisorWeakDelegate *weakDelegate = [[CrashSupervisorWeakDelegate alloc] initWithDelegate:delegate];
        [_delegateList addObject:weakDelegate];
    }
    
    if (_delegateList.count > 0) {
        [self open];
    }
}

+ (void)removeDelegate:(id <CrashSupervisorDelegate>)delegate
{
    [_delegateList enumerateObjectsUsingBlock:^(CrashSupervisorWeakDelegate * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (obj.weakDelegate == nil) {
            [_delegateList removeObjectAtIndex:idx];
        }
        else if (delegate.hash == obj.weakDelegate.hash){
            [_delegateList removeObjectAtIndex:idx];
        }
    }];
    
    if (_delegateList.count == 0) {
        [self close];
    }
}

@end
