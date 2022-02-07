//
//  NTJSCallInfo.m
//  NTJSBridge
//
//  Created by LiJun on 1/12/22.
//  Copyright © 2016 nextop. All rights reserved.
//  Referencing to the DSBridge project on github.com
//

#import <Foundation/Foundation.h>

@interface NTJSCallInfo: NSObject
@property(nullable, nonatomic) NSString *method;
@property(nullable, nonatomic) NSNumber *id;
@property(nullable, nonatomic) NSArray *args;
@end
