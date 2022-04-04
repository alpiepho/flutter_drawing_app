## Get Application
Version: 0.1

GH-Pages site: https://alpiepho.github.io/flutter_drawing_app/

or QR Code:

![QR Code](./qr-code.png)

## "Install" on iPhone

This application is a Web application known as a PWA (progressive web application).  It is possible to add a PWA to the home screen of an iPhone
like it is a downloaded application (there is a similare mechanism for Android that is not discused here).  Use the following steps:

1. Open the above link in Safari and click on up-arrow
2. Click on "Add to Home Screen"
3. Select "Add"

## About flutter_drawing_app

This is simple drawing app written in Flutter/Dart.   It was derived from a nice tutorial (see References).

It was converted to a PWA (progressive web application), which is basically web app that can be saved as a icon on a mobile screen.

Using your finger, you can draw random shapes.  Use the "pencil" icon to clear the drawing.  Use the color icons to change color.  Uses the range of dot sizes to change the stroke size.  The gear at the bottom brings up a settings/help modal. (click outside thoe model to close it).

The arrow/chevron at the top or left allows hiding all controls so you can take a screen shot to save drawings.  It also disables drawing so you don't add unwanted lines, say to switch apps on an iPhone.

There are various clear options associated with the 'pencil' button:
- clear all
- undo last line
- undo last point
- redo all
- redo last line
- redo last point
Tap the '...' below the  'pencil' button to switch modes.

The set of supported colors is greater than the 3 shown.  Use the '...' to shuffle thru the colors.  Also, use the background color to 'erase' (suggest a larger stroke size).

The set of stroke size can also be shuffled using the '...'.


More features will certainly be added.  Stay tuned.

## Known Issue

There is a know issue when redoing points over multiple line segments.  They will be connected.  To be fixed.

The smallest stroke width can be difficult to press.  Has to do with how button is built.

Selected color is not always the top color.

Color Picker should not close until Done.

## Additions

- [x] flutter upgrade
- [x] flutter web
- [x] branch for starter from tutorial
- [x] branch for final from tutorial
- [x] hide save button (wont work on web)
- [x] add hide of settings
- [x] about/help link, try bottom modal (name?)
- [x] icons and favicon
- [x] convert to PWA
- [x] toolboxes in landscape
- [x] small size is hard to touch
- [x] protected area is blue, what background
- [x] gear and settings with help
- [x] qr
- [x] more readme about using screen shot instead of save
- [x] grid lines
- [x] snap to grid
- [x] straight lines
- [x] undo button
- [x] redo
- [x] eraser
- [x] scale toolboxes to fit mobile browser
- [x] button hover or snackbar message
- [x] more sizes
- [x] saved prefrenes for saved state
- [x] color selector
- [x] reset colors


## TODO
- [ ] save colors
- [ ] fix color picker closing immediately
- [ ] fix redo point from line 1 to line 2, no break
- [ ] refactor large main file
- [ ] add tests
- [ ] share with author

Question: when is it done?




- [ ] look into leverage for sketch app

## References

Icons created with https://appicon.co/  NOTE: original image should be square to avoid white edges on IOS Home screen.

This was derived from a tutorial at: https://www.raywenderlich.com/25237210-building-a-drawing-app-in-flutter

The qr code was generated from:
https://www.the-qrcode-generator.com/
