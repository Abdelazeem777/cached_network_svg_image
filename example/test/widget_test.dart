// Smoke test for the example app. It runs without network access (the test
// binding answers every HTTP request with 400), so it checks the app shell
// and the Next button, not the downloaded images.

import 'package:cached_network_svg_image/cached_network_svg_image.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('Next button cycles through the images', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Cached Network SVG Image Demo'), findsOneWidget);
    expect(find.byType(CachedNetworkSVGImage), findsOneWidget);
    expect(find.text('1 / 15'), findsOneWidget);

    await tester.tap(find.byTooltip('Next'));
    await tester.pump();
    expect(find.text('2 / 15'), findsOneWidget);

    // 15 images in total: 14 more taps wrap around to the first one.
    for (var i = 0; i < 14; i++) {
      await tester.tap(find.byTooltip('Next'));
      await tester.pump();
    }
    expect(find.text('1 / 15'), findsOneWidget);

    // Let the widget's 15 ms placeholder timer fire before the test ends.
    await tester.pump(const Duration(milliseconds: 20));
  });
}
