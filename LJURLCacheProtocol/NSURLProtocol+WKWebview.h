//
//  NSURLProtocol+LJWebKitURLCacheProtocol.h
//  WebViewImageCache
//
//  Created by txooo on 2018/12/28.
//  Copyright © 2018 lingjye. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURLProtocol (WKWebview)

+ (void)wk_registerScheme:(NSString *)scheme;
+ (void)wk_unregisterScheme:(NSString *)scheme;

@end

NS_ASSUME_NONNULL_END
