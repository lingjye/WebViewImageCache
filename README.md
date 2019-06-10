# WebViewImageCache
Webview图片与SDWebImage缓存共享示例, 可避免不必要的图片加载, 例如:点击查看大图时不需要再次去下载图片
### 原理: 继承NSURLProtocol, 重写startLoading方法, 当SDImageCache(其他缓存框架方案类似)存在该图片时, 将其二进制数据添加到client已加载的数据中

### 使用方法:
```  
[NSURLProtocol registerClass:[LJURLCacheProtocol class]];
```  

### 具体实现:
```  
//判断加载未加载过的图片
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
    //获取SDImageCache本地缓存
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
        //此处处理未加载过的图片请求
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
```  
### 以下是NSURLSession协议方法
```  
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
```  

# 支持WKWebView 

注册Scheme方式可行, 但是引入了私有API, 可能上架被拒
### 注意:
#### WKWebView拦截只在第一次加载时走startLoading方法, 此时依然可以在NSURLSessionDataDelegate方法中将图片缓存到本地

iOS 11后可以通过setURLSchemeHandler:forURLScheme:方法进行处理, 如下:

```
WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
if (@available(iOS 11.0, *)) {
    LJWKURLSchemeHandler *handler = [[LJWKURLSchemeHandler alloc] init];
    [configuration setURLSchemeHandler:handler forURLScheme:@"ljwebimageclick"];
} else {
    // Fallback on earlier versions
}
```

对于LJWKURLSchemeHandler实现如下:

```
//
//  LJWKURLSchemeHandler.h

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LJWKURLSchemeHandler : NSObject<WKURLSchemeHandler>

@end

NS_ASSUME_NONNULL_END
```

```
//
//  LJWKURLSchemeHandler.m

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
```
