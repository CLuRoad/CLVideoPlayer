//
//  CLVideoPlayerController.m
//  CLVideoPlayerDemo
//
//  Created by RoadClu on 2017/9/18.
//  Copyright © 2017年 worldunion. All rights reserved.
//

#import "CLVideoPlayerController.h"
#import "CLPlayerView.h"

@interface CLVideoPlayerController ()

@property (nonatomic, strong) CLPlayerView *playerView;
@property (nonatomic, strong) AVPlayerItem *playerItem;

@property (nonatomic, assign) BOOL isFullscreenMode;
@property (nonatomic, assign) CGRect originFrame;
@property (nonatomic, assign) CGFloat duration;//总时长 秒
@property (nonatomic, strong) NSTimer *durationTimer;

@property (nonatomic, strong) NSURL *contentUrl;
@property (nonatomic ,strong) id playbackTimeObserver;

@end

@implementation CLVideoPlayerController

- (instancetype)initWithContentUrl:(NSURL *)url {
    self = [super init];
    if (self) {
        _contentUrl = url;
        [self.view addSubview:self.playerView];
        

    }
    return self;
}


- (void)setFrame:(CGRect)frame {
    _frame = frame;
    self.view.frame = frame;
    self.playerView.frame = self.view.bounds;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.playerItem = [AVPlayerItem playerItemWithURL:_contentUrl];
    self.playerView.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    
    
    [self configObserver];
    [self configControlAction];
}



#pragma mark ---- 监听 && 通知
- (void)configObserver {
    // KVO
    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil]; //监听status属性
    [self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil]; //监听loadedTimeRanges属性
    
    // 通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    if ([keyPath isEqualToString:@"status"]) {
        if ([playerItem status] == AVPlayerStatusReadyToPlay) {
            NSLog(@"AVPlayerStatusReadyToPlay");
            self.playerView.playButton.enabled = YES;
            CMTime duration = self.playerItem.duration;
            _duration = CMTimeGetSeconds(duration);
            [self setSliderMaxMinValues];
            [self monitoringPlayback:self.playerItem];// 监听播放状态
            
        } else if ([playerItem status] == AVPlayerStatusFailed) {
            NSLog(@"AVPlayerStatusFailed");
        }
        
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        NSTimeInterval timeInterval = [self availableDuration];// 计算缓冲进度
        NSLog(@"Time Interval:%f",timeInterval);
        CMTime duration = _playerItem.duration;
        CGFloat totalDuration = CMTimeGetSeconds(duration);
        [self.playerView.progress setProgress:timeInterval / totalDuration animated:YES];

    }
}

- (void)monitoringPlayback:(AVPlayerItem *)playerItem {
    
    __weak typeof(self) weakSelf = self;
    self.playbackTimeObserver = [self.playerView.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:NULL usingBlock:^(CMTime time) {
        CGFloat currentSecond = playerItem.currentTime.value/playerItem.currentTime.timescale;// 计算当前在第几秒
        [weakSelf.playerView.slider setValue:currentSecond animated:YES];
        [weakSelf setTimeLabelValues:currentSecond totalTime:weakSelf.duration];
    }];
}

- (void)moviePlayDidEnd:(NSNotification *)notification {
    NSLog(@"Play end");
    
    __weak typeof(self) weakSelf = self;
    [self.playerView.player seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
        [weakSelf.playerView.slider setValue:0.0 animated:YES];
        weakSelf.playerView.playButton.hidden = NO;
        weakSelf.playerView.pauseButton.hidden = YES;
    }];
}

- (NSTimeInterval)availableDuration {
    NSArray *loadedTimeRanges = [[self.playerView.player currentItem] loadedTimeRanges];
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
    float startSeconds = CMTimeGetSeconds(timeRange.start);
    float durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result = startSeconds + durationSeconds;// 计算缓冲总进度
    return result;
}


#pragma mark ----- 自定义按钮 Action
- (void)configControlAction {
    [self.playerView.playButton addTarget:self action:@selector(playButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.playerView.pauseButton addTarget:self action:@selector(pauseButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.playerView.fullScreenButton addTarget:self action:@selector(fullScreenButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.playerView.shrinkScreenButton addTarget:self action:@selector(shrinkScreenButtonClick) forControlEvents:UIControlEventTouchUpInside];
    
    
    [self.playerView.slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.playerView.slider addTarget:self action:@selector(sliderTouchBegan:) forControlEvents:UIControlEventTouchDown];
    [self.playerView.slider addTarget:self action:@selector(sliderTouchEnded:) forControlEvents:UIControlEventTouchUpInside];
    [self.playerView.slider addTarget:self action:@selector(sliderTouchEnded:) forControlEvents:UIControlEventTouchUpOutside];
    
    
}

// 播放
- (void)playButtonClick {
    [self.playerView.player play];
    self.playerView.playButton.hidden = YES;
    self.playerView.pauseButton.hidden = NO;
    self.playerView.isPauseing = NO;
}

// 暂停
- (void)pauseButtonClick {
    [self.playerView.player pause];
    self.playerView.playButton.hidden = NO;
    self.playerView.pauseButton.hidden = YES;
    self.playerView.isPauseing = YES;
}

// 全屏
- (void)fullScreenButtonClick {
    
    if (self.isFullscreenMode) {
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(didFullScreen)]) {
        [self.delegate didFullScreen];
    }
    
    self.originFrame = self.view.frame;
    CGFloat height = [[UIScreen mainScreen] bounds].size.width;
    CGFloat width = [[UIScreen mainScreen] bounds].size.height;
    CGRect frame = CGRectMake((height - width) / 2, (width - height) / 2, width, height);
    
    [UIView animateWithDuration:0.3f animations:^{
        self.frame = frame;
        self.movieBackgroundView.frame = CGRectMake(0, 0, width, height);
        [self.view setTransform:CGAffineTransformMakeRotation(M_PI_2)];
    } completion:^(BOOL finished) {
        self.isFullscreenMode = YES;
        self.playerView.fullScreenButton.hidden = YES;
        self.playerView.shrinkScreenButton.hidden = NO;
    }];
}

// 小屏
- (void)shrinkScreenButtonClick {
    if (!self.isFullscreenMode) {
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(didShrinkScreen)]) {
        [self.delegate didShrinkScreen];
    }
    
    [UIView animateWithDuration:0.3f animations:^{
        [self.view setTransform:CGAffineTransformIdentity];
        self.frame = self.originFrame;
        self.movieBackgroundView.frame = self.view.bounds;
    } completion:^(BOOL finished) {
        self.isFullscreenMode = NO;
        self.playerView.fullScreenButton.hidden = NO;
        self.playerView.shrinkScreenButton.hidden = YES;
    }];
}

// Slider
- (void)setSliderMaxMinValues {
    self.playerView.slider.minimumValue = 0.f;
    self.playerView.slider.maximumValue = floor(_duration);
}

- (void)sliderTouchBegan:(UISlider *)slider {
    [self.playerView.player pause];
    [self.playerView cancelAutoFadeOutControlBar];
    
}

- (void)sliderTouchEnded:(UISlider *)slider {
    CMTime changedTime = CMTimeMakeWithSeconds(slider.value, 1);
    [self.playerView.player seekToTime:changedTime completionHandler:^(BOOL finished) {
        [self.playerView.player play];
        [self.playerView autoFadeOutControlBar];
    }];
}

- (void)sliderValueChanged:(UISlider *)slider {
    [self setTimeLabelValues:slider.value totalTime:_duration];
}


- (void)setTimeLabelValues:(CGFloat)currentTime totalTime:(CGFloat)totalTime {
    double minutesElapsed = floor(currentTime / 60.0);
    double secondsElapsed = fmod(currentTime, 60.0);
    NSString *timeElapsedString = [NSString stringWithFormat:@"%02.0f:%02.0f", minutesElapsed, secondsElapsed];
    
    double minutesRemaining = floor(totalTime / 60.0);;
    double secondsRemaining = floor(fmod(totalTime, 60.0));;
    NSString *timeRmainingString = [NSString stringWithFormat:@"%02.0f:%02.0f", minutesRemaining, secondsRemaining];
    
    self.playerView.timeLabel.text = [NSString stringWithFormat:@"%@/%@",timeElapsedString,timeRmainingString];
}


#pragma mark --- Property
- (UIImageView *)movieBackgroundView {
    if (!_movieBackgroundView) {
        _movieBackgroundView = [[UIImageView alloc] init];
        _movieBackgroundView.backgroundColor = [UIColor clearColor];
    }
    return _movieBackgroundView;
}

- (CLPlayerView *)playerView {
    if (!_playerView) {
        _playerView = [CLPlayerView new];
    }
    return _playerView;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
