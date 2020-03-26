//
//  NSVFishHook.m
//  Supervisor
//
//  Created by 梁宪松 on 2020/3/24.
//

#import "ASLFishHook.h"
#import "fishhook.h"
#import <sys/uio.h>

// static call back foot point
static ASLFishHookCallBack ASLHookCallBack;

//--------------------------------------------------------------------------
// MARK: hook NSLog
//--------------------------------------------------------------------------

// origin writev IMP
static ssize_t (*orig_writev)(int a, const struct iovec * v, int v_len);

// swizzle method
ssize_t asl_writev(int a, const struct iovec *v, int v_len) {
    
    NSMutableString *string = [NSMutableString string];
    for (int i = 0; i < v_len; i++) {
        char *c = (char *)v[i].iov_base;
        [string appendString:[NSString stringWithCString:c encoding:NSUTF8StringEncoding]];
    }
    
    // do something
    if (ASLHookCallBack) {
        ASLHookCallBack([[ASLFishHookInfoModel alloc] initWithType:(ASLFishHookType_Writev) message:string]);
    }
    
    ssize_t result = orig_writev(a, v, v_len);
    return result;
}

//--------------------------------------------------------------------------
// MARK: hook print for swift
//--------------------------------------------------------------------------

// origin fwrite IMP
static size_t (*orig_fwrite)(const void * __restrict, size_t, size_t, FILE * __restrict);

static char *__messageBuffer = {0};
static int __buffIdx = 0;
static NSString *__syncToken = @"token";

void reset_buffer()
{
    __messageBuffer = calloc(1, sizeof(char));
    __messageBuffer[0] = '\0';
    __buffIdx = 0;
}

// swizzle method
size_t asl_fwrite(const void * __restrict ptr, size_t size, size_t nitems, FILE * __restrict stream) {
        
    if (__messageBuffer == NULL) {
        // initial Buffer
        reset_buffer();
    }
    
    char *str = (char *)ptr;
    
    NSString *s = [NSString stringWithCString:str encoding:NSUTF8StringEncoding];
    
    if (__messageBuffer != NULL) {
        
        if (str[0] == '\n' && __messageBuffer[0] != '\0') {
            
            s = [[NSString stringWithCString:__messageBuffer encoding:NSUTF8StringEncoding] stringByAppendingString:s];
            
            // reset buffIdx
            reset_buffer();

            // do something
            if (ASLHookCallBack) {
                ASLHookCallBack([[ASLFishHookInfoModel alloc] initWithType:(ASLFishHookType_Writev) message:s]);
            }
        }
        else {
            
            // append buffer
            __messageBuffer = realloc(__messageBuffer, sizeof(char) * (__buffIdx + nitems + 1));
            for (size_t i = __buffIdx; i < nitems; i++) {
                __messageBuffer[i] = str[i];
                __buffIdx ++;
            }
            __messageBuffer[__buffIdx + 1] = '\0';
            __buffIdx ++;
        }
    }
    
    return orig_fwrite(ptr, size, nitems, stream);
}

//--------------------------------------------------------------------------
// MARK: hook fprintf
//--------------------------------------------------------------------------

// origin fprintf IMP
static int     (*origin_fprintf)(FILE * __restrict, const char * __restrict, ...);

// swizzle method
int     asl_fprintf(FILE * __restrict file, const char * __restrict format, ...)
{
    /*
     typedef struct {
         
        unsigned int gp_offset;
        unsigned int fp_offset;
        void *overflow_arg_area;
        void *reg_save_area;
     } va_list[1];
     */
    va_list args;
    
    va_start(args, format);

    NSString *formatter = [NSString stringWithUTF8String:format];
    NSString *string = [[NSString alloc] initWithFormat:formatter arguments:args];
    // do something
    if (ASLHookCallBack && string) {
        ASLHookCallBack([[ASLFishHookInfoModel alloc] initWithType:(ASLFishHookType_Fprintf) message:string]);
    }
    
    // invoke orign fprintf
    int result = origin_fprintf(file, [string UTF8String]);
    
    va_end(args);

    return result;
}

@implementation ASLFishHookInfoModel

- (instancetype)initWithType:(ASLFishHookType)hookType message:(NSString *)message
{
    if (self = [super init]) {
        self.hookType = hookType;
        self.message = message;
    }
    
    return self;
}

@end

@implementation ASLFishHook

+ (void)hookWithBlock:(ASLFishHookCallBack)callBack
{
    // hook writev
    rebind_symbols((struct rebinding[1]){{
        "writev",
        asl_writev,
        (void*)&orig_writev
    }}, 1);
    
    // hook fwrite
    rebind_symbols((struct rebinding[1]){{
        "fwrite",
        asl_fwrite,
        (void *)&orig_fwrite}}, 1);
    
    // hook fprintf
    rebind_symbols((struct rebinding[1]){{
        "fprintf",
        asl_fprintf,
        (void *)&origin_fprintf}}, 1);
    
    ASLHookCallBack = callBack;
}

@end
