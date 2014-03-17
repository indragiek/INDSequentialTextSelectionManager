//
//  INDSequentialTextSelectionManager.m
//  INDSequentialTextSelectionManager
//
//  Created by Indragie Karunaratne on 2014-03-02.
//  Copyright (c) 2014 Indragie Karunaratne. All rights reserved.
//

#import "INDSequentialTextSelectionManager.h"

@interface INDSequentialTextSelectionManager ()
@property (nonatomic, strong, readonly) NSMutableSet *textViews;
@end

@implementation INDSequentialTextSelectionManager

#pragma mark - Iniialization

- (id)init
{
	if ((self = [super init])) {
		_textViews = [NSMutableSet set];
		[self addLocalEventMonitor];
	}
	return self;
}

- (void)addLocalEventMonitor
{
	[NSEvent addLocalMonitorForEventsMatchingMask:NSLeftMouseDownMask handler:^NSEvent *(NSEvent *event) {
		NSView *contentView = event.window.contentView;
		NSPoint point = [contentView convertPoint:event.locationInWindow fromView:nil];
		NSView *view = [contentView hitTest:point];
		NSLog(@"%@ %@", self.textViews, view);
		if ([self.textViews containsObject:view]) {
			NSLog(@"CONTAINS");
			NSTextView *textView = (NSTextView *)view;
			NSPoint textPoint = [textView convertPoint:point fromView:contentView];
			NSUInteger characterIndex = [textView characterIndexForInsertionAtPoint:textPoint];
			NSLog(@"%lu", characterIndex);
			
		}
		return event;
	}];
}

- (void)runEventTrackingLoop
{
	
}

#pragma mark - Registration

- (void)registerTextView:(NSTextView *)textView
{
	[self.textViews addObject:textView];
}

- (void)unregisterTextView:(NSTextView *)textView
{
	[self.textViews removeObject:textView];
}

- (void)unregisterAllTextViews
{
	[self.textViews removeAllObjects];
}


@end
