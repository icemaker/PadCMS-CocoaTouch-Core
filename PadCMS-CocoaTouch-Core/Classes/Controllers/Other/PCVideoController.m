//
//  PCVideoContoller.m
//  Pad CMS
//
//  Created by Igor Getmanenko on 10.02.12.
//  Copyright 2012 Adyax. All rights reserved.
//

#import "PCVideoController.h"
#import "Reachability.h"
//#import "VersionManager.h"
#import "PCBrowserViewController.h"
#import "PCDownloadApiClient.h"

@interface PCVideoController () 

- (BOOL) isConnectionEstablished;
- (void) fullScreenMovie:(NSNotification *) notification;
- (void) pushVideoScreen:(NSNotification *) notification;
- (void) startPlayingVideo;
- (void) stopPlayingVideo;
- (void) videoHasFinishedPlaying:(NSNotification *) paramNotification;
- (void) videoHasChanged:(NSNotification *) paramNotification;
- (void) videoHasExitedFullScreen:(NSNotification *) paramNotification;

@end

@implementation PCVideoController

@synthesize moviePlayer = _moviePlayer;
@synthesize url = _url;
@synthesize isVideoPlaying = _isVideoPlaying;
@synthesize delegate = _delegate;

- (id) init
{
    self = [super init];
    
    if (self)
    {
        _moviePlayer = nil;
        _url = nil;
        _delegate = nil;
        _isVideoPlaying = NO;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fullScreenMovie:) name:PCVCFullScreenMovieNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pushVideoScreen:) name:PCVCPushVideoScreenNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoHasFinishedPlaying:) name:MPMoviePlayerPlaybackDidFinishNotification object:self.moviePlayer];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoHasChanged:) name:MPMoviePlayerLoadStateDidChangeNotification object:self.moviePlayer];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoHasExitedFullScreen:) name:MPMoviePlayerDidExitFullscreenNotification object:self.moviePlayer];
    }
    
    return  self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_moviePlayer release], _moviePlayer = nil;
    [_url release], _url = nil;
    _isVideoPlaying = NO;
    
    [super dealloc];
}

- (BOOL) isConnectionEstablished
{
	
	AFNetworkReachabilityStatus remoteHostStatus = [PCDownloadApiClient sharedClient].networkReachabilityStatus;
   // NetworkStatus remoteHostStatus = [[VersionManager sharedManager].reachability currentReachabilityStatus];
    
	if(remoteHostStatus == AFNetworkReachabilityStatusNotReachable) 
	{
		UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Vous devez être connecté à Internet pour partager ce contenu." message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		[alert release];
		return NO;
	}
    
    return YES;
}

- (void) fullScreenMovie:(NSNotification*) notification
{   
	self.url = (NSURL *)notification.object;
	NSLog(@"url = %@", self.url);
    if (![[self.url absoluteString] hasPrefix:@"file://"] &&  ![self isConnectionEstablished] )
    {
        return;
    }
    [self startPlayingVideo];
}

- (void) pushVideoScreen:(NSNotification*) notification
{
	NSString* theURL = (NSString*)notification.object;
    if (![theURL hasPrefix:@"file://"] &&  ![self isConnectionEstablished] )
    {
        return;
    }	
    
	PCBrowserViewController* bvc = [[PCBrowserViewController alloc] initWithNibName:nil bundle:nil];
	[bvc view];
	[bvc presentURL:theURL];
    
//    [self.delegate videoControllerWillShow:bvc animated:YES];
    
	[bvc release];
}


- (void) startPlayingVideo
{
    if (self.isVideoPlaying)
    {
        return;
    }
    
    
    if (self.moviePlayer != nil)
    {
        [self stopPlayingVideo];
    }
    
    MPMoviePlayerController *newMoviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:self.url];
    self.moviePlayer = newMoviePlayer;
    [newMoviePlayer release];
    [self.moviePlayer prepareToPlay];
    
    if ([self.delegate respondsToSelector:@selector(videoControllerShow:)]) 
    {
        [self.delegate videoControllerShow:self];
    }
    
    self.isVideoPlaying = YES;
    
    if (self.moviePlayer != nil)
    {
        
        NSLog(@"Successfully instantiated the movie player.");
        /* Scale the movie player to fit the aspect ratio */
        //self.moviePlayer.scalingMode = MPMovieScalingModeAspectFit;
        /* Let's start playing the video in full screen mode */
        [self.moviePlayer play];
        [self.moviePlayer setFullscreen:YES animated:YES];
        [self.moviePlayer setControlStyle:MPMovieControlStyleFullscreen];
    }
    else
    {
        NSLog(@"Failed to instantiate the movie player.");
    }
}

- (void) stopPlayingVideo
{
    if (self.moviePlayer != nil)
    {
        self.isVideoPlaying = NO;
        [self.moviePlayer stop];
        [self.moviePlayer setControlStyle:MPMovieControlStyleEmbedded];

        if ([self.delegate respondsToSelector:@selector(videoControllerHide:)]) 
        {
            [self.delegate videoControllerHide:self];
        }
    }
}

#pragma mark - notification functions
- (void) videoHasFinishedPlaying:(NSNotification *)paramNotification
{
    NSNumber *reason = [paramNotification.userInfo
                        valueForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey];
    if (reason != nil)
    {
        NSInteger reasonAsInteger = [reason integerValue];
        switch (reasonAsInteger)
        {
            case MPMovieFinishReasonPlaybackEnded:
            {
                /* The movie ended normally */ 
                NSLog(@"MPMovieFinishReasonPlaybackEnded");
                break;
            } 
            case MPMovieFinishReasonPlaybackError:
            {
                /* An error happened and the movie ended */ 
                NSLog(@"MPMovieFinishReasonPlaybackError");
                break;
            } 
            case MPMovieFinishReasonUserExited:
            {
                /* The user exited the player */ 
                NSLog(@"MPMovieFinishReasonUserExited");
                break;
            }
            
        }
        [self stopPlayingVideo];
        return;
    }
}

-(void)videoHasChanged:(NSNotification *)paramNotification
{
    if (self.moviePlayer.loadState & MPMovieLoadStatePlayable)
    {
        NSLog(@"MPMovieLoadStatePlayable");
        return;
    }
    if (self.moviePlayer.loadState & MPMovieLoadStateUnknown)
    {
        NSLog(@"MPMovieLoadStateUnknown");
    }
    if (self.moviePlayer.loadState & MPMovieLoadStateStalled)
    {
        NSLog(@"MPMovieLoadStateStalled");
    }
    if (self.moviePlayer.loadState & MPMovieLoadStatePlaythroughOK)
    {
        NSLog(@"MPMovieLoadStatePlaythroughOK");
    }
}

-(void)videoHasExitedFullScreen:(NSNotification *)paramNotification
{
    [self stopPlayingVideo];
}

@end
