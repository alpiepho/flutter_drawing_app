import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;

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
  Color selectedColor = Colors.black;
  double selectedWidth = 5.0;
  bool hidden = false;

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
                      "For more details:",
                      style: Theme.of(context).textTheme.headline3,
                    )),
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
    if (!kIsWeb && !isPortrait) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Container(
            width: 1000,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                new Text(
                  "Landscape mode is not supported.",
                  style: Theme.of(context).textTheme.headline3.copyWith(
                        color: Colors.white,
                      ),
                )
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.yellow[50],
      body: Stack(
        children: [
          buildAllPaths(context),
          buildCurrentPath(context),
          buildHelpToolbar(),
          buildStrokeToolbar(),
          buildColorToolbar(),
          buildHideToolbar(),
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

  void onPanStart(DragStartDetails details) {
    RenderBox box = context.findRenderObject();
    Offset point = box.globalToLocal(details.globalPosition);
    line = DrawnLine([point], selectedColor, selectedWidth);
  }

  void onPanUpdate(DragUpdateDetails details) {
    RenderBox box = context.findRenderObject();
    Offset point = box.globalToLocal(details.globalPosition);

    List<Offset> path = List.from(line.path)..add(point);
    line = DrawnLine(path, selectedColor, selectedWidth);
    currentLineStreamController.add(line);
  }

  void onPanEnd(DragEndDetails details) {
    lines = List.from(lines)..add(line);

    linesStreamController.add(lines);
  }

  Widget buildHelpToolbar() {
    final children = hidden
        ? []
        : [
            buildHelpButton(),
          ];
    return Positioned(
      bottom: 50.0,
      right: 10.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [...children],
      ),
    );
  }

  Widget buildHelpButton() {
    return GestureDetector(
      onTap: help,
      child: CircleAvatar(
        backgroundColor: Colors.transparent,
        child: Icon(
          Icons.question_mark,
          size: 30.0,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget buildStrokeToolbar() {
    final children = hidden
        ? []
        : [
            buildStrokeButton(5.0),
            buildStrokeButton(10.0),
            buildStrokeButton(15.0),
          ];
    return Positioned(
      bottom: 150.0,
      right: 10.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [...children],
      ),
    );
  }

  Widget buildStrokeButton(double strokeWidth) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedWidth = strokeWidth;
        });
      },
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Container(
          width: strokeWidth * 2,
          height: strokeWidth * 2,
          decoration: BoxDecoration(
              color: selectedColor, borderRadius: BorderRadius.circular(50.0)),
        ),
      ),
    );
  }

  Widget buildColorToolbar() {
    final children = hidden
        ? []
        : [
            buildClearButton(),
            Divider(
              height: 20.0,
            ),
            buildColorButton(Colors.red),
            buildColorButton(Colors.blueAccent),
            buildColorButton(Colors.deepOrange),
            buildColorButton(Colors.green),
            buildColorButton(Colors.lightBlue),
            buildColorButton(Colors.black),
            buildColorButton(Colors.white),
          ];
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
        child: Icon(
          Icons.create,
          size: 20.0,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget buildHideToolbar() {
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
