//
//  RootViewController.m
//  WebViewImageCache
//
//  Created by txooo on 2018/12/28.
//  Copyright © 2018 lingjye. All rights reserved.
//

#import "RootViewController.h"
#import "WebViewController.h"
#import "WKWebViewController.h"
#import "WKHandlerViewController.h"

@interface RootViewController ()
{
    NSArray<Class> *_viewControllers;
}
@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
//    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.navigationItem.title = @"WebViewImageCache";
    
    _viewControllers = @[ [WebViewController class],
                          [WKWebViewController class],
                          [WKHandlerViewController class] ];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _viewControllers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellID = @"cellID";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    cell.textLabel.text = NSStringFromClass(_viewControllers[indexPath.row]);
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    Class class = _viewControllers[indexPath.row];
    UIViewController *viewController = [[class alloc] init];
    viewController.title = NSStringFromClass(class);
    [self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark - Navigation
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

@end
