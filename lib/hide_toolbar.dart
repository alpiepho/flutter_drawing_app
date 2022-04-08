import 'package:flutter/material.dart';

import 'hide_button.dart';

class HideToolbar extends StatelessWidget {
  const HideToolbar({
    Key? key,
    required bool this.isPortrait,
    required bool this.hidden,
    required Function()? this.hide,
  }) : super(key: key);

  final bool isPortrait;
  final bool hidden;
  final Function()? hide;

  @override
  Widget build(BuildContext context) {
    if (isPortrait) {
      return Positioned(
        top: 20.0,
        right: 15.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            HideButton(
              hidden: hidden,
              hide: hide,
            ),
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
            HideButton(
              hidden: hidden,
              hide: hide,
            ),
          ],
        ),
      );
    }
  }
}
