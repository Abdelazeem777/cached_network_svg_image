import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PlatformImageLoader {
  static Future<dynamic> load(
    String url,
    String cacheKey,
    BaseCacheManager cacheManager,
    Map<String, String>? headers,
  ) async {
    dynamic file = (await cacheManager.getFileFromMemory(cacheKey))?.file;
    // On web, getSingleFile returns a File-like object.
    // We use dynamic to avoid importing dart:io
    file ??= await cacheManager.getSingleFile(
      url,
      key: cacheKey,
      headers: headers ?? {},
    );

    // Read bytes asynchronously
    return await file.readAsBytes();
  }

  static Widget build(
    dynamic imageHandle, {
    required BoxFit fit,
    required double? width,
    required double? height,
    required AlignmentGeometry alignment,
    required bool matchTextDirection,
    required bool allowDrawingOutsideViewBox,
    required Color? color,
    required BlendMode colorBlendMode,
    required String? semanticsLabel,
    required bool excludeFromSemantics,
    required ColorFilter? colorFilter,
    required WidgetBuilder? placeholderBuilder,
    required SvgTheme theme,
  }) {
    final bytes = imageHandle as Uint8List;
    return SvgPicture.memory(
      bytes,
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
      matchTextDirection: matchTextDirection,
      allowDrawingOutsideViewBox: allowDrawingOutsideViewBox,
      color: color,
      colorBlendMode: colorBlendMode,
      semanticsLabel: semanticsLabel,
      excludeFromSemantics: excludeFromSemantics,
      colorFilter: colorFilter,
      placeholderBuilder: placeholderBuilder,
      theme: theme,
    );
  }
}
