//
//  INDSequentialTextSelectionManager.m
//  INDSequentialTextSelectionManager
//
//  Created by Indragie Karunaratne on 2014-03-02.
//  Copyright (c) 2014 Indragie Karunaratne. All rights reserved.
//

#import "INDSequentialTextSelectionManager.h"
#import <objc/runtime.h>

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
- (void)addSelectionRange:(INDTextViewSelectionRange *)range;
@end

@implementation INDTextViewSelectionSession {
	NSMutableDictionary *_selectionRanges;
}
@synthesize selectionRanges = _selectionRanges;

- (id)initWithTextView:(NSTextView *)textView characterIndex:(NSUInteger)index
{
	if ((self = [super init])) {
		_textViewIdentifier = [textView.ind_uniqueIdentifier copy];
		_characterIndex = index;
		_selectionRanges = [NSMutableDictionary dictionary];
	}
	return self;
}

- (void)addSelectionRange:(INDTextViewSelectionRange *)range
{
	_selectionRanges[range.textViewIdentifier] = range;
}

 @end

@interface INDSequentialTextSelectionManager ()
@property (nonatomic, strong, readonly) NSMutableDictionary *textViews;
@property (nonatomic, strong) INDTextViewSelectionSession *currentSession;
@end

@implementation INDSequentialTextSelectionManager

#pragma mark - Iniialization

- (id)init
{
	if ((self = [super init])) {
		_textViews = [NSMutableDictionary dictionary];
		[self addLocalEventMonitor];
	}
	return self;
}

static NSUInteger INDCharacterIndexForTextViewEvent(NSEvent *event, NSTextView *textView)
{
	NSView *contentView = event.window.contentView;
	NSPoint point = [contentView convertPoint:event.locationInWindow fromView:nil];
	NSPoint textPoint = [textView convertPoint:point fromView:contentView];
	return [textView characterIndexForInsertionAtPoint:textPoint];
}

static NSRange INDSelectionRangeForIndices(NSUInteger idx1, NSUInteger idx2, NSSelectionAffinity *affinity)
{
	if (idx1 == idx2) return NSMakeRange(NSNotFound, 0);
	
	NSRange range;
	NSSelectionAffinity aff = (idx2 > idx1) ? NSSelectionAffinityDownstream : NSSelectionAffinityUpstream;
	if (aff == NSSelectionAffinityDownstream) {
		range = NSMakeRange(idx1, idx2 - idx1);
	} else {
		range = NSMakeRange(idx2, idx1 - idx2);
	}
	if (affinity) *affinity = aff;
	return range;
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

- (void)addSelectionRangeFromIndex:(NSUInteger)idx1 toIndex:(NSUInteger)idx2 inTextView:(NSTextView *)textView
{
	NSSelectionAffinity affinity;
	NSRange range = INDSelectionRangeForIndices(idx1, idx2, &affinity);
	if (range.location != NSNotFound) {
		INDTextViewSelectionRange *selRange = [[INDTextViewSelectionRange alloc] initWithTextView:textView selectedRange:range];
		[self.currentSession addSelectionRange:selRange];
		[textView setSelectedRange:range affinity:affinity stillSelecting:YES];
	}
}

- (void)endSession
{
	for (NSTextView *textView in self.textViews.allValues) {
		textView.selectedRange = NSMakeRange(0, 0);
		self.currentSession = nil;
	}
}

- (void)addLocalEventMonitor
{
	[NSEvent addLocalMonitorForEventsMatchingMask:NSLeftMouseDownMask handler:^NSEvent *(NSEvent *event) {
		NSTextView *textView = [self validTextViewForEvent:event];
		if (textView == nil) return event;
		[self endSession];
		NSUInteger index = INDCharacterIndexForTextViewEvent(event, textView);
		self.currentSession = [[INDTextViewSelectionSession alloc] initWithTextView:textView characterIndex:index];
		return nil;
	}];
	[NSEvent addLocalMonitorForEventsMatchingMask:NSLeftMouseDraggedMask handler:^NSEvent *(NSEvent *event) {
		if (self.currentSession == nil) return event;
		NSTextView *textView = [self validTextViewForEvent:event];
		if (textView != nil) {
			NSUInteger index = INDCharacterIndexForTextViewEvent(event, textView);
			NSUInteger current = self.currentSession.characterIndex;
			[self addSelectionRangeFromIndex:index toIndex:current inTextView:textView];
		}
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
}

- (void)unregisterTextView:(NSTextView *)textView
{
	if (textView.ind_uniqueIdentifier) {
		[self.textViews removeObjectForKey:textView.ind_uniqueIdentifier];
	}
}

- (void)unregisterAllTextViews
{
	[self.textViews removeAllObjects];
}

@end
