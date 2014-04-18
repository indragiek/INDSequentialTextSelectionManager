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
@property (nonatomic, strong, readonly) NSArray *selectionRanges;
- (void)addSelectionRange:(INDTextViewSelectionRange *)range;
@end

@implementation INDTextViewSelectionSession {
	NSMutableArray *_selectionRanges;
}
@synthesize selectionRanges = _selectionRanges;

- (id)initWithTextView:(NSTextView *)textView characterIndex:(NSUInteger)index
{
	if ((self = [super init])) {
		_textViewIdentifier = [textView.ind_uniqueIdentifier copy];
		_characterIndex = index;
		_selectionRanges = [NSMutableArray array];
	}
	return self;
}

- (void)addSelectionRange:(INDTextViewSelectionRange *)range
{
	[_selectionRanges addObject:range];
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

- (void)addLocalEventMonitor
{
	[NSEvent addLocalMonitorForEventsMatchingMask:NSLeftMouseDownMask handler:^NSEvent *(NSEvent *event) {
		NSTextView *textView = [self validTextViewForEvent:event];
		if (textView == nil) return event;
		
		
		return event;
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
