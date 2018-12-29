//
//  ViewController.m
//  WebViewImageCache
//
//  Created by txooo on 2018/11/10.
//  Copyright © 2018年 lingjye. All rights reserved.
//

#import "WebViewController.h"
#import "LJURLCacheProtocol.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface WebViewController ()<UIWebViewDelegate>
@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) NSMutableArray *imageUrls;

@end

@implementation WebViewController

- (void)dealloc {
    NSLog(@"%s", __func__);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
//    [NSURLProtocol registerClass:[LJURLCacheProtocol class]];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
//    [NSURLProtocol unregisterClass:[LJURLCacheProtocol class]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self.view addSubview:self.webView];
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"demo" ofType:@"html"]]]];
}

#pragma mark UIWebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    //将url转换为string
    NSString *requestString = [[request URL] absoluteString];
    //hasPrefix 判断创建的字符串内容是否以pic:字符开始
    if ([requestString hasPrefix:@"ljwebimageclick:"]) {
        //获取点击图片index
        NSInteger index = [[requestString substringFromIndex:@"ljWebImageClick:".length] integerValue];
        if (index > self.imageUrls.count) {
            index = 0;
        }
        [self showBigImageWithUrl:self.imageUrls[index]];
        return NO;
    }
    return YES;
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

-(void)webViewDidFinishLoad:(UIWebView *)webView {
    //js方法遍历图片添加点击事件 返回图片个数
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
    
    [webView stringByEvaluatingJavaScriptFromString:jsGetImages];//注入js方法
    
    NSString *urlResult = [webView stringByEvaluatingJavaScriptFromString:@"getImages()"];
    NSMutableArray *mutImgs = [NSMutableArray arrayWithArray:[urlResult componentsSeparatedByString:@";"]];
    [mutImgs removeObject:@""];
    [self.imageUrls addObjectsFromArray:mutImgs];
    NSLog(@"---调用js方法--%@  %s  jsMehtods_result = %@",self.class,__func__, mutImgs);
    // new for memory cleaning
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"WebKitCacheModelPreferenceKey"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (UIWebView *)webView {
    if (!_webView) {
        _webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
        _webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _webView.scalesPageToFit = YES;
        _webView.delegate = self;
        _webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
        if (@available(iOS 11.0, *)) {
            _webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    return _webView;
}

- (NSMutableArray *)imageUrls {
    if (!_imageUrls) {
        _imageUrls = [[NSMutableArray alloc] init];
    }
    return _imageUrls;
}

@end
