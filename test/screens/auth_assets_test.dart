import 'dart:ui' as ui;

import 'package:evercare/screens/authentication/auth_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'auth artwork and official Google icon are bundled, decodable images',
    () async {
      for (final path in [
        AuthBackground.assetPath,
        'assets/images/google_g.png',
      ]) {
        final data = await rootBundle.load(path);
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        expect(frame.image.width, greaterThan(0));
        expect(frame.image.height, greaterThan(0));
        frame.image.dispose();
        codec.dispose();
      }
      final font = await rootBundle.load(
        'assets/fonts/google_sans_auth_medium.ttf',
      );
      expect(font.lengthInBytes, greaterThan(1000));
      expect(
        await rootBundle.loadString('assets/fonts/GoogleSans-OFL.txt'),
        contains('SIL OPEN FONT LICENSE'),
      );
    },
  );

  testWidgets('background artwork never intercepts form taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AuthBackground(
            child: Center(
              child: FilledButton(
                onPressed: () => taps++,
                child: const Text('Continue'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final artwork = find.byType(Image);
    expect(
      find.ancestor(of: artwork, matching: find.byType(ExcludeSemantics)),
      findsOneWidget,
    );
    expect(
      find.ancestor(of: artwork, matching: find.byType(IgnorePointer)),
      findsWidgets,
    );
    await tester.tap(find.text('Continue'));
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });
}
