//
//  FPrint.m
//  Supervisor_Tests
//
//  Created by 梁宪松 on 2020/3/26.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

#import "FPrint.h"

@implementation FPrint

+ (void)fprint
{
    fprintf(stderr, "fprint test");
    fprintf(stderr, "fprint test: %s", "测试");
    fprintf(stderr, "fprint test: %d", 666);
}
@end
