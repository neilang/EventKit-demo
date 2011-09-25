//
//  RootViewController.m
//  EventKit Demo
//
//  Created by Neil Ang on 25/09/11.
//  Copyright 2011 neilang.com. All rights reserved.
//

#import <EVentKit/EventKit.h>
#import <EventKitUI/EventKitUI.h>
#import "SBJson.h"
#import "RootViewController.h"

// Remember to change this to point to your events feed
// For an example way to do this, download and run: https://github.com/neilang/EventsFeed
#define JSON_EVENT_FEED @"http://localhost:3000/events.json"

@implementation RootViewController

@synthesize events = _events;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
    
    // Add a refresh button
    UIBarButtonItem * refresh = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh 
                                                                              target:self 
                                                                              action:@selector(updateFeed:)];
    self.navigationItem.rightBarButtonItem = refresh;
    [refresh release];
    
    // Fetch the latest events
    [self updateFeed:nil];
}

-(IBAction)updateFeed:(id)sender{
    
    // Create a request to fetch the feed
    NSURL *url = [NSURL URLWithString:JSON_EVENT_FEED];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    // Start the network activity spinner
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    // For simplicity I'm using a synchronous call here.
    // In your app, make sure to replace this with an asynchronous request
    NSError *error = nil;
    NSData  *data  = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:nil error:&error];
    
    if(error){
        NSLog(@"Error: %@", [error description]);
    }
    
    // Parse the returned JSON data
    SBJsonParser *parser = [[SBJsonParser alloc] init];
    self.events = [parser objectWithData:data];
    [parser release];
    
    // Stop activity the network spinner
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    // Update the table view
    [self.tableView reloadData];
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.events count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

    // Get the downloaded event data, and display the title of the event
    NSDictionary *eventData = [self.events objectAtIndex:indexPath.row];
    cell.textLabel.text = [eventData objectForKey:@"title"];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // If an event is tapped, we want to let the user add it to their calendar
    
    NSDictionary *eventData = [self.events objectAtIndex:indexPath.row];
    
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    
    // This will create a new event object, but not save it
    EKEvent * event = [EKEvent eventWithEventStore:eventStore];
    
    // Set basic information
    event.calendar = [eventStore defaultCalendarForNewEvents];
    event.title    = [eventData objectForKey:@"title"];
    event.location = [eventData objectForKey:@"location"];
    event.notes    = [eventData objectForKey:@"notes"];
    
    // To set the event date, we must use NSDate objects
    NSDate * startDate = [NSDate dateWithTimeIntervalSince1970:[[eventData objectForKey:@"startdate"] intValue]];
    NSDate * endDate   = [NSDate dateWithTimeIntervalSince1970:[[eventData objectForKey:@"enddate"] intValue]];
    
    event.startDate = startDate;
    event.endDate   = endDate;
    
    // You could now save the event to the EventStore like this:
    // [eventStore saveEvent:event span:EKSpanThisEvent error:nil];
    
    // However, it's more user friendly to show a GUI to the user about what's happening
    // So we will use EventKitUI to display the details and let the user tap save.
    EKEventEditViewController * controller = [[EKEventEditViewController alloc] init];
    
    controller.eventStore       = eventStore;
    controller.event            = event;
    controller.editViewDelegate = self;
    
    [self presentModalViewController:controller animated:YES];
    
    [controller release];
    [eventStore release];
    
}

-(void)eventEditViewController:(EKEventEditViewController *)controller didCompleteWithAction:(EKEventEditViewAction)action{
    
    switch (action) {
		case EKEventEditViewActionCanceled:
			// Adding the event was cancelled. 
			break;
			
		case EKEventEditViewActionSaved:
			// The event was saved
			break;
			
		case EKEventEditViewActionDeleted:
			// The event was deleted
			break;
			
		default:
			break;
	}
    
    [self dismissModalViewControllerAnimated:YES];
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    self.events = nil;
}

- (void)dealloc
{
    [super dealloc];
}

@end
