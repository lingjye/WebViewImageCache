//
//  LJURLCacheProtocol.m
//  WebViewImageCache
//
//  Created by txooo on 2018/11/10.
//  Copyright © 2018年 lingjye. All rights reserved.
//

#import "LJURLCacheProtocol.h"
#import <SDWebImage/SDWebImageManager.h>
#import <SDWebImage/UIImage+MultiFormat.h>

static NSString *const LJURLCacheProtocolKey = @"LJURLCacheProtocolKey";

@interface LJURLCacheProtocol ()<NSURLSessionDataDelegate>

@property (nonatomic, strong) NSMutableData *responseData;
//iOS 7 以前使用NSURLConnection
@property (nonatomic, nonnull, strong) NSURLSessionDataTask *task;

@end

@implementation LJURLCacheProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    if ([request.URL.scheme isEqualToString:@"http"] || [request.URL.scheme isEqualToString:@"https"]) {
        NSString *str = request.URL.path;
        //筛选图片 且已处理过的不再处理防止无限循环
        if (([str hasSuffix:@".png"] || [str hasSuffix:@".jpg"] || [str hasSuffix:@".jpeg"] || [str hasSuffix:@".gif"])
            && ![NSURLProtocol propertyForKey:LJURLCacheProtocolKey inRequest:request]) {
            return YES;
        }
    }
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    NSMutableURLRequest *mutableReqeust = [request mutableCopy];
    //此处可截取request重定向.(例如:更改地址，提取请求内容，或者设置里面的请求头等)
    return mutableReqeust;
}

- (void)startLoading {
    NSMutableURLRequest *mutableReqeust = [[self request] mutableCopy];
    //给处理过的请求设置标记 防止递归调用
    [NSURLProtocol setProperty:@YES forKey:LJURLCacheProtocolKey inRequest:mutableReqeust];
    
    //利用SDWebImage寻找本地图片
    NSString *key = [[SDWebImageManager sharedManager] cacheKeyForURL:self.request.URL];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    NSData *data = [[SDImageCache sharedImageCache] performSelector:NSSelectorFromString(@"diskImageDataBySearchingAllPathsForKey:") withObject:key];
#pragma clang diagnostic pop
    
    if (data) {
        NSURLResponse *response = [[NSURLResponse alloc] initWithURL:mutableReqeust.URL
                                                            MIMEType:(__bridge NSString*)[NSData sd_UTTypeFromSDImageFormat:[NSData sd_imageFormatForImageData:data]]
                                               expectedContentLength:data.length
                                                    textEncodingName:nil];
        [self.client URLProtocol:self
              didReceiveResponse:response
              cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        
        [self.client URLProtocol:self didLoadData:data];
        [self.client URLProtocolDidFinishLoading:self];
    } else {
        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
        self.task = [session dataTaskWithRequest:self.request];
        [self.task resume];
    }
}

- (void)stopLoading {
    if (self.task != nil) {
        [self.task  cancel];
    }
}

#pragma mark NSURLSessionDataDelegate
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    self.responseData = [[NSMutableData alloc] init];
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [self.responseData appendData:data];
    [[self client] URLProtocol:self didLoadData:data];
}

#pragma mark NSURLSessionTaskDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error {
    if (error) {
        [self.client URLProtocol:self didFailWithError:error];
    }else {
        UIImage *cacheImage = [UIImage sd_imageWithData:self.responseData];
        //用SDWebImage将图片缓存
        [[SDImageCache sharedImageCache] storeImage:cacheImage forKey:[[SDWebImageManager sharedManager] cacheKeyForURL:self.request.URL] toDisk:YES completion:^{
            //do something
        }];
        [self.client URLProtocolDidFinishLoading:self];
    }
}
@end