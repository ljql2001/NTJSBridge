//
//  NTJSCallInfo.m
//  NTJSBridge
//
//  Created by LiJun on 1/12/22.
//  Copyright © 2016 nextop. All rights reserved.
//  Referencing to the DSBridge project on github.com
//

#import "NTJSWebView.h"
#import "NTJSUtils.h"
#import "NTJSCallInfo.h"
#import "NTJSInternalHandler.h"
#import <objc/message.h>

@implementation NTJSWebView {
    void(^javascriptCloseWindowListener)(void);
    int callId;
    NSMutableDictionary<NSString *,id> *allHandlers;
    NSMutableDictionary *handlerMap;
    NSMutableArray<NTJSCallInfo *> *callInfoList;
    NSDictionary<NSString*,NSString*> *dialogTextDic;
    UITextField *txtName;
    UInt64 lastCallTime ;
    NSString *jsCache;
    bool isPending;
    bool isDebug;
}

- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration {
    txtName = nil;
    callId = 0;
    callInfoList = [NSMutableArray array];
    allHandlers = [NSMutableDictionary dictionary];
    handlerMap = [NSMutableDictionary dictionary];
    lastCallTime = 0;
    jsCache = @"";
    isPending = false;
    isDebug = false;
    dialogTextDic = @{};
    
    WKUserScript *script = [[WKUserScript alloc] initWithSource:@"window._dswk=true;"
                                                  injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                               forMainFrameOnly:YES];
    [configuration.userContentController addUserScript:script];
    self = [super initWithFrame:frame configuration:configuration];
    if (self) {
        super.UIDelegate=self;
    }
    // add internal Javascript Object
    NTJSInternalHandler *handler = [[NTJSInternalHandler alloc] init];
    handler.webview = self;
    [self addJSHandler:handler namespace:@"_dsb"];
    return self;
}

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable result))completionHandler {
    NSString *prefix = @"_dsbridge=";
    if ([prompt hasPrefix:prefix]) {
        NSString *method = [prompt substringFromIndex:[prefix length]];
        NSString *result = nil;
        if (isDebug) {
            result = [self call:method :defaultText];
        } else {
            @try {
                result = [self call:method :defaultText];
            } @catch(NSException *exception) {
                NSLog(@"%@", exception);
            }
        }
        completionHandler(result);
    }else {
        if(self.DSUIDelegate && [self.DSUIDelegate respondsToSelector:
                                 @selector(webView:runJavaScriptTextInputPanelWithPrompt
                                           :defaultText:initiatedByFrame
                                           :completionHandler:)]) {
            return [self.DSUIDelegate webView:webView runJavaScriptTextInputPanelWithPrompt:prompt
                                  defaultText:defaultText
                             initiatedByFrame:frame
                            completionHandler:completionHandler];
        }
        completionHandler(nil);
    }
}

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    
    if (self.DSUIDelegate && [self.DSUIDelegate respondsToSelector:@selector(webView:runJavaScriptAlertPanelWithMessage:initiatedByFrame:completionHandler:)]) {
        return [self.DSUIDelegate webView:webView
       runJavaScriptAlertPanelWithMessage:message
                         initiatedByFrame:frame
                        completionHandler:completionHandler];
    }
    completionHandler();
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler {
    if (self.DSUIDelegate && [self.DSUIDelegate respondsToSelector:@selector(webView:runJavaScriptConfirmPanelWithMessage:initiatedByFrame:completionHandler:)]) {
        return [self.DSUIDelegate webView:webView runJavaScriptConfirmPanelWithMessage:message
                         initiatedByFrame:frame
                        completionHandler:completionHandler];
    }
    completionHandler(YES);
}

- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    if (self.DSUIDelegate && [self.DSUIDelegate respondsToSelector:@selector(webView:createWebViewWithConfiguration:forNavigationAction:windowFeatures:)]) {
        return [self.DSUIDelegate webView:webView createWebViewWithConfiguration:configuration forNavigationAction:navigationAction windowFeatures:windowFeatures];
    }
    return nil;
}

- (void)webViewDidClose:(WKWebView *)webView{
    if (self.DSUIDelegate && [self.DSUIDelegate respondsToSelector:@selector(webViewDidClose:)]) {
        [self.DSUIDelegate webViewDidClose:webView];
    }
}

- (BOOL)webView:(WKWebView *)webView shouldPreviewElement:(WKPreviewElementInfo *)elementInfo{
    if (self.DSUIDelegate && [self.DSUIDelegate respondsToSelector: @selector(webView:shouldPreviewElement:)]) {
        return [self.DSUIDelegate webView:webView shouldPreviewElement:elementInfo];
    }
    return NO;
}

- (UIViewController *)webView:(WKWebView *)webView previewingViewControllerForElement:(WKPreviewElementInfo *)elementInfo
               defaultActions:(NSArray<id<WKPreviewActionItem>> *)previewActions {
    if (self.DSUIDelegate && [self.DSUIDelegate respondsToSelector:@selector(webView:previewingViewControllerForElement:defaultActions:)]) {
        return [self.DSUIDelegate webView:webView
       previewingViewControllerForElement:elementInfo
                           defaultActions:previewActions];
    }
    return nil;
}

- (void)webView:(WKWebView *)webView commitPreviewingViewController:(UIViewController *)previewingViewController{
    if (self.DSUIDelegate && [self.DSUIDelegate respondsToSelector:@selector(webView:commitPreviewingViewController:)]) {
        return [self.DSUIDelegate webView:webView commitPreviewingViewController:previewingViewController];
    }
}

- (void)evalJavascript:(int)delay {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
        __strong typeof(self) strongSelf = self;
        @synchronized(self) {
            if ([strongSelf->jsCache length] != 0) {
                [strongSelf evaluateJavaScript:strongSelf->jsCache completionHandler:nil];
                strongSelf->isPending = false;
                strongSelf->jsCache = @"";
                strongSelf->lastCallTime = [[NSDate date] timeIntervalSince1970] * 1000;
            }
        }
    });
}

- (NSString *)call:(NSString *)method :(NSString *)argStr {
    NSArray *nameStr = [NTJSUtils parseMethodName:[method stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
    id JavascriptInterfaceObject = allHandlers[nameStr[0]];
    NSString *error = [NSString stringWithFormat:@"Error! \n Method %@ is not invoked, since there is not a implementation for it", method];
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary:@{@"code": @-1, @"data": @""}];
    if (!JavascriptInterfaceObject) {
        NSLog(@"Js bridge  called, but can't find a corresponded JavascriptObject , please check your code!");
    } else {
        method = nameStr[1];
        NSString *methodOne = [NTJSUtils wholeNameOfMethod:method onClass:[JavascriptInterfaceObject class] argNum:1];
        NSString *methodTwo = [NTJSUtils wholeNameOfMethod:method onClass:[JavascriptInterfaceObject class] argNum:2];
        SEL sel = NSSelectorFromString(methodOne);
        SEL selasyn = NSSelectorFromString(methodTwo);
        NSDictionary *args = [NTJSUtils objectFrom:argStr];
        id arg = args[@"data"];
        if (arg == [NSNull null]) {
            arg = nil;
        }
        NSString *cb;
        do {
            if (args && (cb = args[@"_dscbstub"])) {
                if ([JavascriptInterfaceObject respondsToSelector:selasyn]) {
                    __weak typeof(self) weakSelf = self;
                    void (^completionHandler)(id, BOOL) = ^(id value, BOOL complete) {
                        NSString *del = @"";
                        result[@"code"] = @0;
                        if (value != nil) { result[@"data"] = value; }
                        value = [NTJSUtils jsonStringFrom:result];
                        value = [value stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
                        
                        if (complete) { del = [@"delete window." stringByAppendingString:cb]; }
                        NSString*js=[NSString stringWithFormat:@"try {%@(JSON.parse(decodeURIComponent(\"%@\")).data);%@; } catch(e){};", cb, (value == nil) ? @"" : value, del];
                        __strong typeof(self) strongSelf = weakSelf;
                        @synchronized(self)
                        {
                            UInt64 t = [[NSDate date] timeIntervalSince1970] * 1000;
                            strongSelf->jsCache = [strongSelf->jsCache stringByAppendingString:js];
                            if(t - strongSelf->lastCallTime < 50) {
                                if (!strongSelf->isPending) {
                                    [strongSelf evalJavascript:50];
                                    strongSelf->isPending = true;
                                }
                            } else {
                                [strongSelf evalJavascript:0];
                            }
                        }
                    };
                    
                    void(*action)(id,SEL,id,id) = (void(*)(id,SEL,id,id))objc_msgSend;
                    action(JavascriptInterfaceObject, selasyn, arg, completionHandler);
                    break;
                }
            } else if ([JavascriptInterfaceObject respondsToSelector:sel]) {
                id ret;
                id(*action)(id,SEL,id) = (id(*)(id,SEL,id))objc_msgSend;
                ret = action(JavascriptInterfaceObject, sel, arg);
                [result setValue:@0 forKey:@"code"];
                if (ret != nil) { [result setValue:ret forKey:@"data"]; }
                break;
            }
            NSString *js = [error stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
            if (isDebug) {
                js = [NSString stringWithFormat:@"window.alert(decodeURIComponent(\"%@\"));",js];
                [self evaluateJavaScript:js completionHandler:nil];
            }
            NSLog(@"%@", error);
        }while (0);
    }
    return [NTJSUtils jsonStringFrom:result];
}

- (void)setJavascriptCloseWindowListener:(void (^)(void))callback
{
    javascriptCloseWindowListener=callback;
}

- (void)setDebugMode:(bool)debug{
    isDebug=debug;
}

- (void)loadUrl: (NSString *)url
{
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    [self loadRequest:request];
}


- (void)callHandler:(NSString *)methodName arguments:(NSArray *)args{
    [self callHandler:methodName arguments:args completionHandler:nil];
}

- (void)callHandler:(NSString *)methodName completionHandler:(void (^)(id _Nullable))completionHandler{
    [self callHandler:methodName arguments:nil completionHandler:completionHandler];
}

-(void)callHandler:(NSString *)methodName arguments:(NSArray *)args completionHandler:(void (^)(id  _Nullable value))completionHandler {
    NTJSCallInfo *callInfo = [[NTJSCallInfo alloc] init];
    callInfo.id = [NSNumber numberWithInt:callId++];
    callInfo.args = (args == nil ? @[] : args);
    callInfo.method = methodName;
    if (completionHandler) {
        [handlerMap setObject:completionHandler forKey:callInfo.id];
    }
    if (callInfoList != nil) {
        [callInfoList addObject:callInfo];
    } else {
        [self dispatchJavascriptCall:callInfo];
    }
}

- (void)dispatchJavascriptCall:(NTJSCallInfo *)info {
    NSString *json = [NTJSUtils jsonStringFrom:@{@"method": info.method, @"callbackId": info.id,
                                                 @"data": [NTJSUtils jsonStringFrom: info.args]}];
    [self evaluateJavaScript:[NSString stringWithFormat:@"window._handleMessageFromNative(%@)", json]
           completionHandler:nil];
}

- (void)addJSHandler:(id)handler namespace:(NSString *)namespace {
    if (handler == nil) { return; }
    if (namespace == nil) { namespace = @""; }
    [allHandlers setObject:handler forKey:namespace];
}

- (void)removeJavascriptObject:(NSString *)namespace {
    if (namespace == nil) { namespace = @""; }
    [allHandlers removeObjectForKey:namespace];
}

- (id)onMessage:(NSDictionary *)msg type:(int)type {
    id ret = nil;
    switch (type) {
        case DSB_API_HASNATIVEMETHOD:
            ret = ([self hasNativeMethod:msg] ? @1 : @0);
            break;
        case DSB_API_CLOSEPAGE:
            [self closePage:msg];
            break;
        case DSB_API_RETURNVALUE:
            ret = [self returnValue:msg];
            break;
        case DSB_API_DSINIT:
            ret = [self dsinit:msg];
            break;
        case DSB_API_DISABLESAFETYALERTBOX:
            [self disableJavascriptDialogBlock:[msg[@"disable"] boolValue]];
            break;
        default:
            break;
    }
    return ret;
}

- (bool)hasNativeMethod:(NSDictionary *)args {
    NSArray *nameStr = [NTJSUtils parseMethodName:[args[@"name"]stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
    NSString *type= [args[@"type"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    id JavascriptInterfaceObject = [allHandlers objectForKey:nameStr[0]];
    if (JavascriptInterfaceObject) {
        bool syn = ([NTJSUtils wholeNameOfMethod:nameStr[1] onClass:[JavascriptInterfaceObject class] argNum:1] != nil);
        bool asyn = ([NTJSUtils wholeNameOfMethod:nameStr[1] onClass:[JavascriptInterfaceObject class] argNum:2] != nil);
        if (([@"all" isEqualToString:type] && (syn || asyn))
            || ([@"asyn" isEqualToString:type] && asyn)
            || ([@"syn" isEqualToString:type] && syn)) {
            return true;
        }
    }
    return false;
}

- (id)closePage:(NSDictionary *)args{
    if (javascriptCloseWindowListener) {
        javascriptCloseWindowListener();
    }
    return nil;
}

- (id)returnValue:(NSDictionary *)args {
    void (^ completionHandler)(NSString *_Nullable) = handlerMap[args[@"id"]];
    if (completionHandler) {
        if (isDebug) {
            completionHandler(args[@"data"]);
        } else {
            @try {
                completionHandler(args[@"data"]);
            } @catch (NSException *e) {
                NSLog(@"%@",e);
            }
        }
        if ([args[@"complete"] boolValue]) {
            [handlerMap removeObjectForKey:args[@"id"]];
        }
    }
    return nil;
}

- (void)dispatchStartupQueue {
    if (callInfoList == nil) return;
    for (NTJSCallInfo *callInfo in callInfoList) {
        [self dispatchJavascriptCall:callInfo];
    }
    callInfoList = nil;
}

- (id)dsinit:(NSDictionary *)args{
    [self dispatchStartupQueue];
    return nil;
}

- (void)disableJavascriptDialogBlock:(bool)disabled { }

- (void)hasJavascriptMethod:(NSString *)handlerName methodExistCallback:(void (^)(bool exist))callback {
    [self callHandler:@"_hasJavascriptMethod" arguments:@[handlerName] completionHandler:^(NSNumber* _Nullable value) {
        callback([value boolValue]);
    }];
}

@end


