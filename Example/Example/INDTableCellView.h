//
//  INDTableCellView.h
//  INDSequentialTextSelectionManager
//
//  Created by Indragie Karunaratne on 2014-03-02.
//  Copyright (c) 2014 Indragie Karunaratne. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface INDTableCellView : NSTableCellView
@property (nonatomic, assign) IBOutlet NSTextView *textView;
@end
