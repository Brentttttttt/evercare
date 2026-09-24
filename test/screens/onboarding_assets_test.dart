import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final name in [
    'care_at_home',
    'daily_care',
    'connected_care',
    'safety_support',
  ]) {
    test('onboarding $name is bundled and decodable', () async {
      final bytes = await rootBundle.load('assets/images/onboarding/$name.png');
      final codec = await ui.instantiateImageCodec(
        bytes.buffer.asUint8List(),
        targetWidth: 384,
      );
      try {
        final frame = await codec.getNextFrame();
        try {
          expect(frame.image.width, 384);
          expect(frame.image.width / frame.image.height, closeTo(1.5, .02));
        } finally {
          frame.image.dispose();
        }
      } finally {
        codec.dispose();
      }
    });
  }
}
