import 'package:flutter/material.dart';

class ChangeClearButton extends StatelessWidget {
  const ChangeClearButton({
    Key? key,
    required Function()? this.onChange,
  }) : super(key: key);

  final Function()? onChange;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChange,
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
