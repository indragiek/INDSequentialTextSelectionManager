//
//  INDTableRowView.m
//  INDSequentialTextSelectionManager
//
//  Created by Indragie Karunaratne on 2014-03-02.
//  Copyright (c) 2014 Indragie Karunaratne. All rights reserved.
//

#import "INDTableRowView.h"

@implementation INDTableRowView

- (void)drawBackgroundInRect:(NSRect)dirtyRect
{
	[super drawBackgroundInRect:dirtyRect];
	NSRect slice, rem;
	NSDivideRect(self.bounds, &slice, &rem, 1.f, NSMinYEdge);
	[[NSColor darkGrayColor] set];
	NSRectFill(slice);
}

@end
