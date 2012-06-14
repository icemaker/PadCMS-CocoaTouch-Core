//
//  PCLanscapeSladeshowColumnViewController.m
//  Pad CMS
//
//  Created by Rustam Mallakurbanov on 12.02.12.
//  Copyright (c) 2012 Adyax. All rights reserved.
//

#import "PCLanscapeSladeshowColumnViewController.h"
#import "PCMagazineViewControllersFactory.h"
#import "PCLandscapeViewController.h"
#import "PCScrollView.h"

@interface PCLanscapeSladeshowColumnViewController()

- (void) unloadFullPageAtIndex:(NSInteger) index;

@end;

@implementation PCLanscapeSladeshowColumnViewController

-(void)dealloc
{
    [player stop];
    [player release];
    player = nil;
    [slideShowPageViewControllers release];
    slideShowPageViewControllers = nil;
    [slideShowPagesScrollView release];
    slideShowPagesScrollView = nil;
    self.view = nil;
    [super dealloc];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

-(id)initWithColumn:(PCColumn*)aColumn
{
    if (self = [super initWithColumn:aColumn]) 
    {
        slideShowPageViewControllers = [[NSMutableArray alloc] init];
        slideShowPagesScrollView = nil;
        soundSource = nil;
    }
    return self;
}

-(void)loadView
{
    [super loadView];
    self.view = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, pageSize.width, pageSize.height)] autorelease];
    mainScrollView = [[PCScrollView alloc] initWithFrame:CGRectMake(0, 0, pageSize.width, pageSize.height)];
    slideShowPagesScrollView = [[PCScrollView alloc] initWithFrame:CGRectMake(0, 0, pageSize.height, pageSize.width)];
    [self.view addSubview:mainScrollView];
}

-(CGSize)pageSizeForViewController:(PCPageViewController*)pageViewController
{
    if ([pageViewControllers indexOfObject:pageViewController] != NSNotFound)
        return pageSize;
    if ([slideShowPageViewControllers indexOfObject:pageViewController] != NSNotFound)
        return CGSizeMake(pageSize.height, pageSize.width);
    return CGSizeZero;
}

-(void)createColumnsView
{
    mainScrollView.contentSize =  CGSizeMake(pageSize.width, pageSize.height);
    slideShowPagesScrollView.contentSize = CGSizeMake(pageSize.height, pageSize.width * ([column.pages count]-1));
    slideShowPagesScrollView.frame = CGRectMake(0, 0, pageSize.height, pageSize.width);
    if ([column.pages count] < 1)
        return;
    PCPage* page  = [column.pages objectAtIndex:0];
    PCPageViewController* pageViewController = [[PCMagazineViewControllersFactory factory] viewControllerForPage:page]; 
    [pageViewController setMagazineViewController:self.magazineViewController];
    [pageViewController setColumnViewController:self];
    [pageViewControllers addObject:pageViewController];
    [pageViewController.view setFrame:CGRectMake(0, pageSize.height * 0, pageSize.width, pageSize.height)];
    [mainScrollView addSubview:pageViewController.view];
    
    
    PCPageElement* soundElement = [page firstElementForType:PCPageElementTypeSound];
    if (soundElement)
    {
        soundSource = [[page.revision.contentDirectory stringByAppendingPathComponent:soundElement.resource] retain];
        player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:soundSource] error:nil];
        [player setNumberOfLoops:-1];
    }
    
    for (unsigned i = 0; i < [column.pages count]-1; i++)
    {
        PCPage* page  = [column.pages objectAtIndex:i+1];
        PCPageViewController* pageViewController = [[PCMagazineViewControllersFactory factory] viewControllerForPage:page]; 
        [pageViewController setMagazineViewController:self.magazineViewController];
        [pageViewController setColumnViewController:self];
        [slideShowPageViewControllers addObject:pageViewController];
        CGRect frame = CGRectMake(0, pageSize.width * i, pageSize.height, pageSize.width);
        [pageViewController.view setFrame:frame];
        [slideShowPagesScrollView addSubview:pageViewController.view];
    }
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void) loadFullPageAtIndex:(NSInteger) index
{
    if (UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation]))
    {
        if(index >= 0 && index < [slideShowPageViewControllers count])
        {
            PCPageViewController *currentPage = [slideShowPageViewControllers objectAtIndex:index];
            [currentPage loadFullView];
        }
    }
    else 
    {
        if(index >= 0 && index < [pageViewControllers count])
        {
            PCPageViewController *currentPage = [pageViewControllers objectAtIndex:index];
            [currentPage loadFullView];
        }
    }

}
- (void) updateViewsForCurrentIndex
{
    NSInteger currentIndex = [self currentPageIndex];
    NSArray* controllers = nil;
    if (UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation]))
    {
        controllers = slideShowPageViewControllers;
    }
    else 
    {
        controllers = pageViewControllers;
    }
    
    for(int i = 0; i < [controllers count]; ++i)
    {
        if(ABS(currentIndex - i) > 1)
        {
            [self unloadFullPageAtIndex:i];
        }
        else
        {
            [self loadFullPageAtIndex:i];
        }
    }
}

- (void) unloadFullPageAtIndex:(NSInteger) index
{
    if (UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation]))
    {
        if(index >= 0 && index < [slideShowPageViewControllers count])
        {
            PCPageViewController *currentPage = [slideShowPageViewControllers objectAtIndex:index];
            [currentPage unloadFullView];
        }
    }
    else
    {
        if(index >= 0 && index < [pageViewControllers count])
        {
            PCPageViewController *currentPage = [pageViewControllers objectAtIndex:index];
            [currentPage unloadFullView];
        }
    }
}

- (NSInteger) currentPageIndex
{
    if (UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation]))
        return slideShowPagesScrollView.contentOffset.y / slideShowPagesScrollView.frame.size.height;
    else
        return mainScrollView.contentOffset.y / mainScrollView.frame.size.height;
}

- (PCPageViewController*)currentPageViewController
{
    if (UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation]))
    {
        if([self currentPageIndex] >= 0 && [self currentPageIndex] < [slideShowPageViewControllers count])
        {
            return [slideShowPageViewControllers objectAtIndex:[self currentPageIndex]];
        }
    }
    else
    {
        if([self currentPageIndex] >= 0 && [self currentPageIndex] < [pageViewControllers count])
        {
            return [pageViewControllers objectAtIndex:[self currentPageIndex]];
        }
    }
    return nil;
}


-(void)viewDidLoad
{
    slideShowPagesScrollView.delegate = self;
	slideShowPagesScrollView.pagingEnabled = YES;
	slideShowPagesScrollView.alwaysBounceHorizontal = NO;
	slideShowPagesScrollView.bounces = NO;
    slideShowPagesScrollView.showsVerticalScrollIndicator = NO;
    slideShowPagesScrollView.showsHorizontalScrollIndicator = NO;
    [super viewDidLoad];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

-(void)deviceOrientationDidChange
{
    if (magazineViewController.currentColumnViewController==self)
    {
        if (UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation]))
        {
            if ([self.magazineViewController modalViewController]==nil)
            {
               PCLandscapeViewController* slideView = [[PCLandscapeViewController alloc] initWithNibName:nil bundle:nil];
                slideView.view = [[[UIView alloc] initWithFrame:
                                  CGRectMake(0, 0, pageSize.height, pageSize.width)] autorelease];
                
                //slideView.view.backgroundColor = [UIColor blueColor];
                
               [[slideView view] addSubview:slideShowPagesScrollView];
                
               //[self.magazineViewController.mainViewController presentModalViewController:slideView animated:NO];
                if ([self.magazineViewController.mainViewController respondsToSelector:@selector(presentViewController:animated:completion:)]) 
                {
                    [self.magazineViewController.mainViewController presentViewController:slideView animated:YES completion:nil];
                } 
                else 
                {
                    [self.magazineViewController.mainViewController presentModalViewController:slideView animated:YES];   
                }
                
                [slideView release];
                [self updateViewsForCurrentIndex];
                if (player)
                    [player play];

            }
        }
        else
        {
            if (player)
                [player pause];
            if ([self.magazineViewController.mainViewController modalViewController]!=nil)
            {
                //[self.magazineViewController.mainViewController.modalViewController dismissModalViewControllerAnimated:YES];
                if ([self.magazineViewController.mainViewController.modalViewController respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) 
                {
                    [self.magazineViewController.mainViewController.modalViewController dismissViewControllerAnimated:YES completion:nil];
                } 
                else
                {
                    [self.magazineViewController.mainViewController.modalViewController dismissModalViewControllerAnimated:YES];
                }
            }
        }
    }
}

@end
