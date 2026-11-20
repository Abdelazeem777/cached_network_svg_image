import 'package:cached_network_svg_image/cached_network_svg_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const _imagesUrlList = [
    'https://upload.wikimedia.org/wikipedia/commons/0/02/SVG_logo.svg',
    'https://upload.wikimedia.org/wikipedia/commons/9/99/Unofficial_JavaScript_logo_2.svg',
    'https://upload.wikimedia.org/wikipedia/commons/0/0a/Python.svg',
    'https://upload.wikimedia.org/wikipedia/commons/3/3f/Git_icon.svg',
    'https://upload.wikimedia.org/wikipedia/commons/9/96/Sass_Logo_Color.svg',
    'https://upload.wikimedia.org/wikipedia/commons/2/27/PHP-logo.svg',
    'https://upload.wikimedia.org/wikipedia/commons/d/d9/Node.js_logo.svg',
    'https://upload.wikimedia.org/wikipedia/commons/9/91/Electron_Software_Framework_Logo.svg',
    'https://upload.wikimedia.org/wikipedia/commons/9/91/Octicons-mark-github.svg',
    'https://upload.wikimedia.org/wikipedia/commons/6/61/HTML5_logo_and_wordmark.svg',
    'https://upload.wikimedia.org/wikipedia/commons/d/d5/CSS3_logo_and_wordmark.svg',
    'https://upload.wikimedia.org/wikipedia/commons/7/73/Ruby_logo.svg',
    'https://upload.wikimedia.org/wikipedia/commons/a/a7/React-icon.svg',
    'https://upload.wikimedia.org/wikipedia/commons/1/18/ISO_C%2B%2B_Logo.svg',
    'https://raw.githubusercontent.com/dnfield/flutter_svg/master/packages/flutter_svg/example/assets/flutter_logo.svg',
  ];

  static const _userAgent =
      'cached_network_svg_image-example/2.1.0 (https://github.com/Abdelazeem777/cached_network_svg_image)';

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
          // Wikimedia's User-Agent policy rate-limits generic ones (dart:io's default); browsers can't set it.
          headers: kIsWeb ? null : const {'User-Agent': _userAgent},
          placeholder: const CircularProgressIndicator(
            color: Colors.green,
            semanticsLabel: 'Loading image',
          ),
          errorWidget: const Icon(
            Icons.error,
            color: Colors.red,
            semanticLabel: 'Failed to load image',
          ),
          width: 250.0,
          height: 250.0,
          fadeDuration: const Duration(milliseconds: 700),
          semanticsLabel: 'SVG image ${_selectedIndex + 1}',
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
