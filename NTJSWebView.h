//
//  NTJSCallInfo.m
//  NTJSBridge
//
//  Created by LiJun on 1/12/22.
//  Copyright © 2016 nextop. All rights reserved.
//  Referencing to the DSBridge project on github.com
//

#import <WebKit/WebKit.h>

typedef void (^JSCallback)(NSString * _Nullable result,BOOL complete);

@interface NTJSWebView: WKWebView <WKUIDelegate>

@property (nullable, nonatomic, weak) id <WKUIDelegate> DSUIDelegate;

- (void)loadUrl: (NSString * _Nonnull) url;

// Call javascript handler
- (void)callHandler:(NSString * _Nonnull) methodName arguments:(NSArray * _Nullable) args;
- (void)callHandler:(NSString * _Nonnull) methodName completionHandler:(void (^ _Nullable)(id _Nullable value))completionHandler;
- (void)callHandler:(NSString * _Nonnull) methodName arguments:(NSArray * _Nullable) args completionHandler:(void (^ _Nullable)(id _Nullable value))completionHandler;

// set a listener for javascript closing the current page.
- (void)setJavascriptCloseWindowListener:(void(^_Nullable)(void))callback;

/**
 * Add a Javascript Object to dsBridge with namespace.
 * @param object
 * which implemented the javascript interfaces
 * @param namespace  
 * if empty, the object have no namespace.
 **/
- (void)addJSHandler:(id _Nullable)handler namespace:(NSString * _Nullable)namespace;

// Remove the Javascript Object with the supplied namespace
- (void)removeJavascriptObject:(NSString *  _Nullable) namespace;

// Test whether the handler exist in javascript
- (void) hasJavascriptMethod:(NSString * _Nonnull) handlerName methodExistCallback:(void(^ _Nullable)(bool exist))callback;

// Set debug mode. if in debug mode, some errors will be prompted by a dialog
// and the exception caused by the native handlers will not be captured.
- (void) setDebugMode:(bool) debug;

- (void) disableJavascriptDialogBlock:(bool) disable;

// private method, the developer shoudn't call this method
- (id _Nullable ) onMessage:(NSDictionary *_Nonnull) msg type:(int) type;

@end
