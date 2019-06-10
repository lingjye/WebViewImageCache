//
//  WKHandlerViewController.m
//  WebViewImageCache
//
//  Created by txooo on 2019/6/10.
//  Copyright © 2019 lingjye. All rights reserved.
//

#import "WKHandlerViewController.h"
#import <WebKit/WebKit.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "NSURLProtocol+WKWebview.h"
#import "LJWKURLSchemeHandler.h"

@interface WKHandlerViewController () <WKNavigationDelegate, WKUIDelegate>
@property (nonatomic, strong) WKWebView *wkWebView;
@end

@implementation WKHandlerViewController

- (void)dealloc {
    NSLog(@"%s", __func__);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.edgesForExtendedLayout = UIRectEdgeAll;
    if (@available(ios 11.0, *)) {
        [[UIScrollView appearance] setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentAutomatic];
    }

    self.view.backgroundColor = UIColor.whiteColor;

    [self.view addSubview:self.wkWebView];

    [self.wkWebView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle]
                                                                                        pathForResource:@"demo_2"
                                                                                                 ofType:@"html"]]]];
}

- (void)webView:(WKWebView *)webView
    decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
                    decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSString *absoluteString = navigationAction.request.URL.absoluteString;
    if ([absoluteString hasPrefix:@"ljwebimageclick:"]) {
        //获取点击图片index
        NSURL *url = [NSURL URLWithString:[absoluteString substringFromIndex:@"ljWebImageClick:".length]];
        [self showBigImageWithUrl:url];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)showBigImageWithUrl:(NSURL *)url {
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    imageView.backgroundColor = [UIColor blackColor];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.userInteractionEnabled = YES;
    [imageView sd_setImageWithURL:url placeholderImage:nil];
    [[UIApplication sharedApplication].keyWindow addSubview:imageView];
    
    imageView.alpha = 0;

    [UIView animateWithDuration:0.3
                     animations:^{
                         imageView.alpha = 1;
                     }];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapImage:)];
    [imageView addGestureRecognizer:tap];
}

- (void)tapImage:(UITapGestureRecognizer *)tap {
    UIImageView *imageView = (UIImageView *)tap.view;
    [UIView animateWithDuration:0.2
        animations:^{
            imageView.alpha = 0;
        }
        completion:^(BOOL finished) {
            [imageView removeFromSuperview];
        }];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    static NSString *const jsGetImages = @"function clickFunc(){\
    var objs = document.getElementsByTagName(\"img\");\
    for(var i=0;i<objs.length;i++){\
    +function( _i ){\
    objs[ _i ].onclick = function(){\
    document.location=objs[_i].src;\
    };\
    } ( i );\
    };\
    };";
    [webView evaluateJavaScript:jsGetImages
              completionHandler:^(id _Nullable obj, NSError *_Nullable error) {
                  if (error) {
                      NSLog(@"%@", error.localizedDescription);
                  } else {
                      [webView evaluateJavaScript:@"clickFunc()"
                                completionHandler:^(id _Nullable result, NSError *_Nullable error) {
                                    if (error) {
                                        NSLog(@"%@", error.localizedDescription);
                                    }
                                }];
                  }
              }];
}

- (WKWebView *)wkWebView {
    if (!_wkWebView) {
        //        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
        WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
        configuration.userContentController = [[WKUserContentController alloc] init];
        LJWKURLSchemeHandler *handler = [[LJWKURLSchemeHandler alloc] init];
        if (@available(iOS 11.0, *)) {
            [configuration setURLSchemeHandler:handler forURLScheme:@"ljwebimageclick"];
        } else {
            // Fallback on earlier versions
        }

        WKPreferences *preferences = [WKPreferences new];
        preferences.javaScriptCanOpenWindowsAutomatically = YES;
        preferences.minimumFontSize = 30.0;
        configuration.preferences = preferences;

        _wkWebView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:configuration];
        if ([_wkWebView respondsToSelector:@selector(setNavigationDelegate:)]) {
            [_wkWebView setNavigationDelegate:self];
        }

        if ([_wkWebView respondsToSelector:@selector(setDelegate:)]) {
            [_wkWebView setUIDelegate:self];
        }
    }
    return _wkWebView;
}

@end
