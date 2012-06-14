//
//  PCMagazine.m
//  Pad CMS
//
//  Created by Rustam Mallakurbanov on 02.02.12.
//  Copyright (c) 2012 Adyax. All rights reserved.
//

#import "PCIssue.h"
#import "PCRevision.h"
#import "PCPathHelper.h"
#import "InAppPurchases.h"

@implementation PCIssue

@synthesize application = _application;
//@synthesize currentRevision = _currentRevision;
@synthesize contentDirectory = _contentDirectory;
@synthesize revisions = _revisions;
@synthesize subscriptionType = _subscriptionType;
@synthesize paid = _paid;
@synthesize identifier = _identifier;
@synthesize title = _title;
@synthesize number = _number;
@synthesize productIdentifier = _productIdentifier;
@synthesize coverImageThumbnailURL = _coverImageThumbnailURL;
@synthesize coverImageListURL = _coverImageListURL;
@synthesize coverImageURL = _coverImageURL;
@synthesize updatedDate = _updatedDate;
@synthesize price=_price;

- (void)dealloc
{
    self.updatedDate = nil;
//    self.revisionCreatedDate = nil;
//    self.revisionUpdateDate = nil;
//    self.revisionTitle = nil;
    self.productIdentifier = nil;
    self.coverImageThumbnailURL = nil;
    self.coverImageListURL = nil;
    self.coverImageURL = nil;
    self.number = nil;
    self.title = nil;
	self.price = nil;
    [super dealloc];
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        _subscriptionType = PCIssueUnknownSubscriptionType;
        _paid = NO;
        _identifier = -1;
        _productIdentifier =nil;
        _title = nil;
        _number = nil;
        _updatedDate = nil;
		_price = nil;
    }

    return self;
}

- (id)initWithParameters:(NSDictionary *)parameters rootDirectory:(NSString *)rootDirectory
{
    if (parameters == nil) return nil;

    self = [super init];
    
    if (self)
    {
        NSString *identifierString = [parameters objectForKey:PCJSONIssueIDKey];
        
        _contentDirectory = [[rootDirectory stringByAppendingPathComponent:
                             [NSString stringWithFormat:@"issue-%@", identifierString]] copy];

        [PCPathHelper createDirectoryIfNotExists:_contentDirectory];

        _identifier = [identifierString integerValue];
        _title = [[parameters objectForKey:PCJSONIssueTitleKey] copy];
        _number = [[parameters objectForKey:PCJSONIssueNumberKey] copy];
        _productIdentifier = [[parameters objectForKey:PCJSONIssueProductIDKey] copy];
        
        _paid = [[parameters objectForKey:PCJSONIssuePaidKey] boolValue];
		if ([_productIdentifier isEqualToString:@""])
		{
			_paid = YES;
		}
        
        NSString *issueSubscriptionType = [parameters objectForKey:PCJSONIssueSubscriptionTypeKey];
        
        if (issueSubscriptionType)
        {
            if ([issueSubscriptionType isEqualToString:PCJSONIssueAutoRenewableSubscriptionTypeValue])
            {
                _subscriptionType = PCIssueSubscriptionAutoRenewable;
				_paid = YES;
            }
        }
        
     //   NSDictionary *helpPages = [parameters objectForKey:PCJSONIssueHelpPagesKey];
        
        _revisions = [[NSMutableArray alloc] init];
        NSDictionary *revisionsParameters = [parameters objectForKey:PCJSONRevisionsKey];
        if ([revisionsParameters count] > 0)
        {
            NSArray *revisionsKeys = [revisionsParameters allKeys];
            for (NSString *key in revisionsKeys)
            {
                PCRevision *revision = [[PCRevision alloc] initWithParameters:[revisionsParameters objectForKey:key]
                                                                rootDirectory:_contentDirectory];
                
                if (revision != nil)
                {
                    [_revisions addObject:revision];
                }
                
                revision.issue = self;
       //         revision.helpPages = helpPages;
                
                [revision release];
            }
			[_revisions sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
				NSNumber* number1 = [NSNumber numberWithInteger:((PCRevision*)obj1).identifier];
				NSAssert(number1,@"Error");
				NSNumber* number2 = [NSNumber numberWithInteger:((PCRevision*)obj2).identifier];
				NSAssert(number2,@"Error");
				return [number1 compare:number2];
			}];
        }
		[self loadProductPrices];
    }
    
    return self;
}

- (void) loadProductPrices
{
	if(!_paid && !_price)
	{
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(productDataRecieved:) 
													 name:kInAppPurchaseManagerProductsFetchedNotification
												   object:nil];
		[[InAppPurchases sharedInstance] requestProductDataWithProductId:_productIdentifier];
	}
}

- (void) productDataRecieved:(NSNotification *) notification
{
	NSLog(@"From PCIssue::productDataRecieved: %@ %@", [(NSDictionary *)[notification object] objectForKey:@"productIdentifier"], [(NSDictionary *)[notification object] objectForKey:@"localizedPrice"]);
		
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kInAppPurchaseManagerProductsFetchedNotification object:nil];
	if([[(NSDictionary *)[notification object] objectForKey:@"productIdentifier"] isEqualToString:_productIdentifier])
	{
		self.price = [NSString stringWithString:[(NSDictionary *)[notification object] objectForKey:@"localizedPrice"]];
		return;
	}

}


/*
- (PCRevision *)currentRevision
{
    if (_revisions == nil || [_revisions count] == 0) return nil;
    
    for (PCRevision *revision in _revisions)
    {
        if (revision.state = PCRevisionStatePublished)
        {
            return revision;
        }
    }
    
    return nil;
}
*/
- (NSString *)description
{
    NSString *descriptionString = [NSString stringWithFormat:@"%@\ridentifier: %d\rtitle: %@\r"
                                   "number: %@\rproductIdentifier: %@\rsubscriptionType: %d\r"
                                   "paid: %d\rcolor: %@\rcoverImageThumbnailURL: %@\r"
                                   "coverImageListURL: %@\rcoverImageURL: %@\rupdatedDate: %@\r"
                                   "horisontalMode: %d\rcontentDirectory: %@\r"
                                   "revisions: %@", 
                                   [super description],
                                   _identifier,
                                   _title,
                                   _number,
                                   _productIdentifier,
                                   _subscriptionType,
                                   _paid,
                                   _coverImageThumbnailURL,
                                   _coverImageListURL,
                                   _coverImageURL,
                                   _updatedDate,
                                   _contentDirectory,
                                   _revisions];
    
    return descriptionString;
}

@end
