import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp()); // runAppはFlutterの基本的な関数
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Loop App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ImageLoop(), // ImageLoopウィジェットを呼び出す
    );
  }
}

class ImageLoop extends StatefulWidget {
  @override
  _ImageLoopState createState() => _ImageLoopState();
}

class _ImageLoopState extends State<ImageLoop> {
  int _currentIndex = 0;
  final List<String> _imagePaths = [
    'assets/START.png',
    'assets/A.png',
    'assets/B.png',
    'assets/C.png',
    'assets/END.png'
  ];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 5), (Timer timer) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % _imagePaths.length;
      });
      if (_currentIndex == 0 && timer.tick >= 5) {
        // 50秒経過（5秒 * 5回）
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Image Loop')),
      body: Center(
        child: Image.asset(_imagePaths[_currentIndex]),
      ),
    );
  }
}
