//
//  NTJSCallInfo.m
//  NTJSBridge
//
//  Created by LiJun on 1/12/22.
//  Copyright © 2016 nextop. All rights reserved.
//  Referencing to the DSBridge project on github.com
//

#import "NTJSInternalHandler.h"
#import "NTJSUtils.h"

@implementation NTJSInternalHandler
- (id)hasNativeMethod:(id)args {
    return [self.webview onMessage:args type:DSB_API_HASNATIVEMETHOD];
}

- (id)closePage:(id)args {
    return [self.webview onMessage:args type:DSB_API_CLOSEPAGE];
}

- (id)returnValue:(NSDictionary *)args {
    return [self.webview onMessage:args type:DSB_API_RETURNVALUE];
}

- (id)dsinit:(id)args {
    return [self.webview onMessage:args type:DSB_API_DSINIT];
}

- (id)disableJavascriptDialogBlock:(id)args {
    return [self.webview onMessage:args type:DSB_API_DISABLESAFETYALERTBOX];
}
@end
