import 'dart:io' show FileSystemException;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PlatformImageLoader {
  static Future<Uint8List> load(
    String url,
    String cacheKey,
    BaseCacheManager cacheManager,
    Map<String, String>? headers,
  ) async {
    try {
      final file = await _loadFile(url, cacheKey, cacheManager, headers);
      return await file.readAsBytes();
    } on FileSystemException {
      await cacheManager.removeFile(cacheKey);

      final fileInfo = await cacheManager.downloadFile(
        url,
        key: cacheKey,
        authHeaders: headers ?? {},
        force: true,
      );

      return fileInfo.file.readAsBytes();
    }
  }

  static Future<dynamic> _loadFile(
    String url,
    String cacheKey,
    BaseCacheManager cacheManager,
    Map<String, String>? headers,
  ) async {
    final cachedFile = (await cacheManager.getFileFromMemory(cacheKey))?.file;

    return cachedFile ??
        cacheManager.getSingleFile(url, key: cacheKey, headers: headers ?? {});
  }

  static Widget build(
    Uint8List imageBytes, {
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
    required SvgErrorWidgetBuilder errorBuilder,
  }) {
    return SvgPicture.memory(
      imageBytes,
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
      matchTextDirection: matchTextDirection,
      allowDrawingOutsideViewBox: allowDrawingOutsideViewBox,
      // ignore: deprecated_member_use
      color: color,
      // ignore: deprecated_member_use
      colorBlendMode: colorBlendMode,
      semanticsLabel: semanticsLabel,
      excludeFromSemantics: excludeFromSemantics,
      colorFilter: colorFilter,
      placeholderBuilder: placeholderBuilder,
      theme: theme,
      errorBuilder: errorBuilder,
    );
  }
}
