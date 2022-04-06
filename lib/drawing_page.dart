import 'dart:async';

import 'package:drawing_app/drawn_line.dart';
import 'package:drawing_app/sketcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

enum ClearMode {
  all,
  line,
  point,
  redoAll,
  redoLine,
  redoPoint,
}

class DrawingPage extends StatefulWidget {
  @override
  _DrawingPageState createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  GlobalKey _globalKey = new GlobalKey();
  List<DrawnLine> lines = <DrawnLine>[];
  DrawnLine line;
  int gridSize = 10;
  Offset lastPoint; // for straightLines
  List<DrawnLine> lastLines = <DrawnLine>[]; // for redo lines
  ClearMode clearMode = ClearMode.all; // for toggle of clear button
  List<Color> defaultColorsAvailable = <Color>[
    // for shuffle colors
    Colors.red,
    Colors.blueAccent,
    Colors.yellow,
    Colors.green,
    Colors.lightBlue,
    Colors.black,
    Colors.white,
    Color(0xFFFFFDE7), // background to "erase"
  ];
  List<Color> colorsAvailable = <Color>[
    // for shuffle colors
    Colors.red,
    Colors.blueAccent,
    Colors.yellow,
    Colors.green,
    Colors.lightBlue,
    Colors.black,
    Colors.white,
    Color(0xFFFFFDE7), // background to "erase"
  ];
  List<double> strokesAvailable = <double>[
    5.0,
    10.0,
    15.0,
    20.0,
    25.0,
  ];
  bool prefsRead = false;
  bool swipeFromBottom = false;

  // for settings model to be saved in hive? overkill?
  Color selectedColor = Colors.black;
  Color nextColor = Colors.black;
  double selectedWidth = 5.0;
  bool hidden = false;
  bool showMessages = true;
  bool showGrid = false;
  bool snapToGrid = false;
  bool straightLines = false;

  StreamController<List<DrawnLine>> linesStreamController =
      StreamController<List<DrawnLine>>.broadcast();
  StreamController<DrawnLine> currentLineStreamController =
      StreamController<DrawnLine>.broadcast();

  void dumpLines(String msg) {
    print(msg);
    for (int i = 0; i < lines.length; i++) {
      print('line[' +
          i.toString() +
          '].path.length = ' +
          lines[i].path.length.toString());
    }
    for (int i = 0; i < lastLines.length; i++) {
      print('lastLines[' +
          i.toString() +
          '].path.length = ' +
          lastLines[i].path.length.toString());
    }
  }

  Future<void> clear() async {
    setState(() {
      switch (clearMode) {
        case ClearMode.all:
          lastLines = lines;
          lines = [];
          line = null;
          break;
        case ClearMode.line:
          if (lines.length > 0) {
            lastLines.add(lines.last);
            if (lines.length == 1) {
              lines = [];
              line = null;
            } else {
              lines.removeLast();
              line = null;
            }
          }
          break;
        case ClearMode.point:
          //dumpLines("AAA:");
          // any lines left to remove
          if (lines.length > 0) {
            // any points on last path to remove
            if (lines.last.path.length > 0) {
              // save last point before removing it
              if (lastLines.length == 0) {
                // copy last line with empty path
                List<Offset> newPath = [];
                DrawnLine newLine = DrawnLine(
                  newPath,
                  lines.last.color,
                  lines.last.width,
                );
                lastLines.add(newLine);
              }
              lastLines.last.path.add(lines.last.path.last);

              // remove last point
              lines.last.path.removeLast();
            } else {
              // since points gone, remove last line
              lines.removeLast();

              // save new last line
              if (lines.length > 0) {
                // copy last line with empty path
                List<Offset> newPath = [];
                DrawnLine newLine = DrawnLine(
                  newPath,
                  lines.last.color,
                  lines.last.width,
                );
                lastLines.add(newLine);
              }
            }
          }
          //dumpLines("BBB:");
          break;
        case ClearMode.redoAll:
          if (lastLines.length > 0) {
            lines = lastLines;
            lastLines = <DrawnLine>[];
          }
          break;
        case ClearMode.redoLine:
          if (lastLines.length > 0) {
            lines.add(lastLines.last);
            lastLines.removeLast();
          }
          break;
        case ClearMode.redoPoint:
          //dumpLines("aaa:");
          // any lastLines left to redo
          if (lastLines.length > 0) {
            // any points on last path to redo
            if (lastLines.last.path.length > 0) {
              // save lastLines point before removing it
              if (lines.length == 0) {
                // copy lastLines last line with empty path
                List<Offset> newPath = [];
                DrawnLine newLine = DrawnLine(
                  newPath,
                  lastLines.last.color,
                  lastLines.last.width,
                );
                lines.add(newLine);
              }
              lines.last.path.add(lastLines.last.path.last);

              // remove lastLines last point
              lastLines.last.path.removeLast();
            } else {
              // since points gone, remove lastLines last line
              lastLines.removeLast();

              // save new last line
              if (lastLines.length > 0) {
                // copy lastLines last line with empty path
                List<Offset> newPath = [];
                DrawnLine newLine = DrawnLine(
                  newPath,
                  lastLines.last.color,
                  lastLines.last.width,
                );
                lines.add(newLine);
              }
            }
          }
          //dumpLines("bbb:");
          break;
      }
    });
  }

  Future<void> changeClearMode() async {
    setState(() {
      switch (clearMode) {
        case ClearMode.all:
          clearMode = ClearMode.line;
          ShowSnackbar('clear line');
          break;
        case ClearMode.line:
          clearMode = ClearMode.point;
          ShowSnackbar('clear point');
          break;
        case ClearMode.point:
          clearMode = ClearMode.redoAll;
          ShowSnackbar('redo all');
          break;
        case ClearMode.redoAll:
          clearMode = ClearMode.redoLine;
          ShowSnackbar('redo line');
          break;
        case ClearMode.redoLine:
          clearMode = ClearMode.redoPoint;
          ShowSnackbar('redo point');
          break;
        case ClearMode.redoPoint:
          clearMode = ClearMode.all;
          ShowSnackbar('clear all');
          break;
      }
    });
  }

  void ShowSnackbar(String text) {
    if (showMessages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 250),
          content: Text(text),
        ),
      );
    }
  }

  void ShowSnackbarLong(String text) {
    if (showMessages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 2000),
          content: Text(text),
        ),
      );
    }
  }

  Future<void> changeColors() async {
    setState(() {
      var last = colorsAvailable.last;
      colorsAvailable.removeLast();
      colorsAvailable.insert(0, last);
    });
  }

  Future<void> changeStrokes() async {
    setState(() {
      var last = strokesAvailable.last;
      strokesAvailable.removeLast();
      strokesAvailable.insert(0, last);
    });
  }

  Future<void> help() async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Center(
                        child: Text(
                      "Version 0.1",
                      style: Theme.of(context).textTheme.headline3,
                    )),
                    Divider(
                      height: 20.0,
                    ),
                    Container(
                      width: 300,
                      child: CheckboxListTile(
                        title: Text('Show Messages'),
                        onChanged: onShowMessages,
                        value: showMessages,
                      ),
                    ),
                    Container(
                      width: 300,
                      child: CheckboxListTile(
                        title: Text('Show Grid Lines'),
                        onChanged: onShowGrid,
                        value: showGrid,
                      ),
                    ),
                    Container(
                      width: 300,
                      child: CheckboxListTile(
                        title: Text('Snap to Grid'),
                        onChanged: onSnapToGrid,
                        value: snapToGrid,
                      ),
                    ),
                    Container(
                      width: 300,
                      child: CheckboxListTile(
                        title: Text('Only Straight Lines'),
                        onChanged: onStraightLines,
                        value: straightLines,
                      ),
                    ),
                    Container(
                      width: 300,
                      child: GestureDetector(
                        child: ListTile(
                          title: Text('Reset Colors'),
                          trailing: Icon(Icons.redo),
                        ),
                        onTap: onResetColors,
                      ),
                    ),
                    Container(
                      width: 300,
                      child: ListTile(
                        title: Text('Costomize Color'),
                        trailing: buildColorSelectButton(),
                      ),
                    ),
                    Divider(
                      height: 20.0,
                    ),
                    SizedBox(
                      height: 20.0,
                    ),
                    GestureDetector(
                      child: Center(
                        child: Text(
                          "flutter_drawing_app/README",
                          style: Theme.of(context)
                              .textTheme
                              .headline3
                              .copyWith(color: Colors.blue),
                        ),
                      ),
                      onTap: onHelp,
                    ),
                  ]),
            ),
          ],
        );
      },
    );
  }

  Future<void> onShowMessages(bool value) async {
    setState(() {
      showMessages = !showMessages;
    });
    toPrefs();
    Navigator.of(context).pop();
  }

  Future<void> onShowGrid(bool value) async {
    setState(() {
      showGrid = !showGrid;
    });
    toPrefs();
    Navigator.of(context).pop();
  }

  Future<void> onSnapToGrid(bool value) async {
    setState(() {
      snapToGrid = !snapToGrid;
    });
    toPrefs();
    Navigator.of(context).pop();
  }

  Future<void> onStraightLines(bool value) async {
    setState(() {
      straightLines = !straightLines;
    });
    toPrefs();
    Navigator.of(context).pop();
  }

  Future<void> onResetColors() async {
    setState(() {
      colorsAvailable = defaultColorsAvailable;
      selectedColor = colorsAvailable[0];
      // TODO rotate Color Toolkit to selected
    });
    toPrefs();
    Navigator.of(context).pop();
  }

  Future<void> onColorAddChange(Color color) async {
    if (color == nextColor) {
      return;
    }
    if (colorsAvailable.length >= 32) {
      Navigator.of(context).pop();
      ShowSnackbarLong('too many colors');
      return;
    }
    setState(() {
      nextColor = color;
    });
    toPrefs();
    //Navigator.of(context).pop();
  }

  Future<void> onHelp() async {
    await launch(
        'https://github.com/alpiepho/flutter_drawing_app/blob/master/README.md');
    Navigator.of(context).pop();
  }

  Widget buildColorSelectButton() {
    return Padding(
      padding: const EdgeInsets.all(0.0),
      child: FloatingActionButton(
        mini: true,
        backgroundColor: selectedColor,
        child: Container(),
        onPressed: onSelectColor,
      ),
    );
  }

  Future<void> onSelectColor() async {
    showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add a color! (EXPERIMENTAL)'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: selectedColor,
              onColorChanged: onColorAddChange,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Done'),
              onPressed: () {
                setState(() {
                  colorsAvailable.insert(0, nextColor);
                  selectedColor = nextColor;
                });
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> hide() async {
    setState(() {
      hidden = !hidden;
    });
  }

  @override
  Widget build(BuildContext context) {
    var isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return FutureBuilder(
      future: fromPrefs(),
      builder: (
        BuildContext context,
        AsyncSnapshot<dynamic> snapshot,
      ) {
        if (snapshot.hasData) {
          // Return page after reading preferences
          return Scaffold(
            backgroundColor: Color(0xFFFFFDE7),
            body: Stack(
              children: [
                buildAllPaths(context),
                buildCurrentPath(context),
                buildHelpToolbar(isPortrait),
                buildStrokeToolbar(isPortrait),
                buildColorToolbar(isPortrait),
                buildHideToolbar(isPortrait),
              ],
            ),
          );
        } else {
          // Return loading screen while reading preferences
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Future<bool> fromPrefs() async {
    if (prefsRead) {
      return true;
    }
    prefsRead = true;

    var prefs = await SharedPreferences.getInstance();

    int colorValue = prefs.getInt('selectedColor') ?? 0xff000000;
    selectedColor = Color(colorValue);
    selectedWidth = prefs.getDouble('selectedWidth') ?? 5.0;
    showMessages = prefs.getBool('showMessages') ?? true;
    showGrid = prefs.getBool('showGrid') ?? false;
    snapToGrid = prefs.getBool('snapToGrid') ?? false;
    straightLines = prefs.getBool('straightLines') ?? false;

    var count = prefs.getInt('colorsAvailableLength') ?? 0;
    if (count > 0) {
      colorsAvailable = [];
      //defaultColorsAvailable;
      for (int index = 0; index < count; index++) {
        var colorValue =
            prefs.getInt('colorsAvailable' + index.toString()) ?? 0;
        if (colorValue != 0) {
          colorsAvailable.add(Color(colorValue));
        }
      }
    }
    return true;
  }

  Future<void> toPrefs() async {
    var prefs = await SharedPreferences.getInstance();

    int temp = selectedColor.value;
    prefs.setInt('selectedColor', temp);
    prefs.setDouble('selectedWidth', selectedWidth);
    prefs.setBool('showMessages', showMessages);
    prefs.setBool('showGrid', showGrid);
    prefs.setBool('snapToGrid', snapToGrid);
    prefs.setBool('straightLines', straightLines);

    prefs.setInt('colorsAvailableLength', colorsAvailable.length);
    int index = 0;
    for (Color color in colorsAvailable) {
      temp = color.value;
      prefs.setInt('colorsAvailable' + index.toString(), temp);
      index++;
    }
  }

  Widget buildCurrentPath(BuildContext context) {
    return GestureDetector(
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      child: RepaintBoundary(
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          padding: EdgeInsets.all(4.0),
          color: Colors.transparent,
          alignment: Alignment.topLeft,
          child: StreamBuilder<DrawnLine>(
            stream: currentLineStreamController.stream,
            builder: (context, snapshot) {
              return CustomPaint(
                painter: Sketcher(
                  lines: [line],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget buildAllPaths(BuildContext context) {
    buildGrid(context);
    return RepaintBoundary(
      key: _globalKey,
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        color: Colors.transparent,
        padding: EdgeInsets.all(4.0),
        alignment: Alignment.topLeft,
        child: StreamBuilder<List<DrawnLine>>(
          stream: linesStreamController.stream,
          builder: (context, snapshot) {
            return CustomPaint(
              painter: Sketcher(
                lines: lines,
              ),
            );
          },
        ),
      ),
    );
  }

  void buildGrid(BuildContext context) {
    var gridShowing = (lines.length > 0 && lines.first.width == 1.0);
    // using fixed size since rotate can change sizes and this is not dynamic
    var width = 2000; //MediaQuery.of(context).size.width.round();
    var height = 2000; //MediaQuery.of(context).size.height.round();

    if (showGrid && !gridShowing) {
      var x = 0;
      while (x < width) {
        List<Offset> path = [
          Offset(x as double, 0.0),
          Offset(x as double, height as double)
        ];
        DrawnLine gridLine = DrawnLine(path, Colors.black12, 1.0);
        lines.insert(0, gridLine);
        x += gridSize;
      }
      var y = 0;
      while (y < height) {
        List<Offset> path = [
          Offset(0.0, y as double),
          Offset(width as double, y as double)
        ];
        DrawnLine gridLine = DrawnLine(path, Colors.black12, 1.0);
        lines.insert(0, gridLine);
        y += gridSize;
      }
    }
    if (!showGrid && gridShowing) {
      while (lines.length > 0 && lines.first.width == 1.0) {
        lines.removeAt(0);
      }
    }
  }

  void onPanStart(DragStartDetails details) {
    if (hidden) {
      return;
    }
    RenderBox box = context.findRenderObject();
    Offset point = gridPoint(box.globalToLocal(details.globalPosition));

    // detect swipeFromBottom that commonly occurs on mobile
    // then skip drawing
    var dy = point.dy.round();
    var maxy = MediaQuery.of(context).size.height - 10;
    //print(dy.toString());
    //print(maxy.toString());
    if (dy > maxy) {
      swipeFromBottom = true;
      return;
    }

    line = DrawnLine([point], selectedColor, selectedWidth);
    // clear saved lastLines
    lastLines = [];
  }

  void onPanUpdate(DragUpdateDetails details) {
    if (hidden) {
      return;
    }
    if (swipeFromBottom) {
      return;
    }
    RenderBox box = context.findRenderObject();
    Offset point = gridPoint(box.globalToLocal(details.globalPosition));
    if (straightLines) {
      // wont show as drawn, just keep last point
      lastPoint = point;
    } else {
      List<Offset> path = List.from(line.path)..add(point);
      line = DrawnLine(path, selectedColor, selectedWidth);
      currentLineStreamController.add(line);
    }
  }

  void onPanEnd(DragEndDetails details) {
    if (hidden) {
      return;
    }
    if (swipeFromBottom) {
      swipeFromBottom = false;
      return;
    }
    if (straightLines) {
      // finally draw the straight  line
      List<Offset> path = List.from(line.path)..add(lastPoint);
      line = DrawnLine(path, selectedColor, selectedWidth);
      currentLineStreamController.add(line);
    }
    lines = List.from(lines)..add(line);
    linesStreamController.add(lines);
  }

  Offset gridPoint(Offset point) {
    if (snapToGrid) {
      return Offset(gridX(point.dx), gridX(point.dy));
    }
    return point;
  }

  double gridX(double x) {
    int ix = x.round();
    ix = ((ix ~/ gridSize) * gridSize);
    return ix as double;
  }

  Widget buildHelpToolbar(bool isPortrait) {
    final children = hidden
        ? []
        : [
            buildHelpButton(),
          ];
    if (isPortrait) {
      return Positioned(
        bottom: 50.0,
        right: 15.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [...children],
        ),
      );
    } else {
      return Positioned(
        top: 25.0,
        right: 50.0,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [...children],
        ),
      );
    }
  }

  Widget buildHelpButton() {
    return GestureDetector(
      onTap: help,
      child: CircleAvatar(
        backgroundColor: Colors.transparent,
        child: Icon(
          Icons.settings,
          size: 30.0,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget buildStrokeToolbar(bool isPortrait) {
    // stroke buttons as List so we can rotate
    final strokeButtons = [];
    int count = 1;
    for (double stroke in strokesAvailable) {
      strokeButtons.add(buildStrokeButton(stroke));
      if (count++ >= 3) break;
    }
    strokeButtons.add(buildChangeStrokesButton());

    // all buttons as List so we can use with Row or Column below
    final children = hidden
        ? []
        : [
            ...strokeButtons,
          ];

    if (isPortrait) {
      return Positioned(
        bottom: 120.0,
        right: 10.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ...children,
          ],
        ),
      );
    } else {
      return Positioned(
        top: 20.0,
        right: 150.0,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [...children],
        ),
      );
    }
  }

  Widget buildStrokeButton(double strokeWidth) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedWidth = strokeWidth;
        });
        toPrefs();
      },
      child: Container(
        padding: const EdgeInsets.all(12.0),
        child: Container(
          width: strokeWidth * 2,
          height: strokeWidth * 2,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
            color: selectedColor,
            borderRadius: BorderRadius.circular(50.0),
          ),
        ),
      ),
    );
  }

  Widget buildChangeStrokesButton() {
    return GestureDetector(
      onTap: changeStrokes,
      child: CircleAvatar(
        backgroundColor: Colors.transparent,
        child: Text(
          "...",
          style: Theme.of(context).textTheme.headline3,
        ),
      ),
    );
  }

  Widget buildColorToolbar(bool isPortrait) {
    // color buttons as List so we can rotate
    final colorButtons = [];
    int count = 1;

    for (Color color in colorsAvailable) {
      colorButtons.add(buildColorButton(color));
      if (count++ >= 3) break;
    }
    colorButtons.add(buildChangeColorsButton());

    // all buttons as List so we can use with Row or Column below
    final children = hidden
        ? []
        : [
            buildClearButton(),
            buildChangeClearButton(),
            SizedBox(
              height: 20.0,
              width: 20.0,
            ),
            ...colorButtons,
          ];

    if (isPortrait) {
      return Positioned(
        top: 90.0,
        right: 10.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ...children,
          ],
        ),
      );
    } else {
      return Positioned(
        top: 20.0,
        left: 90.0,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ...children,
          ],
        ),
      );
    }
  }

  Widget buildColorButton(Color color) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: FloatingActionButton(
        mini: true,
        backgroundColor: color,
        child: Container(),
        onPressed: () {
          setState(() {
            selectedColor = color;
          });
          toPrefs();
        },
      ),
    );
  }

  Widget buildChangeColorsButton() {
    return GestureDetector(
      onTap: changeColors,
      child: CircleAvatar(
        backgroundColor: Colors.transparent,
        child: Text(
          "...",
          style: Theme.of(context).textTheme.headline3,
        ),
      ),
    );
  }

  Widget buildClearButton() {
    var icon;
    switch (clearMode) {
      case ClearMode.all:
        icon = Icons.create;
        break;
      case ClearMode.line:
        icon = Icons.undo;
        break;
      case ClearMode.point:
        icon = Icons.remove;
        break;
      case ClearMode.redoAll:
        icon = Icons.fast_forward;
        break;
      case ClearMode.redoLine:
        icon = Icons.redo;
        break;
      case ClearMode.redoPoint:
        icon = Icons.add;
        break;
    }
    return GestureDetector(
      onTap: clear,
      child: CircleAvatar(
        backgroundColor: Colors.blueGrey,
        child: Icon(
          icon,
          size: 20.0,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget buildChangeClearButton() {
    return GestureDetector(
      onTap: changeClearMode,
      child: CircleAvatar(
        backgroundColor: Colors.transparent,
        child: Text(
          "...",
          style: Theme.of(context).textTheme.headline3,
        ),
      ),
    );
  }

  Widget buildHideToolbar(bool isPortrait) {
    if (isPortrait) {
      return Positioned(
        top: 20.0,
        right: 15.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            buildHideButton(),
          ],
        ),
      );
    } else {
      return Positioned(
        top: 20.0,
        left: 15.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            buildHideButton(),
          ],
        ),
      );
    }
  }

  Widget buildHideButton() {
    final child = hidden
        ? Icon(
            Icons.keyboard_arrow_down,
            size: 30.0,
            color: Colors.black,
          )
        : Icon(
            Icons.keyboard_arrow_up,
            size: 30.0,
            color: Colors.black,
          );
    return GestureDetector(
      onTap: hide,
      child: CircleAvatar(
        backgroundColor: Colors.transparent,
        child: child,
      ),
    );
  }
}
