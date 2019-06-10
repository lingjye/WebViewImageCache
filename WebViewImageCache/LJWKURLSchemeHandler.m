//
//  LJWKURLSchemeHandler.m
//  WebViewImageCache
//
//  Created by txooo on 2019/6/10.
//  Copyright © 2019 lingjye. All rights reserved.
//

#import "LJWKURLSchemeHandler.h"
#import <SDWebImage/UIImage+MultiFormat.h>
#import <SDWebImage/SDWebImageManager.h>

@implementation LJWKURLSchemeHandler

- (void)webView:(WKWebView *)webView startURLSchemeTask:(id<WKURLSchemeTask>)urlSchemeTask API_AVAILABLE(ios(11.0)) {
    NSURLRequest *request = urlSchemeTask.request;
    NSString *urlString = [request.URL.absoluteString stringByReplacingOccurrencesOfString:@"ljwebimageclick:" withString:@""];
    NSURL *url = [NSURL URLWithString:urlString];
    //利用SDWebImage寻找本地图片
    NSString *key = [[SDWebImageManager sharedManager] cacheKeyForURL:url];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    NSData *data = [[SDImageCache sharedImageCache] performSelector:NSSelectorFromString(@"diskImageDataBySearchingAllPathsForKey:") withObject:key];
#pragma clang diagnostic pop
    if (data){
        [self urlSchemeTask:urlSchemeTask appendLocalData:data url:url];
    } else {
        [[SDWebImageManager sharedManager] loadImageWithURL:url options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
            
        } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
            [self urlSchemeTask:urlSchemeTask appendLocalData:data url:url];
        }];
    }
    
}

- (void)urlSchemeTask:(id<WKURLSchemeTask>)urlSchemeTask appendLocalData:(NSData *)data url:(NSURL *)url API_AVAILABLE(ios(11.0)){
    NSURLResponse *response = [[NSURLResponse alloc] initWithURL:url
                                                        MIMEType:(__bridge NSString*)[NSData sd_UTTypeFromSDImageFormat:[NSData sd_imageFormatForImageData:data]]
                                           expectedContentLength:data.length
                                                textEncodingName:nil];
    [urlSchemeTask didReceiveResponse:response];
    [urlSchemeTask didReceiveData:data];
    [urlSchemeTask didFinish];
}

- (void)webView:(nonnull WKWebView *)webView
    stopURLSchemeTask:(nonnull id<WKURLSchemeTask>)urlSchemeTask API_AVAILABLE(ios(11.0)) {
}

@end
