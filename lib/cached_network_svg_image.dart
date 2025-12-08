library cached_network_svg_image;

import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Builder function to create an error widget. This builder is called when
/// the image failed loading, for example due to a 404 NotFound exception.
typedef ErrorWidgetBuilder = Widget Function(BuildContext context, String url, Object error);

class CachedNetworkSVGImage extends StatefulWidget {
  CachedNetworkSVGImage(
    String url, {
    Key? key,
    String? cacheKey,
    Widget? placeholder,
    Widget? errorWidget,
    double? width,
    double? height,
    Map<String, String>? headers,
    BoxFit fit = BoxFit.contain,
    AlignmentGeometry alignment = Alignment.center,
    bool matchTextDirection = false,
    bool allowDrawingOutsideViewBox = false,
    String? semanticsLabel,
    bool excludeFromSemantics = false,
    SvgTheme theme = const SvgTheme(),
    Duration fadeDuration = const Duration(milliseconds: 300),
    ColorFilter? colorFilter,
    WidgetBuilder? placeholderBuilder,
    ErrorWidgetBuilder? errorBuilder,
    BaseCacheManager? cacheManager,
  }) : _url = url,
       _cacheKey = cacheKey,
       _placeholder = placeholder,
       _errorWidget = errorWidget,
       _width = width,
       _height = height,
       _headers = headers,
       _fit = fit,
       _alignment = alignment,
       _matchTextDirection = matchTextDirection,
       _allowDrawingOutsideViewBox = allowDrawingOutsideViewBox,
       _semanticsLabel = semanticsLabel,
       _excludeFromSemantics = excludeFromSemantics,
       _theme = theme,
       _fadeDuration = fadeDuration,
       _colorFilter = colorFilter,
       _errorBuilder = errorBuilder,
       _placeholderBuilder = placeholderBuilder,
       _cacheManager = cacheManager ?? DefaultCacheManager(),
       super(key: key ?? ValueKey(url));

  final String _url;
  final String? _cacheKey;
  final Widget? _placeholder;
  final Widget? _errorWidget;
  final double? _width;
  final double? _height;
  final Map<String, String>? _headers;
  final BoxFit _fit;
  final AlignmentGeometry _alignment;
  final bool _matchTextDirection;
  final bool _allowDrawingOutsideViewBox;
  final String? _semanticsLabel;
  final bool _excludeFromSemantics;
  final SvgTheme _theme;
  final Duration _fadeDuration;
  final ColorFilter? _colorFilter;
  final ErrorWidgetBuilder? _errorBuilder;
  final WidgetBuilder? _placeholderBuilder;
  final BaseCacheManager _cacheManager;

  @override
  State<CachedNetworkSVGImage> createState() => _CachedNetworkSVGImageState();

  static Future<void> preCache(String imageUrl, {String? cacheKey, BaseCacheManager? cacheManager}) {
    final key = cacheKey ?? _generateKeyFromUrl(imageUrl);
    cacheManager ??= DefaultCacheManager();
    return cacheManager.downloadFile(key);
  }

  static Future<void> clearCacheForUrl(String imageUrl, {String? cacheKey, BaseCacheManager? cacheManager}) {
    final key = cacheKey ?? _generateKeyFromUrl(imageUrl);
    cacheManager ??= DefaultCacheManager();
    return cacheManager.removeFile(key);
  }

  static Future<void> clearCache({BaseCacheManager? cacheManager}) {
    cacheManager ??= DefaultCacheManager();
    return cacheManager.emptyCache();
  }

  static String _generateKeyFromUrl(String url) => url.split('?').first;
}

class _CachedNetworkSVGImageState extends State<CachedNetworkSVGImage> with SingleTickerProviderStateMixin {
  bool _isLoading = false;

  Object? _error;
  XFile? _imageFile;
  late String _cacheKey;

  late final AnimationController _controller;
  late final Animation<double> _animation;

  bool get _isError => _error != null;

  @override
  void initState() {
    super.initState();
    _cacheKey = widget._cacheKey ?? CachedNetworkSVGImage._generateKeyFromUrl(widget._url);
    _controller = AnimationController(vsync: this, duration: widget._fadeDuration);
    _animation = Tween(begin: 0.0, end: 1.0).animate(_controller);
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      _setToLoadingAfter15MsIfNeeded();

      var file = (await widget._cacheManager.getFileFromMemory(_cacheKey))?.file;

      file ??= await widget._cacheManager.getSingleFile(widget._url, key: _cacheKey, headers: widget._headers ?? {});

      _imageFile = XFile(file.path, length: file.lengthSync(), bytes: file.readAsBytesSync());
      _isLoading = false;

      _setState();

      _controller.forward();
    } catch (e) {
      log('CachedNetworkSVGImage: $e');

      _error = e;
      _isLoading = false;

      _setState();
    }
  }

  void _setToLoadingAfter15MsIfNeeded() => Future.delayed(const Duration(milliseconds: 15), () {
    if (!_isLoading && _imageFile == null && !_isError) {
      _isLoading = true;
      _setState();
    }
  });

  void _setState() => mounted ? setState(() {}) : null;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: widget._width, height: widget._height, child: _buildImage());
  }

  Widget _buildImage() {
    if (_isLoading) return _buildPlaceholderWidget();

    if (_error case final error?) return _buildErrorWidget(error);

    return FadeTransition(opacity: _animation, child: _buildSVGImage());
  }

  Widget _buildPlaceholderWidget() =>
      widget._placeholderBuilder?.call(context) ?? widget._placeholder ?? const SizedBox();

  Widget _buildErrorWidget(Object error) =>
      widget._errorBuilder?.call(context, widget._url, error) ?? widget._errorWidget ?? const SizedBox();

  Widget _buildSVGImage() {
    final imageFile = _imageFile;

    if (imageFile == null) return const SizedBox();

    return SvgPicture(
      _SvgXFileLoader(imageFile, theme: widget._theme),
      fit: widget._fit,
      width: widget._width,
      height: widget._height,
      alignment: widget._alignment,
      matchTextDirection: widget._matchTextDirection,
      allowDrawingOutsideViewBox: widget._allowDrawingOutsideViewBox,
      semanticsLabel: widget._semanticsLabel,
      excludeFromSemantics: widget._excludeFromSemantics,
      colorFilter: widget._colorFilter,
      placeholderBuilder: widget._placeholderBuilder,
    );
  }
}

class _SvgXFileLoader extends SvgLoader<Uint8List> {
  const _SvgXFileLoader(this.file, {super.theme});

  final XFile file;

  @override
  Future<Uint8List> prepareMessage(_) async => (await file.readAsBytes()).buffer.asUint8List();

  @override
  String provideSvg(Uint8List? message) {
    final data = message;
    if (data == null) throw StateError('SVG bytes are missing');

    return utf8.decode(data, allowMalformed: true);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is _SvgXFileLoader && runtimeType == other.runtimeType && file == other.file;

  @override
  int get hashCode => file.hashCode;

  @override
  String toString() => '_SvgXFileLoader(file: $file)';
}
