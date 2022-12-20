library cached_network_svg_image;

import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CachedNetworkSVGImage extends StatefulWidget {
  CachedNetworkSVGImage(
    String url, {
    Key? key,
    Widget? placeholder,
    Widget? errorWidget,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    AlignmentGeometry alignment = Alignment.center,
    bool matchTextDirection = false,
    bool allowDrawingOutsideViewBox = false,
    Color? color,
    BlendMode colorBlendMode = BlendMode.srcIn,
    String? semanticsLabel,
    bool excludeFromSemantics = false,
    Clip clipBehavior = Clip.hardEdge,
    bool cacheColorFilter = false,
    SvgTheme? theme,
  })  : _url = url,
        _placeholder = placeholder,
        _errorWidget = errorWidget,
        _width = width,
        _height = height,
        _fit = fit,
        _alignment = alignment,
        _matchTextDirection = matchTextDirection,
        _allowDrawingOutsideViewBox = allowDrawingOutsideViewBox,
        _color = color,
        _colorBlendMode = colorBlendMode,
        _semanticsLabel = semanticsLabel,
        _excludeFromSemantics = excludeFromSemantics,
        _clipBehavior = clipBehavior,
        _cacheColorFilter = cacheColorFilter,
        _theme = theme,
        super(key: key ?? ValueKey(url));

  final String _url;
  final Widget? _placeholder;
  final Widget? _errorWidget;
  final double? _width;
  final double? _height;
  final BoxFit _fit;
  final AlignmentGeometry _alignment;
  final bool _matchTextDirection;
  final bool _allowDrawingOutsideViewBox;
  final Color? _color;
  final BlendMode _colorBlendMode;
  final String? _semanticsLabel;
  final bool _excludeFromSemantics;
  final Clip _clipBehavior;
  final bool _cacheColorFilter;
  final SvgTheme? _theme;

  @override
  State<CachedNetworkSVGImage> createState() => _CachedNetworkSVGImageState();
}

class _CachedNetworkSVGImageState extends State<CachedNetworkSVGImage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isError = false;
  File? _imageFile;

  late final DefaultCacheManager _cacheManager;
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _cacheManager = DefaultCacheManager();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween(begin: 0.0, end: 1.0).animate(_controller);
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final file = await _cacheManager.getSingleFile(widget._url);
      setState(() {
        _imageFile = file;
        _isLoading = false;
      });
      _controller.forward();
    } catch (e) {
      log('CachedNetworkSVGImage: $e');
      setState(() {
        _isError = true;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildPlaceholderWidget();

    if (_isError) return _buildErrorWidget();

    return FadeTransition(
      opacity: _animation,
      child: _buildSVGImage(),
    );
  }

  Widget _buildPlaceholderWidget() => widget._placeholder ?? const SizedBox();

  Widget _buildErrorWidget() => widget._errorWidget ?? const SizedBox();

  Widget _buildSVGImage() {
    try {
      final child = SvgPicture.file(
        _imageFile!,
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
        clipBehavior: widget._clipBehavior,
        cacheColorFilter: widget._cacheColorFilter,
        theme: widget._theme,
      );
      return child;
    } catch (e) {
      log('CachedNetworkSVGImage: $e');
      return _buildErrorWidget();
    }
  }
}
