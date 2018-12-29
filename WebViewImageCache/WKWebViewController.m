//
//  WKWebViewController.m
//  WebViewImageCache
//
//  Created by txooo on 2018/12/28.
//  Copyright © 2018 lingjye. All rights reserved.
//

#import "WKWebViewController.h"
#import <WebKit/WebKit.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "NSURLProtocol+WKWebview.h"

@interface WKWebViewController ()<WKNavigationDelegate, WKUIDelegate>
@property (nonatomic, strong) WKWebView *wkWebView;
@property (nonatomic, strong) NSMutableArray *imageUrls;
@end

@implementation WKWebViewController

- (void)dealloc {
    NSLog(@"%s", __func__);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.edgesForExtendedLayout = UIRectEdgeAll;
    if (@available(ios 11.0,*)) {
        [[UIScrollView appearance] setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentAutomatic];
    }
    
    self.view.backgroundColor = UIColor.whiteColor;
    
    [NSURLProtocol wk_registerScheme:@"http"];
    [NSURLProtocol wk_registerScheme:@"https"];
    
    [self.view addSubview:self.wkWebView];
    
    [self.wkWebView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"demo_1" ofType:@"html"]]]];
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    NSLog(@"%@", webView.URL.absoluteString);
    NSString *absoluteString = webView.URL.absoluteString;
    if ([absoluteString hasPrefix:@"ljwebimageclick:"]) {
        //获取点击图片index
        NSInteger index = [[absoluteString substringFromIndex:@"ljWebImageClick:".length] integerValue];
        if (index > self.imageUrls.count) {
            index = 0;
        }
        [self showBigImageWithUrl:self.imageUrls[index]];
    }
}

- (void)showBigImageWithUrl:(NSString *)url {
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    imageView.backgroundColor = [UIColor blackColor];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.userInteractionEnabled = YES;
    [imageView sd_setImageWithURL:[NSURL URLWithString:url] placeholderImage:nil];
    [[UIApplication sharedApplication].keyWindow addSubview:imageView];
    
    imageView.alpha = 0;
    
    [UIView animateWithDuration:0.3 animations:^{
        imageView.alpha = 1;
    }];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapImage:)];
    [imageView addGestureRecognizer:tap];
}

- (void)tapImage:(UITapGestureRecognizer *)tap {
    UIImageView *imageView = (UIImageView *)tap.view;
    [UIView animateWithDuration:0.2 animations:^{
        imageView.alpha = 0;
    } completion:^(BOOL finished) {
        [imageView removeFromSuperview];
    }];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    static  NSString * const jsGetImages =
    @"function getImages(){\
    var objs = document.getElementsByTagName(\"img\");\
    var imgSrc = '';\
    for(var i=0;i<objs.length;i++){\
    imgSrc = imgSrc + objs[i].src + ';';\
    +function( _i ){\
    objs[ _i ].onclick = function(){\
    document.location=\"ljWebImageClick:\" + _i;\
    };\
    } ( i );\
    };\
    return imgSrc;\
    };";
    [webView evaluateJavaScript:jsGetImages completionHandler:^(id _Nullable obj, NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error.localizedDescription);
        }else {
            [webView evaluateJavaScript:@"getImages()" completionHandler:^(id _Nullable result, NSError * _Nullable error) {
                NSMutableArray *mutImgs = [NSMutableArray arrayWithArray:[result componentsSeparatedByString:@";"]];
                [mutImgs removeObject:@""];
                [self.imageUrls addObjectsFromArray:mutImgs];
            }];
        }
    }];
}

- (WKWebView *)wkWebView {
    if (!_wkWebView) {
        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
        WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
        configuration.userContentController = [[WKUserContentController alloc] init];

        WKPreferences *preferences = [WKPreferences new];
        preferences.javaScriptCanOpenWindowsAutomatically = YES;
        preferences.minimumFontSize = 30.0;
        configuration.preferences = preferences;

        _wkWebView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:config];
        if ([_wkWebView respondsToSelector:@selector(setNavigationDelegate:)]) {
            [_wkWebView setNavigationDelegate:self];
        }

        if ([_wkWebView respondsToSelector:@selector(setDelegate:)]) {
            [_wkWebView setUIDelegate:self];
        }
    }
    return _wkWebView;
}

- (NSMutableArray *)imageUrls {
    if (!_imageUrls) {
        _imageUrls = [NSMutableArray array];
    }
    return _imageUrls;
}

@end
