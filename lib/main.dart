import 'package:drawing_app/drawing_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'config/theme.dart';

void main() {
  //runApp(MyApp());

  // We need to call it manually,
  // because we going to call configurations
  // before the runApp() call
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(statusBarColor: Colors.black));

  // Than we setup preferred orientations,
  // and only after it finished we run our app
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((value) => runApp(MyApp()));
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
