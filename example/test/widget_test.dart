// Smoke test for the example app. It runs without network access (the test
// binding answers every HTTP request with 400), so it checks the app shell
// and the Next button, not the downloaded images.

import 'package:cached_network_svg_image/cached_network_svg_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example/main.dart';

void main() {
  String? currentUrl(WidgetTester tester) {
    final key = tester.widget(find.byType(CachedNetworkSVGImage)).key;
    return (key as ValueKey<String>?)?.value;
  }

  testWidgets('Next button cycles through the images', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Cached Network SVG Image Demo'), findsOneWidget);
    final firstUrl = currentUrl(tester);
    expect(firstUrl, endsWith('SVG_logo.svg'));

    await tester.tap(find.byTooltip('Next'));
    await tester.pump();
    expect(currentUrl(tester), isNot(firstUrl));

    // 15 images in total: 14 more taps wrap around to the first one.
    for (var i = 0; i < 14; i++) {
      await tester.tap(find.byTooltip('Next'));
      await tester.pump();
    }
    expect(currentUrl(tester), firstUrl);

    // Let the widget's 15 ms placeholder timer fire before the test ends.
    await tester.pump(const Duration(milliseconds: 20));
  });
}
