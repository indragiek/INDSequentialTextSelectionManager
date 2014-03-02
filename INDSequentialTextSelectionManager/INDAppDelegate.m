//
//  INDAppDelegate.m
//  INDSequentialTextSelectionManager
//
//  Created by Indragie Karunaratne on 2014-03-02.
//  Copyright (c) 2014 Indragie Karunaratne. All rights reserved.
//

#import "INDAppDelegate.h"
#import "INDTableCellView.h"
#import "INDTableRowView.h"

@implementation INDAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return 10;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	return @"";
}

#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	return [tableView makeViewWithIdentifier:@"Cell" owner:self];
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
	return [[INDTableRowView alloc] initWithFrame:NSZeroRect];
}

@end
