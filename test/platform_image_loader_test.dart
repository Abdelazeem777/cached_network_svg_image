// The deprecated `color` / `colorBlendMode` parameters are part of the public
// API and are tested on purpose.
// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:io' show File, HttpException;
import 'dart:typed_data';

import 'package:cached_network_svg_image/src/image_loader_io.dart' as io_loader;
import 'package:cached_network_svg_image/src/image_loader_web.dart'
    as web_loader;
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_cache_manager.dart';

// Both loaders expose the same static API; the conditional export in
// lib/src/image_loader.dart picks one per platform. image_loader_web.dart only
// uses dart:typed_data, so it can be exercised on the VM as well.

typedef _Load = Future<dynamic> Function(
  String url,
  String cacheKey,
  BaseCacheManager cacheManager,
  Map<String, String>? headers,
);

typedef _Build = Widget Function(
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
});

const _url = 'https://example.com/logo.svg';

void main() {
  _loaderTests(
    'io',
    load: io_loader.PlatformImageLoader.load,
    build: io_loader.PlatformImageLoader.build,
    readHandle: (handle) => (handle as File).readAsBytesSync(),
    bytesOf: (loader) => (loader as SvgFileLoader).file.readAsBytesSync(),
  );
  _loaderTests(
    'web',
    load: web_loader.PlatformImageLoader.load,
    build: web_loader.PlatformImageLoader.build,
    readHandle: (handle) => handle as Uint8List,
    bytesOf: (loader) => (loader as SvgBytesLoader).bytes,
  );
}

void _loaderTests(
  String platform, {
  required _Load load,
  required _Build build,
  required List<int> Function(dynamic handle) readHandle,
  required List<int> Function(BytesLoader loader) bytesOf,
}) {
  group('PlatformImageLoader ($platform)', () {
    late FakeCacheManager cacheManager;

    setUp(() {
      cacheManager = FakeCacheManager(responses: {_url: validSvgBytes});
    });

    SvgPicture buildPicture(
      dynamic handle, {
      Color? color,
      BlendMode colorBlendMode = BlendMode.srcIn,
      ColorFilter? colorFilter,
      SvgTheme theme = const SvgTheme(),
      WidgetBuilder? placeholderBuilder,
    }) {
      return build(
        handle,
        fit: BoxFit.fill,
        width: 30,
        height: 40,
        alignment: Alignment.bottomRight,
        matchTextDirection: true,
        allowDrawingOutsideViewBox: true,
        color: color,
        colorBlendMode: colorBlendMode,
        semanticsLabel: 'label',
        excludeFromSemantics: true,
        colorFilter: colorFilter,
        placeholderBuilder: placeholderBuilder,
        theme: theme,
      ) as SvgPicture;
    }

    test('load downloads with the given key and headers', () async {
      final handle = await load(_url, 'key', cacheManager, {'a': 'b'});

      expect(readHandle(handle), validSvgBytes);
      final call = cacheManager.getSingleFileCalls.single;
      expect(call.url, _url);
      expect(call.key, 'key');
      expect(call.headers, {'a': 'b'});
    });

    test('load sends empty headers when none are given', () async {
      await load(_url, 'key', cacheManager, null);

      expect(cacheManager.getSingleFileCalls.single.headers, isEmpty);
    });

    test('load prefers the memory cache', () async {
      cacheManager.seedMemoryCache('key', invalidSvgBytes);

      final handle = await load(_url, 'key', cacheManager, null);

      expect(readHandle(handle), invalidSvgBytes);
      expect(cacheManager.getFileFromMemoryCalls, ['key']);
      expect(cacheManager.getSingleFileCalls, isEmpty);
    });

    test('load propagates download errors', () {
      expect(
        load('https://example.com/missing.svg', 'k', cacheManager, null),
        throwsA(isA<HttpException>()),
      );
    });

    test('build forwards every option to SvgPicture', () async {
      final handle = await load(_url, 'key', cacheManager, null);
      Widget placeholderBuilder(BuildContext context) => const SizedBox();
      const theme = SvgTheme(currentColor: Colors.pink);

      final picture = buildPicture(
        handle,
        theme: theme,
        placeholderBuilder: placeholderBuilder,
      );

      expect(bytesOf(picture.bytesLoader), validSvgBytes);
      expect((picture.bytesLoader as SvgLoader).theme, theme);
      expect(picture.fit, BoxFit.fill);
      expect(picture.width, 30);
      expect(picture.height, 40);
      expect(picture.alignment, Alignment.bottomRight);
      expect(picture.matchTextDirection, isTrue);
      expect(picture.allowDrawingOutsideViewBox, isTrue);
      expect(picture.semanticsLabel, 'label');
      expect(picture.excludeFromSemantics, isTrue);
      expect(picture.placeholderBuilder, same(placeholderBuilder));
      expect(picture.colorFilter, isNull);
    });

    test('build bridges the deprecated color and colorBlendMode', () async {
      final handle = await load(_url, 'key', cacheManager, null);

      expect(
        buildPicture(handle, color: Colors.red).colorFilter,
        const ColorFilter.mode(Colors.red, BlendMode.srcIn),
      );
      expect(
        buildPicture(
          handle,
          color: Colors.red,
          colorBlendMode: BlendMode.modulate,
        ).colorFilter,
        const ColorFilter.mode(Colors.red, BlendMode.modulate),
      );
    });

    test('build prefers colorFilter over color', () async {
      final handle = await load(_url, 'key', cacheManager, null);
      const filter = ColorFilter.mode(Colors.green, BlendMode.dst);

      expect(
        buildPicture(handle, color: Colors.red, colorFilter: filter)
            .colorFilter,
        filter,
      );
    });

    testWidgets('build output decodes and lays out the SVG', (tester) async {
      final handle = await load(_url, 'key', cacheManager, null);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: buildPicture(handle)),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // Until the picture is decoded SvgPicture is a 30x40 placeholder box.
      // Once decoded it keeps the square SVG's aspect ratio at height 40.
      expect(tester.getSize(find.byType(SvgPicture)), const Size(40, 40));
    });
  });
}
