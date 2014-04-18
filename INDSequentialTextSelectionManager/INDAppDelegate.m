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
#import "INDSequentialTextSelectionManager.h"

@interface INDAppDelegate () <NSTableViewDelegate, NSTableViewDataSource>
@property (nonatomic, strong, readonly) INDSequentialTextSelectionManager *selectionManager;
@end

@implementation INDAppDelegate {
	BOOL _awokenFromNib;
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	if (!_awokenFromNib) {
		_selectionManager = [[INDSequentialTextSelectionManager alloc] init];
		_awokenFromNib = YES;
	}
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

- (INDTableCellView *)cellViewForRowView:(NSTableRowView *)rowView
{
	NSAssert([rowView isKindOfClass:INDTableRowView.class], @"Row view is not an instance of INDTableRowView");
	INDTableCellView *cellView = [rowView viewAtColumn:0];
	NSAssert([cellView isKindOfClass:INDTableCellView.class], @"Cell view is not an instance of INDTableCellView");
	return cellView;
}

- (void)tableView:(NSTableView *)tableView didRemoveRowView:(NSTableRowView *)rowView forRow:(NSInteger)row
{
	INDTableCellView *cellView = [self cellViewForRowView:rowView];
	[self.selectionManager unregisterTextView:cellView.textView];
}

- (void)tableView:(NSTableView *)tableView didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row
{
	INDTableCellView *cellView = [self cellViewForRowView:rowView];
	[self.selectionManager registerTextView:cellView.textView withUniqueIdentifier:@(row).stringValue];
}

@end
