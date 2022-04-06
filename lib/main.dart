import 'package:drawing_app/drawing_page.dart';
import 'package:flutter/material.dart';

import 'config/theme.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drawing App',
      debugShowCheckedModeBanner: false,
      theme: theme(),
      home: SafeArea(
        top: false,
        bottom: false,
        left: false,
        right: false,
        child: DrawingPage(),
      ),
    );
  }
}
