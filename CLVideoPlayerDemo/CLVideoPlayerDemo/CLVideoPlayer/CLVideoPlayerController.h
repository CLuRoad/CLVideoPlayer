//
//  CLVideoPlayerController.h
//  CLVideoPlayerDemo
//
//  Created by RoadClu on 2017/9/18.
//  Copyright © 2017年 worldunion. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CLVideoPlayerDelegate <NSObject>

// 全屏回调
- (void)didFullScreen;

// 缩放回调
- (void)didShrinkScreen;

@end

@interface CLVideoPlayerController : UIViewController

@property (nonatomic, assign) CGRect frame;
@property (nonatomic, weak) id<CLVideoPlayerDelegate> delegate;

@property (nonatomic, strong) UIImageView *movieBackgroundView;

- (instancetype)initWithContentUrl:(NSURL *)url;

// 关闭视频
- (void)close;

- (void)setUrl:(NSURL *)url;

@end
