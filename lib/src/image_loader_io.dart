import 'dart:io';

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
    var file = (await cacheManager.getFileFromMemory(cacheKey))?.file;

    file ??= await cacheManager.getSingleFile(
      url,
      key: cacheKey,
      headers: headers ?? {},
    );

    return file;
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
    final file = imageHandle as File;
    return SvgPicture.file(
      file,
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
