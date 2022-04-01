import 'package:drawing_app/drawing_page.dart';
import 'package:flutter/material.dart';

import 'config/theme.dart';

void main() {
  runApp(MyApp());

  // // We need to call it manually,
  // // because we going to call configurations
  // // before the runApp() call
  // WidgetsFlutterBinding.ensureInitialized();

  // // Hide status bar
  // SystemChrome.setPreferredOrientations(orientations).setEnabledSystemUIOverlays([]);

  // // Than we setup preferred orientations,
  // // and only after it finished we run our app
  // SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
  //     .then((value) => runApp(DrawingApp()));
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
