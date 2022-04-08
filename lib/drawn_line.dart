import 'package:flutter/material.dart';

class DrawnLine {
  List<Offset> path;
  Color color;
  double width;

  DrawnLine({
    required this.path,
    this.color = Colors.black,
    this.width = 1.0,
  });

  bool isEmpty() {
    return this.path.length == 0;
  }

  void clear() {
    this.path = [];
    this.color = Colors.black;
    this.width = 1.0;
  }
}
