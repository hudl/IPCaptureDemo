//
//  AppDelegate.m
//  IPCaptureDemo
//
//  Created by An Xu on 27/07/2016.
//  Copyright © 2016 Hudl. All rights reserved.
//

#import "AppDelegate.h"
#import "IPCaptureMainViewController.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.window.contentViewController = [[IPCaptureMainViewController alloc] initWithNibName:@"IPCaptureMainViewController" bundle:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    //TODO: stop HTTP server and ffmpeg server
}

@end
