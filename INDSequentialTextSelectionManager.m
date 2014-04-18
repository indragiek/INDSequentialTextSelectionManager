//
//  INDSequentialTextSelectionManager.m
//  INDSequentialTextSelectionManager
//
//  Created by Indragie Karunaratne on 2014-03-02.
//  Copyright (c) 2014 Indragie Karunaratne. All rights reserved.
//

#import "INDSequentialTextSelectionManager.h"
#import <objc/runtime.h>

static NSUInteger INDCharacterIndexForTextViewEvent(NSEvent *event, NSTextView *textView)
{
	NSView *contentView = event.window.contentView;
	NSPoint point = [contentView convertPoint:event.locationInWindow fromView:nil];
	NSPoint textPoint = [textView convertPoint:point fromView:contentView];
	return [textView characterIndexForInsertionAtPoint:textPoint];
}

static NSRange INDForwardRangeForIndices(NSUInteger idx1, NSUInteger idx2) {
	NSRange range;
	if (idx2 >= idx1) {
		range = NSMakeRange(idx1, idx2 - idx1);
	} else if (idx2 < idx1) {
		range = NSMakeRange(idx2, idx1 - idx2);
	} else {
		range = NSMakeRange(NSNotFound, 0);
	}
	return range;
}

static void * INDUniqueIdentifierKey = &INDUniqueIdentifierKey;

@interface NSTextView (INDUniqueIdentifiers)
@property (nonatomic, copy) NSString *ind_uniqueIdentifier;
@end

@implementation NSTextView (INDUniqueIdentifiers)

- (void)setInd_uniqueIdentifier:(NSString *)ind_uniqueIdentifier
{
	objc_setAssociatedObject(self, INDUniqueIdentifierKey, ind_uniqueIdentifier, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)ind_uniqueIdentifier
{
	return objc_getAssociatedObject(self, INDUniqueIdentifierKey);
}

@end

@interface INDTextViewSelectionRange : NSObject
@property (nonatomic, copy, readonly) NSString *textViewIdentifier;
@property (nonatomic, assign, readonly) NSRange range;
@property (nonatomic, copy, readonly) NSAttributedString *text;
@end

@implementation INDTextViewSelectionRange

- (id)initWithTextView:(NSTextView *)textView selectedRange:(NSRange)range
{
	if ((self = [super init])) {
		_textViewIdentifier = [textView.ind_uniqueIdentifier copy];
		_range = range;
		_text = [textView.attributedString attributedSubstringFromRange:range];
	}
	return self;
}

@end

@interface INDTextViewSelectionSession : NSObject
@property (nonatomic, copy, readonly) NSString *textViewIdentifier;
@property (nonatomic, assign, readonly) NSUInteger characterIndex;
@property (nonatomic, strong, readonly) NSDictionary *selectionRanges;
@property (nonatomic, assign) NSPoint windowPoint;
- (void)addSelectionRange:(INDTextViewSelectionRange *)range;
- (void)removeSelectionRangeForTextView:(NSTextView *)textView;
@end

@implementation INDTextViewSelectionSession {
	NSMutableDictionary *_selectionRanges;
}
@synthesize selectionRanges = _selectionRanges;

- (id)initWithTextView:(NSTextView *)textView event:(NSEvent *)event
{
	if ((self = [super init])) {
		_textViewIdentifier = [textView.ind_uniqueIdentifier copy];
		_characterIndex = INDCharacterIndexForTextViewEvent(event, textView);
		_selectionRanges = [NSMutableDictionary dictionary];
		_windowPoint = event.locationInWindow;
	}
	return self;
}

- (void)addSelectionRange:(INDTextViewSelectionRange *)range
{
	NSParameterAssert(range.textViewIdentifier);
	_selectionRanges[range.textViewIdentifier] = range;
}

- (void)removeSelectionRangeForTextView:(NSTextView *)textView
{
	NSParameterAssert(textView.ind_uniqueIdentifier);
	[_selectionRanges removeObjectForKey:textView.ind_uniqueIdentifier];
}

 @end

@interface INDSequentialTextSelectionManager ()
@property (nonatomic, strong, readonly) NSMutableDictionary *textViews;
@property (nonatomic, strong, readonly) NSMutableOrderedSet *sortedTextViews;
@property (nonatomic, strong) INDTextViewSelectionSession *currentSession;
@end

@implementation INDSequentialTextSelectionManager

#pragma mark - Iniialization

- (id)init
{
	if ((self = [super init])) {
		_textViews = [NSMutableDictionary dictionary];
		_sortedTextViews = [NSMutableOrderedSet orderedSet];
		[self addLocalEventMonitor];
	}
	return self;
}

- (NSTextView *)validTextViewForEvent:(NSEvent *)event
{
	NSView *contentView = event.window.contentView;
	NSPoint point = [contentView convertPoint:event.locationInWindow fromView:nil];
	NSView *view = [contentView hitTest:point];
	if ([view isKindOfClass:NSTextView.class]) {
		NSTextView *textView = (NSTextView *)view;
		NSString *identifier = textView.ind_uniqueIdentifier;
		return (identifier && self.textViews[identifier]) ? textView : nil;
	}
	return nil;
}

- (void)setSelectionRangeForTextView:(NSTextView *)textView withRange:(NSRange)range affinity:(NSSelectionAffinity)affinity
{
	if (range.location == NSNotFound || NSMaxRange(range) == 0) {
		textView.selectedRange = NSMakeRange(0, 0);
		[self.currentSession removeSelectionRangeForTextView:textView];
	} else {
		INDTextViewSelectionRange *selRange = [[INDTextViewSelectionRange alloc] initWithTextView:textView selectedRange:range];
		[self.currentSession addSelectionRange:selRange];
		[textView setSelectedRange:range affinity:affinity stillSelecting:YES];
	}
}

- (void)processCompleteSelectionsForTargetTextView:(NSTextView *)textView affinity:(NSSelectionAffinity)affinity
{
	if (self.currentSession == nil) return;
	
	NSTextView *startingView = self.textViews[self.currentSession.textViewIdentifier];
	NSUInteger start = [self.sortedTextViews indexOfObject:startingView];
	NSUInteger end = [self.sortedTextViews indexOfObject:textView];
	if (start == NSNotFound || end == NSNotFound) return;
	
	NSRange subrange = NSMakeRange(NSNotFound, 0);
	BOOL select = NO;
	NSUInteger count = self.sortedTextViews.count;
	if (end > start) {
		if (affinity == NSSelectionAffinityDownstream) {
			subrange = NSMakeRange(start, end - start);
			select = YES;
		} else if (count > end + 1) {
			subrange = NSMakeRange(end + 1, count - end - 1);
		}
	} else if (end < start) {
		if (affinity == NSSelectionAffinityUpstream) {
			subrange = NSMakeRange(end + 1, start - end);
			select = YES;
		} else {
			subrange = NSMakeRange(0, end);
		}
	}
	NSArray *subarray = nil;
	if (subrange.location == NSNotFound) {
		NSMutableOrderedSet *views = [self.sortedTextViews mutableCopy];
		[views removeObject:textView];
		subarray = views.array;
	} else {
		subarray = [self.sortedTextViews.array subarrayWithRange:subrange];
	}
	for (NSTextView *textView in subarray) {
		NSRange range = NSMakeRange(0, select ? textView.string.length : 0);
		[self setSelectionRangeForTextView:textView withRange:range affinity:affinity];
	}
}

- (void)endSession
{
	for (NSTextView *textView in self.textViews.allValues) {
		textView.selectedRange = NSMakeRange(0, 0);
	}
	self.currentSession = nil;
}

- (void)addLocalEventMonitor
{
	[NSEvent addLocalMonitorForEventsMatchingMask:NSLeftMouseDownMask handler:^NSEvent *(NSEvent *event) {
		NSTextView *textView = [self validTextViewForEvent:event];
		if (textView == nil) return event;
		[self endSession];
		self.currentSession = [[INDTextViewSelectionSession alloc] initWithTextView:textView event:event];
		return nil;
	}];
	[NSEvent addLocalMonitorForEventsMatchingMask:NSLeftMouseDraggedMask handler:^NSEvent *(NSEvent *event) {
		if (self.currentSession == nil) return event;
		NSTextView *textView = [self validTextViewForEvent:event];
		if (textView == nil) return nil;
		
		NSSelectionAffinity affinity = (event.locationInWindow.y < self.currentSession.windowPoint.y) ? NSSelectionAffinityDownstream : NSSelectionAffinityUpstream;
		self.currentSession.windowPoint = event.locationInWindow;
		
		NSUInteger current;
		NSString *identifier = self.currentSession.textViewIdentifier;
		if ([textView.ind_uniqueIdentifier isEqualTo:identifier]) {
			current = self.currentSession.characterIndex;
		} else {
			NSUInteger start = [self.sortedTextViews indexOfObject:self.textViews[identifier]];
			NSUInteger end = [self.sortedTextViews indexOfObject:textView];
			current = (end >= start) ? 0 : textView.string.length;
		}
		NSUInteger index = INDCharacterIndexForTextViewEvent(event, textView);
		NSRange range = INDForwardRangeForIndices(index, current);
		[self setSelectionRangeForTextView:textView withRange:range affinity:affinity];
		[self processCompleteSelectionsForTargetTextView:textView affinity:affinity];
		return nil;
	}];
}

#pragma mark - Registration

- (void)registerTextView:(NSTextView *)textView withUniqueIdentifier:(NSString *)identifier
{
	NSParameterAssert(identifier);
	NSParameterAssert(textView);
	
	[self unregisterTextView:textView];
	textView.ind_uniqueIdentifier = identifier;
	self.textViews[identifier] = textView;
	
	[self.sortedTextViews addObject:textView];
	[self sortTextViews];
}

- (void)sortTextViews
{
	[self.sortedTextViews sortUsingComparator:^NSComparisonResult(NSTextView *obj1, NSTextView *obj2) {
		// Convert to window coordinates to normalize coordinate flipped-ness
		NSRect frame1 = [obj1 convertRect:obj1.bounds toView:nil];
		NSRect frame2 = [obj2 convertRect:obj2.bounds toView:nil];
		
		CGFloat y1 = NSMinY(frame1);
		CGFloat y2 = NSMinY(frame2);
		
		if (y1 > y2) {
			return NSOrderedAscending;
		} else if (y1 < y2) {
			return NSOrderedDescending;
		} else {
			return NSOrderedSame;
		}
	}];
}

- (void)unregisterTextView:(NSTextView *)textView
{
	if (textView.ind_uniqueIdentifier == nil) return;
	[self.textViews removeObjectForKey:textView.ind_uniqueIdentifier];
	[self.sortedTextViews removeObject:textView];
	[self sortTextViews];
}

- (void)unregisterAllTextViews
{
	[self.textViews removeAllObjects];
	[self.sortedTextViews removeAllObjects];
}

@end
