//
//  IPCaptureMainViewController.m
//  IPCaptureDemo
//
//  Created by An Xu on 27/07/2016.
//  Copyright © 2016 Hudl. All rights reserved.
//

#import "IPCaptureMainViewController.h"

#import "HTTPServer.h"
#import "DDLog.h"
#import "DDTTYLogger.h"

@import AVFoundation;
@import AVKit;

@interface IPCaptureMainViewController ()

@property (strong) IBOutlet NSView *previewView;
@property (strong) IBOutlet NSView *topBannerView;
@property (strong) IBOutlet NSTextField *addressTextField;
@property (nonatomic, strong) NSTask *ffmpegTask;
@property (strong) IBOutlet NSProgressIndicator *progressIndicator;
@property (strong) IBOutlet NSButton *stopButton;
@property (nonatomic, strong) HTTPServer *httpServer;
@property (nonatomic, strong) AVPlayer *player;

@end

@implementation IPCaptureMainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.stopButton setHidden:YES];
    [self.progressIndicator stopAnimation:nil];
}

- (IBAction)goButtonClicked:(NSButton *)sender
{
    [self startHTTPServer];
    [self.topBannerView setHidden:YES];
    [self.progressIndicator startAnimation:nil];
    [self startWriteFileToDisk];
    [self.stopButton setHidden:NO];
}

- (void)startHTTPServer
{
    self.httpServer = [[HTTPServer alloc] init];
    [self.httpServer setType:@"_http._tcp."];
    [self.httpServer setPort:12345];
    
    // Serve files from the standard Sites folder
    NSString *docRoot = [@"/Users/anxu/Desktop/Demo" stringByExpandingTildeInPath];
    [self.httpServer setDocumentRoot:docRoot];
    NSError *error = nil;
    if(![self.httpServer start:&error])
    {
        [NSApp presentError:error];
    }

}
- (IBAction)stopButtonClicked:(NSButtonCell *)sender
{
    [self.ffmpegTask terminate];
    [self.topBannerView setHidden:NO];
    [self.stopButton setHidden:YES];
    [self.progressIndicator stopAnimation:nil];
    [self.httpServer stop];
}

- (void)startWriteFileToDisk
{
    NSString *ffmpegPath = [[NSBundle mainBundle] pathForResource:@"ffmpeg" ofType:nil];
    NSString *address = [NSString stringWithFormat:@"%@?multicast=1" ,self.addressTextField.stringValue];
    NSString *segmentListFilePath = @"/Users/anxu/Desktop/Demo/demo.m3u8";
    NSString *mpegtsFilePath = @"/Users/anxu/Desktop/Demo/stream%05d.ts";
    
    NSArray *arguments = @[@"-i", address, @"-acodec", @"copy", @"-vcodec",
                           @"copy", @"-f", @"segment", @"-segment_time", @"3",
                           @"-segment_list", segmentListFilePath,
                           @"-segment_format", @"mpegts", mpegtsFilePath];
    self.ffmpegTask = [NSTask launchedTaskWithLaunchPath:ffmpegPath arguments:arguments];
    [self startLookingForFiles:segmentListFilePath];
}

- (void)startLookingForFiles:(NSString *)segmentListFilePath
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if(![[NSFileManager defaultManager] fileExistsAtPath:segmentListFilePath])
        {
            [self startLookingForFiles:segmentListFilePath];
        }
        else
        {
            [self startPlayHLS];
            [self.progressIndicator stopAnimation:nil];
        }
    });
}

- (void)startPlayHLS
{
    self.previewView.wantsLayer = YES;
    NSURL *url = [NSURL URLWithString:@"http://localhost:12345/demo.m3u8"];
    self.player = [AVPlayer playerWithURL:url];
    
    [self.player.currentItem.asset loadValuesAsynchronouslyForKeys:@[@"status"] completionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (self.player.status == AVPlayerStatusReadyToPlay)
            {
                AVPlayerView *playerView = [[AVPlayerView alloc] initWithFrame:self.previewView.bounds];
                playerView.player = self.player;
                [self.previewView addSubview:playerView];
            }

        });
    }];
}

- (IBAction)playButtonClicked:(NSButton *)sender
{
    [self.player play];
}

@end
