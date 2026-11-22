library cached_network_svg_image;

import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'src/image_loader.dart';

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
    @deprecated Color? color,
    @deprecated BlendMode colorBlendMode = BlendMode.srcIn,
    String? semanticsLabel,
    bool excludeFromSemantics = false,
    SvgTheme theme = const SvgTheme(),
    Duration fadeDuration = const Duration(milliseconds: 300),
    ColorFilter? colorFilter,
    WidgetBuilder? placeholderBuilder,
    BaseCacheManager? cacheManager,
  })  : _url = url,
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
        _color = color,
        _colorBlendMode = colorBlendMode,
        _semanticsLabel = semanticsLabel,
        _excludeFromSemantics = excludeFromSemantics,
        _theme = theme,
        _fadeDuration = fadeDuration,
        _colorFilter = colorFilter,
        _placeholderBuilder = placeholderBuilder,
        _cacheManager = cacheManager ?? DefaultCacheManager(),
        super(key: key);

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
  final Color? _color;
  final BlendMode _colorBlendMode;
  final String? _semanticsLabel;
  final bool _excludeFromSemantics;
  final SvgTheme _theme;
  final Duration _fadeDuration;
  final ColorFilter? _colorFilter;
  final WidgetBuilder? _placeholderBuilder;
  final BaseCacheManager _cacheManager;

  @override
  State<CachedNetworkSVGImage> createState() => _CachedNetworkSVGImageState();

  static Future<void> preCache(
    String imageUrl, {
    String? cacheKey,
    BaseCacheManager? cacheManager,
  }) {
    final key = cacheKey ?? _generateKeyFromUrl(imageUrl);
    cacheManager ??= DefaultCacheManager();
    return cacheManager.downloadFile(imageUrl, key: key);
  }

  static Future<void> clearCacheForUrl(
    String imageUrl, {
    String? cacheKey,
    BaseCacheManager? cacheManager,
  }) {
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

class _CachedNetworkSVGImageState extends State<CachedNetworkSVGImage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _isError = false;

  // ignore: prefer_typing_uninitialized_variables
  var _imageFile;

  late String _cacheKey;

  /// Incremented for every load, so a load that finishes after the widget
  /// changed (or was disposed) can tell it is stale and drop its result.
  int _loadId = 0;

  /// Shows the placeholder if the current load takes longer than 15 ms.
  Timer? _loadingTimer;

  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _cacheKey = widget._cacheKey ??
        CachedNetworkSVGImage._generateKeyFromUrl(widget._url);
    _controller = AnimationController(
      vsync: this,
      duration: widget._fadeDuration,
    );
    _animation = Tween(begin: 0.0, end: 1.0).animate(_controller);
    _loadImage();
  }

  @override
  void didUpdateWidget(CachedNetworkSVGImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newKey = widget._cacheKey ??
        CachedNetworkSVGImage._generateKeyFromUrl(widget._url);
    if (newKey == _cacheKey &&
        widget._url == oldWidget._url &&
        widget._cacheManager == oldWidget._cacheManager &&
        mapEquals(widget._headers, oldWidget._headers)) {
      return;
    }
    _cacheKey = newKey;
    _imageFile = null;
    _isError = false;
    _isLoading = false;
    _controller.reset();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final loadId = ++_loadId;
    _startLoadingTimer(loadId);
    try {
      final imageFile = await PlatformImageLoader.load(
        widget._url,
        _cacheKey,
        widget._cacheManager,
        widget._headers,
      );
      if (loadId != _loadId) return;

      _loadingTimer?.cancel();
      _imageFile = imageFile;
      _isLoading = false;

      _setState();

      if (mounted) {
        _controller.forward();
      }
    } catch (e) {
      if (loadId != _loadId) return;
      log('CachedNetworkSVGImage: $e');

      _loadingTimer?.cancel();
      _isError = true;
      _isLoading = false;

      _setState();
    }
  }

  /// Replaces any pending placeholder timer with one for load [loadId], so a
  /// reload restarts the 15 ms delay and an older load never shows it.
  void _startLoadingTimer(int loadId) {
    _loadingTimer?.cancel();
    _loadingTimer = Timer(const Duration(milliseconds: 15), () {
      if (loadId != _loadId) return;
      if (!_isLoading && _imageFile == null && !_isError) {
        _isLoading = true;
        _setState();
      }
    });
  }

  void _setState() => mounted ? setState(() {}) : null;

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _loadId++; // Marks any in-flight load as stale.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget._width,
      height: widget._height,
      child: _buildImage(),
    );
  }

  Widget _buildImage() {
    if (_isLoading) return _buildPlaceholderWidget();

    if (_isError) return _buildErrorWidget();

    return FadeTransition(
      opacity: _animation,
      child: _buildSVGImage(),
    );
  }

  Widget _buildPlaceholderWidget() =>
      Center(child: widget._placeholder ?? const SizedBox());

  Widget _buildErrorWidget() =>
      Center(child: widget._errorWidget ?? const SizedBox());

  Widget _buildSVGImage() {
    if (_imageFile == null) return const SizedBox();

    return PlatformImageLoader.build(
      _imageFile,
      fit: widget._fit,
      width: widget._width,
      height: widget._height,
      alignment: widget._alignment,
      matchTextDirection: widget._matchTextDirection,
      allowDrawingOutsideViewBox: widget._allowDrawingOutsideViewBox,
      color: widget._color,
      colorBlendMode: widget._colorBlendMode,
      semanticsLabel: widget._semanticsLabel,
      excludeFromSemantics: widget._excludeFromSemantics,
      colorFilter: widget._colorFilter,
      placeholderBuilder: widget._placeholderBuilder,
      errorWidget: widget._errorWidget,
      theme: widget._theme,
    );
  }
}
