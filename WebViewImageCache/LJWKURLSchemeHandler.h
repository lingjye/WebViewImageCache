//
//  LJWKURLSchemeHandler.h
//  WebViewImageCache
//
//  Created by txooo on 2019/6/10.
//  Copyright © 2019 lingjye. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^didClickBlock)(UIImage *image, CGFloat progress);

@interface LJWKURLSchemeHandler : NSObject<WKURLSchemeHandler>

@property (nonatomic, copy) didClickBlock clickBlock;

@end

NS_ASSUME_NONNULL_END
