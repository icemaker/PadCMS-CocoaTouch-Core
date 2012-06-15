//
//  PCSearchResult.h
//  Pad CMS
//
//  Created by Oleg Zhitnik on 01.03.12.
//  Copyright (c) 2012 Adyax. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PCSearchResultItem.h"

/**
 @class PCSearchResult
 @brief This class contains result generated by searching task
 */
@interface PCSearchResult : NSObject

/**
 @brief Array of PCSearchResultItem elements - search result items
 */ 
@property (atomic, retain) NSMutableArray *items;

/**
 @brief Adding new search result item to array
 @param item - new search result item
 */
-(void) addResultItem:(PCSearchResultItem*) item;

@end