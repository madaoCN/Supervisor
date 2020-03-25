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


// origin writev IMP
static ssize_t (*orig_writev)(int a, const struct iovec * v, int v_len);

// swizzle method
ssize_t aslfh_writev(int a, const struct iovec *v, int v_len) {
    
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

// hook print for swift
static char *__chineseChar = {0};
static int __buffIdx = 0;
static NSString *__syncToken = @"token";

// origin fwrite IMP
static size_t (*orig_fwrite)(const void * __restrict, size_t, size_t, FILE * __restrict);

// swizzle method
size_t asl_fwrite(const void * __restrict ptr, size_t size, size_t nitems, FILE * __restrict stream) {
    
    char *str = (char *)ptr;
    __block NSString *s = [NSString stringWithCString:str encoding:NSUTF8StringEncoding];
    dispatch_async(dispatch_get_main_queue(), ^{
        @synchronized (__syncToken) {
            if (__chineseChar != NULL) {
                if (str[0] == '\n' && __chineseChar[0] != '\0') {
                    s = [[NSString stringWithCString:__chineseChar encoding:NSUTF8StringEncoding] stringByAppendingString:s];
                    __buffIdx = 0;
                    __chineseChar = calloc(1, sizeof(char));
                }
            } else {
               // do something
                if (ASLHookCallBack) {
                    ASLHookCallBack([[ASLFishHookInfoModel alloc] initWithType:(ASLFishHookType_Fwrite) message:s]);
                }
            }
        }
    });
    return orig_fwrite(ptr, size, nitems, stream);
}

// swbuf
static int (*orin___swbuf)(int, FILE *);
static int asl___swbuf(int c, FILE *p) {
    @synchronized (__syncToken) {
        __chineseChar = realloc(__chineseChar, sizeof(char) * (__buffIdx + 2));
        __chineseChar[__buffIdx] = (char)c;
        __chineseChar[__buffIdx + 1] = '\0';
        __buffIdx++;
    }
    return orin___swbuf(c, p);
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
    rebind_symbols((struct rebinding[1]){{
        "writev",
        aslfh_writev,
        (void*)&orig_writev
    }}, 1);
    
    rebind_symbols((struct rebinding[1]){{
        "fwrite",
        asl_fwrite,
        (void *)&orig_fwrite}}, 1);

    rebind_symbols((struct rebinding[1]){{
        "__swbuf",
        asl___swbuf,
        (void *)&orin___swbuf}}, 1);
    
    ASLHookCallBack = callBack;
}

@end
