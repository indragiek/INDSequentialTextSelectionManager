//
//  INDSequentialTextSelectionManager.h
//  INDSequentialTextSelectionManager
//
//  Created by Indragie Karunaratne on 2014-03-02.
//  Copyright (c) 2014 Indragie Karunaratne. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  Coordinates sequential text selection among an arbitrary set of `NSTextView`s
 */
@interface INDSequentialTextSelectionManager : NSObject

/**
 *  Registers a text view for sequential text selection.
 *
 *  @param textView The text view to register.
 */
- (void)registerTextView:(NSTextView *)textView;

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
