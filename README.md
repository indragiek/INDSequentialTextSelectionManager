## INDSequentialTextSelectionManager
#### Easy WebView-like text selection in multiple text views

When building [Flamingo](http://flamingo.im), I wanted to find a way to select text through multiple `NSTextView`s in a single drag, similar to how it works in a `WebView`. After finding out that there's nothing in AppKit that would do this for me, I developed this project to replicate that functionality.

Here's a GIF demonstrating how it works:

![INDSequentialTextSelectionManager](https://raw.githubusercontent.com/indragiek/INDSequentialTextSelectionManager/master/demo.gif)

**WARNING: This is alpha quality code at the moment and has not been tested in production.**

### How to use

The API is extremely simple. These two methods are all you'll need:

```objective-c
- (void)registerTextView:(NSTextView *)textView withUniqueIdentifier:(NSString *)identifier;
- (void)unregisterTextView:(NSTextView *)textView;
```

Allocate an instance of `INDSequentialTextSelectionManager` for every group of `NSTextView`s that you want to participate in sequential selection. When a text view goes on screen, call `-registerTextView:withUniqueIdentifier:`. The unique identifier should be something relevant to the *content* of the text view and not the text view instance itself. Since `INDSequentialTextSelectionManager` is designed to support things like cell recycling (where a single `NSTextView` instance is shared among multiple cells), the unique identifier is used instead of the text view instance itself to keep track of the selection state. The unique identifier **must be unique** for each text view being tracked by the manager.

If a text view's frame, bounds, or location in the view hierarchy changes, `-registerTextView:withUniqueIdentifier:` must be called again to let the manager know to update its cached layout information.

When a text view goes off-screen, call `-unregisterTextView:` to ensure that it's no longer tracked by the manager.

### Example: NSTableView

Implementing `INDSequentialTextManager` support with an `NSTableView` is as easy as implementing these 2 delegate methods:

```objective-c
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
```

(Full code can be found in the Example project)

### TODO

* Support for other `NSTextView` contextual menu items like Services, Text to Speech, etc.
* Autoscroll when dragging
* ~~Proper inactive state for selection~~

### Contact

* Indragie Karunaratne
* [@indragie](http://twitter.com/indragie)
* [http://indragie.com](http://indragie.com)

### License

`INDSequentialTextSelectionManager` is licensed under the MIT License.


