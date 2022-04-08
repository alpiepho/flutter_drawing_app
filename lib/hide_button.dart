import 'package:flutter/material.dart';

class HideButton extends StatelessWidget {
  const HideButton({
    Key? key,
    required bool this.hidden,
    required Function()? this.hide,
  }) : super(key: key);

  final bool hidden;
  final Function()? hide;

  @override
  Widget build(BuildContext context) {
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
