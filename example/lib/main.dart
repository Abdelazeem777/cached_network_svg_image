import 'package:cached_network_svg_image/cached_network_svg_image.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cached Network SVG Image Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const _imagesUrlList = [
    'https://upload.wikimedia.org/wikipedia/commons/0/02/SVG_logo.svg',
    'https://upload.wikimedia.org/wikipedia/commons/7/71/Epsilon_letter%2C_Mega_Etymologikon%2C_1499.svg',
    'https://upload.wikimedia.org/wikipedia/commons/0/0a/Python.svg',
    'https://upload.wikimedia.org/wikipedia/commons/3/3f/Git_icon.svg',
    'https://upload.wikimedia.org/wikipedia/commons/9/96/Sass_Logo_Color.svg',
    'https://upload.wikimedia.org/wikipedia/commons/2/27/PHP-logo.svg',
    'https://upload.wikimedia.org/wikipedia/commons/5/57/Delta_letter%2C_Mega_Etymologikon%2C_1499.svg',
    'https://upload.wikimedia.org/wikipedia/commons/9/91/Electron_Software_Framework_Logo.svg',
    'https://upload.wikimedia.org/wikipedia/commons/e/e2/202009_Allosaurus_fragilis.svg',
    'https://upload.wikimedia.org/wikipedia/commons/6/61/HTML5_logo_and_wordmark.svg',
    'https://upload.wikimedia.org/wikipedia/commons/d/d5/CSS3_logo_and_wordmark.svg',
    'https://upload.wikimedia.org/wikipedia/commons/7/73/Ruby_logo.svg',
    'https://upload.wikimedia.org/wikipedia/commons/3/34/202101_Zebrafish.svg',
    'https://upload.wikimedia.org/wikipedia/commons/1/18/ISO_C%2B%2B_Logo.svg',
    'https://upload.wikimedia.org/wikipedia/commons/b/bb/Lamda_letter%2C_Mega_Etymologikon%2C_1499.svg',
  ];

  int _selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cached Network SVG Image Demo'),
      ),
      body: Center(
        child: CachedNetworkSVGImage(
          _imagesUrlList[_selectedIndex],
          placeholder: const CircularProgressIndicator(color: Colors.green),
          errorWidget: const Icon(Icons.error, color: Colors.red),
          width: 250.0,
          height: 250.0,
          fadeDuration: const Duration(milliseconds: 700),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _nextImage,
        tooltip: 'Next',
        child: const Icon(Icons.navigate_next),
      ),
    );
  }

  void _nextImage() => setState(() {
        _selectedIndex = (_selectedIndex + 1) % _imagesUrlList.length;
      });
}
