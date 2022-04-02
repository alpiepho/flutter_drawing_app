import 'dart:async';

import 'package:drawing_app/drawn_line.dart';
import 'package:drawing_app/sketcher.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DrawingPage extends StatefulWidget {
  @override
  _DrawingPageState createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  GlobalKey _globalKey = new GlobalKey();
  List<DrawnLine> lines = <DrawnLine>[];
  DrawnLine line;
  Offset lastPoint;
  Color selectedColor = Colors.black;
  double selectedWidth = 5.0;
  bool hidden = false;
  int gridSize = 10;
  bool showGrid = false;
  bool snapToGrid = false;
  bool straightLines = false;

  StreamController<List<DrawnLine>> linesStreamController =
      StreamController<List<DrawnLine>>.broadcast();
  StreamController<DrawnLine> currentLineStreamController =
      StreamController<DrawnLine>.broadcast();

  Future<void> clear() async {
    setState(() {
      lines = [];
      line = null;
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
                      "Version: 0.1",
                      style: Theme.of(context).textTheme.headline3,
                    )),
                    Divider(
                      height: 20.0,
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

  Future<void> onShowGrid(bool value) async {
    setState(() {
      showGrid = !showGrid;
    });
    Navigator.of(context).pop();
  }

  Future<void> onSnapToGrid(bool value) async {
    setState(() {
      snapToGrid = !snapToGrid;
    });
    Navigator.of(context).pop();
  }

  Future<void> onStraightLines(bool value) async {
    setState(() {
      straightLines = !straightLines;
    });
    Navigator.of(context).pop();
  }

  Future<void> onHelp() async {
    await launch(
        'https://github.com/alpiepho/flutter_drawing_app/blob/master/README.md');
    Navigator.of(context).pop();
  }

  Future<void> hide() async {
    setState(() {
      hidden = !hidden;
    });
  }

  @override
  Widget build(BuildContext context) {
    var isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

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
    if (showGrid) {
      var width = MediaQuery.of(context).size.width;
      var height = MediaQuery.of(context).size.height;
      List<Offset> path = [Offset(10.0, 0.0), Offset(10.0, height)];
      DrawnLine gridLine = DrawnLine(path, Colors.black12, 1.0);

      lines.insert(0, gridLine);
    }
  }

  void onPanStart(DragStartDetails details) {
    if (hidden) {
      return;
    }
    RenderBox box = context.findRenderObject();
    Offset point = gridPoint(box.globalToLocal(details.globalPosition));
    line = DrawnLine([point], selectedColor, selectedWidth);
  }

  void onPanUpdate(DragUpdateDetails details) {
    if (hidden) {
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
    final children = hidden
        ? []
        : [
            buildStrokeButton(5.0),
            buildStrokeButton(10.0),
            buildStrokeButton(15.0),
          ];
    if (isPortrait) {
      return Positioned(
        bottom: 120.0,
        right: 10.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [...children],
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
      },
      child: Container(
        padding: const EdgeInsets.all(12.0),
        child: Container(
          width: strokeWidth * 2,
          height: strokeWidth * 2,
          decoration: BoxDecoration(
              color: selectedColor, borderRadius: BorderRadius.circular(50.0)),
        ),
      ),
    );
  }

  Widget buildColorToolbar(bool isPortrait) {
    final children = hidden
        ? []
        : [
            buildClearButton(),
            SizedBox(
              height: 20.0,
              width: 20.0,
            ),
            buildColorButton(Colors.red),
            buildColorButton(Colors.blueAccent),
            buildColorButton(Colors.yellow),
            buildColorButton(Colors.green),
            //buildColorButton(Colors.lightBlue),
            buildColorButton(Colors.black),
            buildColorButton(Colors.white),
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
        },
      ),
    );
  }

  Widget buildClearButton() {
    return GestureDetector(
      onTap: clear,
      child: CircleAvatar(
        backgroundColor: Colors.blueGrey,
        child: Icon(
          Icons.create, //.remove, //.undo, //.create,
          size: 20.0,
          color: Colors.white,
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
