//
//  CLVideoPlayer.m
//  CLVideoPlayerDemo
//
//  Created by RoadClu on 2017/9/18.
//  Copyright © 2017年 worldunion. All rights reserved.
//

#import "CLPlayerView.h"

static const CGFloat kVideoControlBarHeight = 40.0;
static const CGFloat kVideoControlAnimationTimeInterval = 0.3;
static const CGFloat kVideoControlTimeLabelFontSize = 10.0;
static const CGFloat kVideoControlBarAutoFadeOutTimeInterval = 5.0;

@interface CLPlayerView ()

@property (nonatomic, strong) UIView *bottomBar;
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) UIButton *pauseButton;
@property (nonatomic, strong) UIButton *fullScreenButton;
@property (nonatomic, strong) UIButton *shrinkScreenButton;
@property (nonatomic, strong) UISlider *slider;
@property (nonatomic, strong) UIProgressView *progress;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, assign) BOOL isBarShowing;
@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;

@end


@implementation CLPlayerView

#pragma mark ---- layer层设置
+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (AVPlayer *)player {
    return [(AVPlayerLayer *)[self layer] player];
}

- (void)setPlayer:(AVPlayer *)player {
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}

#pragma mark ---- 创建子视图
- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self addSubview:self.bottomBar];
        [self.bottomBar addSubview:self.playButton];
        [self.bottomBar addSubview:self.pauseButton];
        self.pauseButton.hidden = YES;
        [self.bottomBar addSubview:self.fullScreenButton];
        [self.bottomBar addSubview:self.shrinkScreenButton];
        self.shrinkScreenButton.hidden = YES;
        [self.bottomBar addSubview:self.progress];
        [self.bottomBar addSubview:self.slider];
        [self.bottomBar addSubview:self.timeLabel];
        [self addSubview:self.indicatorView];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap:)];
        [self addGestureRecognizer:tapGesture];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.bottomBar.frame = CGRectMake(CGRectGetMinX(self.bounds), CGRectGetHeight(self.bounds) - kVideoControlBarHeight, CGRectGetWidth(self.bounds), kVideoControlBarHeight);
    self.playButton.frame = CGRectMake(CGRectGetMinX(self.bottomBar.bounds), CGRectGetHeight(self.bottomBar.bounds)/2 - CGRectGetHeight(self.playButton.bounds)/2, CGRectGetWidth(self.playButton.bounds), CGRectGetHeight(self.playButton.bounds));
    self.pauseButton.frame = self.playButton.frame;
    self.fullScreenButton.frame = CGRectMake(CGRectGetWidth(self.bottomBar.bounds) - CGRectGetWidth(self.fullScreenButton.bounds), CGRectGetHeight(self.bottomBar.bounds)/2 - CGRectGetHeight(self.fullScreenButton.bounds)/2, CGRectGetWidth(self.fullScreenButton.bounds), CGRectGetHeight(self.fullScreenButton.bounds));
    self.shrinkScreenButton.frame = self.fullScreenButton.frame;
    self.slider.frame = CGRectMake(CGRectGetMaxX(self.playButton.frame), CGRectGetHeight(self.bottomBar.bounds)/2 - CGRectGetHeight(self.slider.bounds)/2, CGRectGetMinX(self.fullScreenButton.frame) - CGRectGetMaxX(self.playButton.frame), CGRectGetHeight(self.slider.bounds));
    CGRect progressFrame = self.slider.frame;
    progressFrame.size.height = 2.0;
    self.progress.frame = progressFrame;
    self.progress.center = self.slider.center;
    
    self.timeLabel.frame = CGRectMake(CGRectGetMidX(self.slider.frame), CGRectGetHeight(self.bottomBar.bounds) - CGRectGetHeight(self.timeLabel.bounds) - 2.0, CGRectGetWidth(self.slider.bounds)/2, CGRectGetHeight(self.timeLabel.bounds));
    self.indicatorView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    self.isBarShowing = YES;
}

- (void)animateHide {
    if (self.isPauseing) {
        return;
    }
    
    if (!self.isBarShowing) {
        return;
    }
    
    [UIView animateWithDuration:kVideoControlAnimationTimeInterval animations:^{
        self.bottomBar.alpha = 0.0;
    } completion:^(BOOL finished) {
        self.isBarShowing = NO;
    }];
}

- (void)animateShow {
    if (self.isBarShowing) {
        return;
    }
    
    [UIView animateWithDuration:kVideoControlAnimationTimeInterval animations:^{
        self.bottomBar.alpha = 1.0;
    } completion:^(BOOL finished) {
        self.isBarShowing = YES;
        [self autoFadeOutControlBar];
    }];
}

- (void)autoFadeOutControlBar {
    if (!self.isBarShowing) {
        return;
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(animateHide) object:nil];
    [self performSelector:@selector(animateHide) withObject:nil afterDelay:kVideoControlBarAutoFadeOutTimeInterval];
}

- (void)cancelAutoFadeOutControlBar{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(animateHide) object:nil];
}

- (void)onTap:(UITapGestureRecognizer *)gesture{
    if (gesture.state == UIGestureRecognizerStateRecognized) {
        if (self.isBarShowing) {
            [self animateHide];
        } else {
            [self animateShow];
        }
    }
}

#pragma mark ----- Property
- (UIView *)bottomBar
{
    if (!_bottomBar) {
        _bottomBar = [UIView new];
        _bottomBar.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3];
    }
    return _bottomBar;
}

- (UIButton *)playButton
{
    if (!_playButton) {
        _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playButton setImage:[UIImage imageNamed:@"video-player-play"] forState:UIControlStateNormal];
        _playButton.bounds = CGRectMake(0, 0, kVideoControlBarHeight, kVideoControlBarHeight);
    }
    return _playButton;
}

- (UIButton *)pauseButton
{
    if (!_pauseButton) {
        _pauseButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_pauseButton setImage:[UIImage imageNamed:@"video-player-pause"] forState:UIControlStateNormal];
        _pauseButton.bounds = CGRectMake(0, 0, kVideoControlBarHeight, kVideoControlBarHeight);
    }
    return _pauseButton;
}

- (UIButton *)fullScreenButton
{
    if (!_fullScreenButton) {
        _fullScreenButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_fullScreenButton setImage:[UIImage imageNamed:@"video-player-fullscreen"] forState:UIControlStateNormal];
        _fullScreenButton.bounds = CGRectMake(0, 0, kVideoControlBarHeight, kVideoControlBarHeight);
    }
    return _fullScreenButton;
}

- (UIButton *)shrinkScreenButton
{
    if (!_shrinkScreenButton) {
        _shrinkScreenButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_shrinkScreenButton setImage:[UIImage imageNamed:@"video-player-shrinkscreen"] forState:UIControlStateNormal];
        _shrinkScreenButton.bounds = CGRectMake(0, 0, kVideoControlBarHeight, kVideoControlBarHeight);
    }
    return _shrinkScreenButton;
}

- (UISlider *)slider
{
    if (!_slider) {
        _slider = [[UISlider alloc] init];
        [_slider setThumbImage:[UIImage imageNamed:@"video-player-point"] forState:UIControlStateNormal];
        [_slider setMinimumTrackTintColor:[UIColor whiteColor]];
        [_slider setMaximumTrackTintColor:[UIColor clearColor]];
        _slider.value = 0.f;
        _slider.continuous = YES;
    }
    return _slider;
}

- (UIProgressView *)progress {
    if (!_progress) {
        _progress = [[UIProgressView alloc] init];
        [_progress setTrackTintColor:[UIColor lightGrayColor]];
        [_progress setProgressTintColor:[UIColor blueColor]];
    }
    return _progress;
}


- (UILabel *)timeLabel
{
    if (!_timeLabel) {
        _timeLabel = [UILabel new];
        _timeLabel.backgroundColor = [UIColor clearColor];
        _timeLabel.font = [UIFont systemFontOfSize:kVideoControlTimeLabelFontSize];
        _timeLabel.textColor = [UIColor whiteColor];
        _timeLabel.textAlignment = NSTextAlignmentRight;
        _timeLabel.bounds = CGRectMake(0, 0, kVideoControlTimeLabelFontSize, kVideoControlTimeLabelFontSize);
    }
    return _timeLabel;
}

- (UIActivityIndicatorView *)indicatorView
{
    if (!_indicatorView) {
        _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [_indicatorView stopAnimating];
    }
    return _indicatorView;
}





























@end
