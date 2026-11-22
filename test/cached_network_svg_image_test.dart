// The deprecated `color` / `colorBlendMode` parameters are part of the public
// API and are tested on purpose.
// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:async';
import 'dart:io' show HttpException;

import 'package:cached_network_svg_image/cached_network_svg_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_cache_manager.dart';

const _url = 'https://example.com/logo.svg';
const _brokenUrl = 'https://example.com/missing.svg';
const _placeholderKey = Key('placeholder');
const _errorKey = Key('error');

/// Long enough for the widget's 15 ms "show placeholder" timer to fire.
const _afterPlaceholderDelay = Duration(milliseconds: 20);

void main() {
  late FakeCacheManager cacheManager;

  setUp(() {
    cacheManager = FakeCacheManager(
      responses: {_url: validSvgBytes},
    );
  });

  Future<void> pumpImage(WidgetTester tester, Widget image) {
    return tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: image),
      ),
    );
  }

  /// Pumps [image] and lets the load, the placeholder timer and the default
  /// 300 ms fade-in finish.
  Future<void> pumpLoaded(WidgetTester tester, Widget image) async {
    await pumpImage(tester, image);
    await tester.pump(_afterPlaceholderDelay);
    await tester.pumpAndSettle();
  }

  SvgPicture svgPicture(WidgetTester tester) =>
      tester.widget<SvgPicture>(find.byType(SvgPicture));

  /// The bytes of the SVG file currently on screen.
  List<int> shownSvgBytes(WidgetTester tester) =>
      (svgPicture(tester).bytesLoader as SvgFileLoader).file.readAsBytesSync();

  /// The opacity of the fade-in around the SvgPicture.
  Animation<double> fadeOpacity(WidgetTester tester) => tester
      .widget<FadeTransition>(
        find.ancestor(
          of: find.byType(SvgPicture),
          matching: find.byType(FadeTransition),
        ),
      )
      .opacity;

  group('loading', () {
    testWidgets('asks the cache manager for the url with a query-free key',
        (tester) async {
      cacheManager.responses['$_url?v=2&token=abc'] = validSvgBytes;

      await pumpLoaded(
        tester,
        CachedNetworkSVGImage(
          '$_url?v=2&token=abc',
          headers: const {'Authorization': 'Bearer t'},
          cacheManager: cacheManager,
        ),
      );

      expect(cacheManager.getFileFromMemoryCalls, [_url]);
      expect(cacheManager.getSingleFileCalls, hasLength(1));
      final call = cacheManager.getSingleFileCalls.single;
      expect(call.url, '$_url?v=2&token=abc');
      expect(call.key, _url);
      expect(call.headers, {'Authorization': 'Bearer t'});
    });

    testWidgets('uses an explicit cacheKey instead of the url', (tester) async {
      await pumpLoaded(
        tester,
        CachedNetworkSVGImage(
          _url,
          cacheKey: 'my-key',
          cacheManager: cacheManager,
        ),
      );

      expect(cacheManager.getFileFromMemoryCalls, ['my-key']);
      expect(cacheManager.getSingleFileCalls.single.key, 'my-key');
      expect(cacheManager.getSingleFileCalls.single.url, _url);
    });

    testWidgets('sends an empty header map when no headers are given',
        (tester) async {
      await pumpLoaded(
        tester,
        CachedNetworkSVGImage(_url, cacheManager: cacheManager),
      );

      expect(cacheManager.getSingleFileCalls.single.headers, isEmpty);
    });

    testWidgets('serves a memory-cached file without downloading it',
        (tester) async {
      cacheManager.seedMemoryCache(_url, validSvgBytes);

      await pumpLoaded(
        tester,
        CachedNetworkSVGImage(_url, cacheManager: cacheManager),
      );

      expect(cacheManager.getSingleFileCalls, isEmpty);
      expect(find.byType(SvgPicture), findsOneWidget);
    });

    testWidgets('waits 15 ms before showing the placeholder', (tester) async {
      cacheManager.gate = Completer<void>();

      await pumpImage(
        tester,
        CachedNetworkSVGImage(
          _url,
          placeholder: const SizedBox(key: _placeholderKey),
          cacheManager: cacheManager,
        ),
      );
      await tester.pump(const Duration(milliseconds: 10));
      expect(find.byKey(_placeholderKey), findsNothing);

      await tester.pump(const Duration(milliseconds: 10));
      expect(find.byKey(_placeholderKey), findsOneWidget);
      expect(find.byType(SvgPicture), findsNothing);

      cacheManager.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(_placeholderKey), findsNothing);
      expect(find.byType(SvgPicture), findsOneWidget);
    });

    testWidgets('shows the placeholder centered inside width x height',
        (tester) async {
      cacheManager.gate = Completer<void>();

      await pumpImage(
        tester,
        CachedNetworkSVGImage(
          _url,
          width: 80,
          height: 40,
          placeholder: const SizedBox(key: _placeholderKey, width: 10),
          cacheManager: cacheManager,
        ),
      );
      await tester.pump(_afterPlaceholderDelay);

      expect(tester.getSize(find.byType(CachedNetworkSVGImage)),
          const Size(80, 40));
      expect(
        find.ancestor(
          of: find.byKey(_placeholderKey),
          matching: find.byType(Center),
        ),
        findsWidgets,
      );

      cacheManager.gate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('shows nothing while loading when no placeholder is given',
        (tester) async {
      cacheManager.gate = Completer<void>();

      await pumpImage(
        tester,
        CachedNetworkSVGImage(_url, cacheManager: cacheManager),
      );
      await tester.pump(_afterPlaceholderDelay);

      expect(find.byType(SvgPicture), findsNothing);
      expect(tester.takeException(), isNull);

      cacheManager.gate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('does not update after being disposed mid-load',
        (tester) async {
      cacheManager.gate = Completer<void>();

      await pumpImage(
        tester,
        CachedNetworkSVGImage(_url, cacheManager: cacheManager),
      );
      await pumpImage(tester, const SizedBox());

      cacheManager.gate!.complete();
      await tester.pump(_afterPlaceholderDelay);

      expect(tester.takeException(), isNull);
    });

    testWidgets('does not update after being disposed mid-load (error)',
        (tester) async {
      cacheManager.gate = Completer<void>();

      await pumpImage(
        tester,
        CachedNetworkSVGImage(_brokenUrl, cacheManager: cacheManager),
      );
      await pumpImage(tester, const SizedBox());

      cacheManager.gate!.complete();
      await tester.pump(_afterPlaceholderDelay);

      expect(tester.takeException(), isNull);
    });

    testWidgets('restarts the 15 ms placeholder delay when the url changes',
        (tester) async {
      const otherUrl = 'https://example.com/other.svg';
      const key = Key('avatar');
      cacheManager
        ..responses[otherUrl] = validSvgBytes
        ..gate = Completer<void>();

      Widget image(String url) => CachedNetworkSVGImage(
            url,
            key: key,
            placeholder: const SizedBox(key: _placeholderKey),
            cacheManager: cacheManager,
          );

      await pumpImage(tester, image(_url));
      await tester.pump(const Duration(milliseconds: 10));
      await pumpImage(tester, image(otherUrl));

      // 20 ms after the first load started, but only 10 ms into the new one.
      await tester.pump(const Duration(milliseconds: 10));
      expect(find.byKey(_placeholderKey), findsNothing);

      await tester.pump(const Duration(milliseconds: 10));
      expect(find.byKey(_placeholderKey), findsOneWidget);

      cacheManager.gate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('leaves no timer or update behind after quick url changes',
        (tester) async {
      const urls = [
        _url,
        'https://example.com/b.svg',
        'https://example.com/c.svg',
      ];
      cacheManager.gate = Completer<void>();

      for (final url in urls) {
        cacheManager.responses[url] = validSvgBytes;
        await pumpImage(
          tester,
          CachedNetworkSVGImage(
            url,
            placeholder: const SizedBox(key: _placeholderKey),
            cacheManager: cacheManager,
          ),
        );
        await tester.pump(const Duration(milliseconds: 5));
      }
      await pumpImage(tester, const SizedBox());

      // Finish the loads after dispose without moving the clock. A placeholder
      // timer still pending here makes the test binding fail the test.
      cacheManager.gate!.complete();
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('success', () {
    testWidgets('renders an SvgPicture and no placeholder or error widget',
        (tester) async {
      await pumpLoaded(
        tester,
        CachedNetworkSVGImage(
          _url,
          placeholder: const SizedBox(key: _placeholderKey),
          errorWidget: const SizedBox(key: _errorKey),
          cacheManager: cacheManager,
        ),
      );

      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.byKey(_placeholderKey), findsNothing);
      expect(find.byKey(_errorKey), findsNothing);
    });

    testWidgets('fades the image in over fadeDuration', (tester) async {
      await pumpImage(
        tester,
        CachedNetworkSVGImage(
          _url,
          fadeDuration: const Duration(milliseconds: 200),
          cacheManager: cacheManager,
        ),
      );
      await tester.pump(); // load completes, fade starts

      expect(fadeOpacity(tester).value, 0);
      await tester.pump(const Duration(milliseconds: 100));
      expect(fadeOpacity(tester).value, closeTo(0.5, 0.01));
      await tester.pump(const Duration(milliseconds: 100));
      expect(fadeOpacity(tester).value, 1);
    });

    testWidgets('uses the new fadeDuration after it changes', (tester) async {
      const otherUrl = 'https://example.com/other.svg';
      const key = Key('avatar');
      cacheManager.responses[otherUrl] = validSvgBytes;

      await pumpLoaded(
        tester,
        CachedNetworkSVGImage(
          _url,
          key: key,
          fadeDuration: const Duration(seconds: 1),
          cacheManager: cacheManager,
        ),
      );
      await pumpImage(
        tester,
        CachedNetworkSVGImage(
          otherUrl,
          key: key,
          fadeDuration: const Duration(milliseconds: 200),
          cacheManager: cacheManager,
        ),
      );
      await tester.pump(); // load completes, fade starts

      expect(fadeOpacity(tester).value, 0);
      await tester.pump(const Duration(milliseconds: 100));
      expect(fadeOpacity(tester).value, closeTo(0.5, 0.01));
      await tester.pump(const Duration(milliseconds: 100));
      expect(fadeOpacity(tester).value, 1);
    });

    testWidgets('passes layout and rendering options to SvgPicture',
        (tester) async {
      Widget placeholderBuilder(BuildContext context) => const SizedBox();
      const theme = SvgTheme(currentColor: Color(0xFF00FF00), fontSize: 20);

      await pumpLoaded(
        tester,
        CachedNetworkSVGImage(
          _url,
          width: 120,
          height: 60,
          fit: BoxFit.cover,
          alignment: Alignment.topLeft,
          matchTextDirection: true,
          allowDrawingOutsideViewBox: true,
          placeholderBuilder: placeholderBuilder,
          theme: theme,
          cacheManager: cacheManager,
        ),
      );

      final picture = svgPicture(tester);
      expect(picture.width, 120);
      expect(picture.height, 60);
      expect(picture.fit, BoxFit.cover);
      expect(picture.alignment, Alignment.topLeft);
      expect(picture.matchTextDirection, isTrue);
      expect(picture.allowDrawingOutsideViewBox, isTrue);
      expect(picture.placeholderBuilder, same(placeholderBuilder));
      expect((picture.bytesLoader as SvgLoader).theme, theme);
      expect(tester.getSize(find.byType(CachedNetworkSVGImage)),
          const Size(120, 60));
    });

    testWidgets('uses the documented defaults', (tester) async {
      await pumpLoaded(
        tester,
        CachedNetworkSVGImage(_url, cacheManager: cacheManager),
      );

      final picture = svgPicture(tester);
      expect(picture.width, isNull);
      expect(picture.height, isNull);
      expect(picture.fit, BoxFit.contain);
      expect(picture.alignment, Alignment.center);
      expect(picture.matchTextDirection, isFalse);
      expect(picture.allowDrawingOutsideViewBox, isFalse);
      expect(picture.excludeFromSemantics, isFalse);
      expect(picture.semanticsLabel, isNull);
      expect(picture.colorFilter, isNull);
      expect((picture.bytesLoader as SvgLoader).theme, const SvgTheme());
    });

    testWidgets('exposes semanticsLabel to accessibility services',
        (tester) async {
      final semantics = tester.ensureSemantics();

      await pumpLoaded(
        tester,
        CachedNetworkSVGImage(
          _url,
          semanticsLabel: 'Company logo',
          cacheManager: cacheManager,
        ),
      );

      expect(svgPicture(tester).semanticsLabel, 'Company logo');
      expect(find.bySemanticsLabel('Company logo'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('excludeFromSemantics hides the label', (tester) async {
      final semantics = tester.ensureSemantics();

      await pumpLoaded(
        tester,
        CachedNetworkSVGImage(
          _url,
          semanticsLabel: 'Company logo',
          excludeFromSemantics: true,
          cacheManager: cacheManager,
        ),
      );

      expect(svgPicture(tester).excludeFromSemantics, isTrue);
      expect(find.bySemanticsLabel('Company logo'), findsNothing);
      semantics.dispose();
    });
  });

  group('color', () {
    testWidgets('deprecated color becomes a srcIn ColorFilter', (tester) async {
      await pumpLoaded(
        tester,
        CachedNetworkSVGImage(
          _url,
          color: Colors.blue,
          cacheManager: cacheManager,
        ),
      );

      expect(
        svgPicture(tester).colorFilter,
        const ColorFilter.mode(Colors.blue, BlendMode.srcIn),
      );
    });

    testWidgets('deprecated colorBlendMode is honored', (tester) async {
      await pumpLoaded(
        tester,
        CachedNetworkSVGImage(
          _url,
          color: Colors.blue,
          colorBlendMode: BlendMode.multiply,
          cacheManager: cacheManager,
        ),
      );

      expect(
        svgPicture(tester).colorFilter,
        const ColorFilter.mode(Colors.blue, BlendMode.multiply),
      );
    });

    testWidgets('colorBlendMode alone does nothing', (tester) async {
      await pumpLoaded(
        tester,
        CachedNetworkSVGImage(
          _url,
          colorBlendMode: BlendMode.multiply,
          cacheManager: cacheManager,
        ),
      );

      expect(svgPicture(tester).colorFilter, isNull);
    });

    testWidgets('colorFilter wins over the deprecated color', (tester) async {
      const filter = ColorFilter.mode(Colors.green, BlendMode.dstIn);

      await pumpLoaded(
        tester,
        CachedNetworkSVGImage(
          _url,
          color: Colors.blue,
          colorBlendMode: BlendMode.multiply,
          colorFilter: filter,
          cacheManager: cacheManager,
        ),
      );

      expect(svgPicture(tester).colorFilter, filter);
    });
  });

  group('errors', () {
    testWidgets('shows errorWidget when the download fails', (tester) async {
      await pumpLoaded(
        tester,
        CachedNetworkSVGImage(
          _brokenUrl,
          placeholder: const SizedBox(key: _placeholderKey),
          errorWidget: const SizedBox(key: _errorKey),
          cacheManager: cacheManager,
        ),
      );

      expect(find.byKey(_errorKey), findsOneWidget);
      expect(find.byKey(_placeholderKey), findsNothing);
      expect(find.byType(SvgPicture), findsNothing);
    });

    testWidgets('shows errorWidget for any exception from the cache manager',
        (tester) async {
      cacheManager.errors[_url] = StateError('disk full');

      await pumpLoaded(
        tester,
        CachedNetworkSVGImage(
          _url,
          errorWidget: const SizedBox(key: _errorKey),
          cacheManager: cacheManager,
        ),
      );

      expect(find.byKey(_errorKey), findsOneWidget);
    });

    testWidgets(
        'replaces the placeholder with errorWidget after a slow failure',
        (tester) async {
      cacheManager
        ..gate = Completer<void>()
        ..errors[_url] = const HttpException('timeout');

      await pumpImage(
        tester,
        CachedNetworkSVGImage(
          _url,
          placeholder: const SizedBox(key: _placeholderKey),
          errorWidget: const SizedBox(key: _errorKey),
          cacheManager: cacheManager,
        ),
      );
      await tester.pump(_afterPlaceholderDelay);
      expect(find.byKey(_placeholderKey), findsOneWidget);

      cacheManager.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(_placeholderKey), findsNothing);
      expect(find.byKey(_errorKey), findsOneWidget);
    });

    testWidgets('shows nothing on failure when no errorWidget is given',
        (tester) async {
      await pumpLoaded(
        tester,
        CachedNetworkSVGImage(_brokenUrl, cacheManager: cacheManager),
      );

      expect(find.byType(SvgPicture), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not throw when the downloaded bytes are not an SVG',
        (tester) async {
      cacheManager.responses[_url] = invalidSvgBytes;

      await pumpLoaded(
        tester,
        CachedNetworkSVGImage(_url, cacheManager: cacheManager),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'shows errorWidget when the downloaded bytes are not an SVG',
      (tester) async {
        cacheManager.responses[_url] = invalidSvgBytes;

        await pumpLoaded(
          tester,
          CachedNetworkSVGImage(
            _url,
            errorWidget: const SizedBox(key: _errorKey),
            cacheManager: cacheManager,
          ),
        );

        expect(find.byKey(_errorKey), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'renders an empty box when the bytes are not an SVG and no errorWidget '
      'is given',
      (tester) async {
        cacheManager.responses[_url] = invalidSvgBytes;

        await pumpLoaded(
          tester,
          CachedNetworkSVGImage(_url, cacheManager: cacheManager),
        );

        expect(find.byType(SvgPicture), findsOneWidget);
        expect(find.byType(Center), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('identity', () {
    testWidgets('does not set a widget key by default', (tester) async {
      final image = CachedNetworkSVGImage(_url, cacheManager: cacheManager);
      expect(image.key, isNull);

      const explicit = Key('explicit');
      expect(
        CachedNetworkSVGImage(_url, key: explicit, cacheManager: cacheManager)
            .key,
        explicit,
      );
    });

    testWidgets('two siblings with the same url build without a key clash',
        (tester) async {
      await pumpLoaded(
        tester,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CachedNetworkSVGImage(_url, cacheManager: cacheManager),
            CachedNetworkSVGImage(_url, cacheManager: cacheManager),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(SvgPicture), findsNWidgets(2));
    });

    testWidgets('urls that differ only by query share one cache entry',
        (tester) async {
      cacheManager.responses['$_url?v=1'] = validSvgBytes;

      await pumpLoaded(
        tester,
        CachedNetworkSVGImage('$_url?v=1', cacheManager: cacheManager),
      );
      await pumpLoaded(
        tester,
        CachedNetworkSVGImage('$_url?v=2', cacheManager: cacheManager),
      );

      expect(cacheManager.getSingleFileCalls, hasLength(1));
      expect(cacheManager.getFileFromMemoryCalls, [_url, _url]);
      expect(find.byType(SvgPicture), findsOneWidget);
    });

    testWidgets('two images with the same cacheKey download once',
        (tester) async {
      await pumpLoaded(
        tester,
        CachedNetworkSVGImage(_url, cacheKey: 'k', cacheManager: cacheManager),
      );
      await pumpLoaded(
        tester,
        CachedNetworkSVGImage(
          'https://other.example.com/x.svg',
          cacheKey: 'k',
          cacheManager: cacheManager,
        ),
      );

      expect(cacheManager.getSingleFileCalls, hasLength(1));
      expect(find.byType(SvgPicture), findsOneWidget);
    });

    testWidgets('loads the new image when the url changes', (tester) async {
      const otherUrl = 'https://example.com/other.svg';
      cacheManager.responses[otherUrl] = validSvgBytes;

      await pumpLoaded(
        tester,
        CachedNetworkSVGImage(_url, cacheManager: cacheManager),
      );
      final first = svgPicture(tester).bytesLoader;

      await pumpLoaded(
        tester,
        CachedNetworkSVGImage(otherUrl, cacheManager: cacheManager),
      );

      expect(
          cacheManager.getSingleFileCalls.map((c) => c.url), [_url, otherUrl]);
      expect(svgPicture(tester).bytesLoader, isNot(first));
    });

    testWidgets(
      'loads the new image when the url changes under an explicit key',
      (tester) async {
        const otherUrl = 'https://example.com/other.svg';
        cacheManager.responses[otherUrl] = validSvgBytes;
        const key = Key('avatar');

        await pumpLoaded(
          tester,
          CachedNetworkSVGImage(_url, key: key, cacheManager: cacheManager),
        );
        await pumpLoaded(
          tester,
          CachedNetworkSVGImage(otherUrl, key: key, cacheManager: cacheManager),
        );

        expect(cacheManager.getSingleFileCalls.map((c) => c.url),
            [_url, otherUrl]);
      },
    );

    testWidgets('loads the new image when only the cacheKey changes',
        (tester) async {
      const key = Key('avatar');

      await pumpLoaded(
        tester,
        CachedNetworkSVGImage(_url,
            key: key, cacheKey: 'a', cacheManager: cacheManager),
      );
      await pumpLoaded(
        tester,
        CachedNetworkSVGImage(_url,
            key: key, cacheKey: 'b', cacheManager: cacheManager),
      );

      expect(cacheManager.getSingleFileCalls.map((c) => c.key), ['a', 'b']);
    });

    testWidgets('does not reload when rebuilt with the same url and key',
        (tester) async {
      const key = Key('avatar');

      await pumpLoaded(
        tester,
        CachedNetworkSVGImage(_url, key: key, cacheManager: cacheManager),
      );
      await pumpLoaded(
        tester,
        CachedNetworkSVGImage(_url, key: key, cacheManager: cacheManager),
      );

      expect(cacheManager.getSingleFileCalls, hasLength(1));
    });

    testWidgets('a stale in-flight load does not overwrite the new one',
        (tester) async {
      const otherUrl = 'https://example.com/other.svg';
      const key = Key('avatar');
      cacheManager.responses[otherUrl] = validSvgBytes;
      final firstGate = Completer<void>();
      final secondGate = Completer<void>();
      cacheManager.gate = firstGate;

      await pumpImage(
        tester,
        CachedNetworkSVGImage(_url, key: key, cacheManager: cacheManager),
      );
      await tester.pump(_afterPlaceholderDelay);

      cacheManager.gate = secondGate;
      await pumpImage(
        tester,
        CachedNetworkSVGImage(otherUrl, key: key, cacheManager: cacheManager),
      );

      // The new load finishes first, then the stale one (which now fails).
      cacheManager.responses.remove(_url);
      secondGate.complete();
      await tester.pumpAndSettle();
      expect(find.byType(SvgPicture), findsOneWidget);

      firstGate.complete();
      await tester.pumpAndSettle();
      expect(find.byType(SvgPicture), findsOneWidget);
    });

    testWidgets('a stale load that succeeds late does not replace the new one',
        (tester) async {
      const otherUrl = 'https://example.com/other.svg';
      const key = Key('avatar');
      cacheManager.responses[otherUrl] = otherSvgBytes;
      final firstGate = Completer<void>();
      final secondGate = Completer<void>();
      cacheManager.gate = firstGate;

      await pumpImage(
        tester,
        CachedNetworkSVGImage(_url, key: key, cacheManager: cacheManager),
      );
      await tester.pump(_afterPlaceholderDelay);

      cacheManager.gate = secondGate;
      await pumpImage(
        tester,
        CachedNetworkSVGImage(otherUrl, key: key, cacheManager: cacheManager),
      );

      // The new load finishes first, then the stale one (which succeeds).
      secondGate.complete();
      await tester.pumpAndSettle();
      expect(shownSvgBytes(tester), otherSvgBytes);

      firstGate.complete();
      await tester.pumpAndSettle();

      // A rebuild that does not reload must still show the new image.
      await pumpImage(
        tester,
        CachedNetworkSVGImage(otherUrl, key: key, cacheManager: cacheManager),
      );
      expect(shownSvgBytes(tester), otherSvgBytes);
    });
  });

  group('static helpers', () {
    test('preCache downloads the url so a later image skips the network',
        () async {
      await CachedNetworkSVGImage.preCache(_url, cacheManager: cacheManager);

      expect(cacheManager.downloadFileCalls.single.url, _url);
      expect(cacheManager.cachedKeys, [_url]);
    });

    testWidgets('an image after preCache is served from memory',
        (tester) async {
      await CachedNetworkSVGImage.preCache(_url, cacheManager: cacheManager);

      await pumpLoaded(
        tester,
        CachedNetworkSVGImage(_url, cacheManager: cacheManager),
      );

      expect(cacheManager.getSingleFileCalls, isEmpty);
      expect(find.byType(SvgPicture), findsOneWidget);
    });

    test('preCache propagates download errors', () {
      expect(
        CachedNetworkSVGImage.preCache(_brokenUrl, cacheManager: cacheManager),
        throwsA(isA<HttpException>()),
      );
    });

    test(
      'preCache with a cacheKey downloads the url and stores it under the key',
      () async {
        await CachedNetworkSVGImage.preCache(
          _url,
          cacheKey: 'my-key',
          cacheManager: cacheManager,
        );

        final call = cacheManager.downloadFileCalls.single;
        expect(call.url, _url);
        expect(call.key ?? call.url, 'my-key');
      },
    );

    test(
      'preCache keeps the query string in the download url',
      () async {
        const signedUrl = '$_url?token=abc';
        cacheManager.responses[signedUrl] = validSvgBytes;

        await CachedNetworkSVGImage.preCache(
          signedUrl,
          cacheManager: cacheManager,
        );

        final call = cacheManager.downloadFileCalls.single;
        expect(call.url, signedUrl);
        expect(call.key ?? call.url, _url);
      },
    );

    test('clearCacheForUrl removes the query-free url key', () async {
      await CachedNetworkSVGImage.clearCacheForUrl(
        '$_url?v=3',
        cacheManager: cacheManager,
      );

      expect(cacheManager.removedKeys, [_url]);
    });

    test('clearCacheForUrl removes an explicit cacheKey', () async {
      await CachedNetworkSVGImage.clearCacheForUrl(
        _url,
        cacheKey: 'my-key',
        cacheManager: cacheManager,
      );

      expect(cacheManager.removedKeys, ['my-key']);
    });

    testWidgets('an image after clearCacheForUrl downloads again',
        (tester) async {
      await pumpLoaded(
        tester,
        CachedNetworkSVGImage(_url, cacheManager: cacheManager),
      );
      await pumpImage(tester, const SizedBox());

      await CachedNetworkSVGImage.clearCacheForUrl(
        _url,
        cacheManager: cacheManager,
      );
      await pumpLoaded(
        tester,
        CachedNetworkSVGImage(_url, cacheManager: cacheManager),
      );

      expect(cacheManager.getSingleFileCalls, hasLength(2));
    });

    test('clearCache empties the cache manager', () async {
      cacheManager.seedMemoryCache(_url, validSvgBytes);

      await CachedNetworkSVGImage.clearCache(cacheManager: cacheManager);

      expect(cacheManager.emptyCacheCalls, 1);
      expect(cacheManager.cachedKeys, isEmpty);
    });
  });
}
