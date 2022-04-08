import 'package:flutter/material.dart';

enum ClearMode {
  all,
  line,
  point,
  redoAll,
  redoLine,
  redoPoint,
}

class ClearButton extends StatelessWidget {
  const ClearButton({
    Key? key,
    required ClearMode this.clearMode,
    Function()? this.clear,
  }) : super(key: key);

  final ClearMode clearMode;
  final Function()? clear;

  @override
  Widget build(BuildContext context) {
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
}
