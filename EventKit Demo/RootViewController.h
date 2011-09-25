//
//  RootViewController.h
//  EventKit Demo
//
//  Created by Neil Ang on 25/09/11.
//  Copyright 2011 neilang.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RootViewController : UITableViewController<EKEventEditViewDelegate>

@property (nonatomic, retain) NSArray * events;

-(IBAction)updateFeed:(id)sender;

@end
