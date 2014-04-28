//
//  INDSequentialTextSelectionManager.h
//  INDSequentialTextSelectionManager
//
//  Created by Indragie Karunaratne on 2014-03-02.
//  Copyright (c) 2014 Indragie Karunaratne. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NSAttributedString * (^INDAttributedTextTransformationBlock)(NSAttributedString *);

/**
 *  Coordinates sequential text selection among an arbitrary set of `NSTextView`s
 */
@interface INDSequentialTextSelectionManager : NSResponder

/**
 *  Registers a text view to participate in sequential selection.
 *
 *  @param textView   The `NSTextView` instance to register.
 *  @param identifier The unique identifier to associate with the text view instance.
 */
- (void)registerTextView:(NSTextView *)textView withUniqueIdentifier:(NSString *)identifier;

/**
 *  Registers a text view to participate in sequential selection.
 *
 *  @param textView   The `NSTextView` instance to register.
 *  @param identifier The unique identifier to associate with the text view instance.
 *  @param block      A transformation block to apply to the contents of the text view
 *  before copying the text.
 */
- (void)registerTextView:(NSTextView *)textView withUniqueIdentifier:(NSString *)identifier transformationBlock:(INDAttributedTextTransformationBlock)block;

/**
 *  Unregisters a text view for sequential text selection.
 *
 *  @param textView The text view to unregister.
 */
- (void)unregisterTextView:(NSTextView *)textView;

/**
 *  Unregisters all text views.
 */
- (void)unregisterAllTextViews;

@end
