import 'package:flutter/material.dart';

class ChangeColorsButton extends StatelessWidget {
  const ChangeColorsButton({
    Key? key,
    Function()? this.changeColors,
  }) : super(key: key);

  final Function()? changeColors;

  @override
  Widget build(BuildContext context) {
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
}
