//
//  ViewController.m
//  CLVideoPlayerDemo
//
//  Created by RoadClu on 2017/9/18.
//  Copyright © 2017年 worldunion. All rights reserved.
//

#import "ViewController.h"
#import "CLVideoPlayerController.h"

@interface ViewController ()
@property (nonatomic, strong) CLVideoPlayerController *videoPC;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSURL *videoUrl = [NSURL URLWithString:@"http://v.hoto.cn/dc/c7/1099740.mp4"];
    
    _videoPC = [[CLVideoPlayerController alloc] initWithContentUrl:videoUrl];
    _videoPC.frame = CGRectMake(0, 0, 375, 200);
    [self.view addSubview:_videoPC.view];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
