//
//  NTJSCallInfo.m
//  NTJSBridge
//
//  Created by LiJun on 1/12/22.
//  Copyright © 2016 nextop. All rights reserved.
//  Referencing to the DSBridge project on github.com
//

#import <Foundation/Foundation.h>

enum{
 DSB_API_HASNATIVEMETHOD,
 DSB_API_CLOSEPAGE,
 DSB_API_RETURNVALUE,
 DSB_API_DSINIT,
 DSB_API_DISABLESAFETYALERTBOX
};

@interface NTJSUtils: NSObject
+ (NSString * _Nullable)jsonStringFrom:(id _Nonnull)dict;
+ (id _Nullable)objectFrom:(NSString *_Nonnull)jsonString;
+ (NSString * _Nullable)wholeNameOfMethod:(NSString * _Nullable)name onClass:(Class _Nonnull)class argNum:(NSInteger)argNum;
+ (NSArray * _Nonnull)parseMethodName:(NSString * _Nonnull)name;
@end
