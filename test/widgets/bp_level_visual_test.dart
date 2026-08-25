import 'package:evercare/models/blood_pressure_assessment.dart';
import 'package:evercare/widgets/bp_level_visual.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps every blood-pressure category to its dedicated hero asset', () {
    expect(
      {
        for (final category in BloodPressureCategory.values)
          category: bloodPressureHeroAssetFor(category),
      },
      {
        BloodPressureCategory.lowerThanUsual:
            'assets/health/bp_levels/bp_lower_hero.webp',
        BloodPressureCategory.normal:
            'assets/health/bp_levels/bp_normal_hero.webp',
        BloodPressureCategory.elevated:
            'assets/health/bp_levels/bp_elevated_hero.webp',
        BloodPressureCategory.hypertensionStage1:
            'assets/health/bp_levels/bp_stage1_hero.webp',
        BloodPressureCategory.hypertensionStage2:
            'assets/health/bp_levels/bp_stage2_hero.webp',
        BloodPressureCategory.severeHypertension:
            'assets/health/bp_levels/bp_severe_hero.webp',
      },
    );
  });

  test('all generated production assets are bundled and non-empty', () async {
    final paths = <String>{
      for (final category in BloodPressureCategory.values)
        bloodPressureHeroAssetFor(category),
      'assets/ai_mascot/evercare_ai_mascot_main.png',
      'assets/ai_mascot/evercare_ai_mascot_icon.png',
      evercareAiMascotAvatarAsset,
    };

    for (final path in paths) {
      final data = await rootBundle.load(path);
      expect(data.lengthInBytes, greaterThan(1000), reason: path);
    }
  });

  testWidgets('BP level visual uses a stable key and decorative semantics', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 320,
          height: 180,
          child: BpLevelVisual(
            category: BloodPressureCategory.hypertensionStage2,
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byKey(bpLevelVisualKey));
    expect(
      _assetName(image.image),
      'assets/health/bp_levels/bp_stage2_hero.webp',
    );
    expect(image.excludeFromSemantics, isTrue);
    expect(image.fit, BoxFit.cover);
    expect(image.alignment, Alignment.centerRight);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AI mascot uses its production asset and decorative semantics', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Center(child: AiMascotAvatar(size: 56))),
    );

    final image = tester.widget<Image>(find.byKey(evercareAiMascotKey));
    expect(_assetName(image.image), evercareAiMascotAvatarAsset);
    expect(image.excludeFromSemantics, isTrue);
    expect(image.fit, BoxFit.contain);

    final avatar = tester.getSize(find.byType(AiMascotAvatar));
    expect(avatar, const Size.square(56));
    expect(tester.takeException(), isNull);
  });
}

String _assetName(ImageProvider<Object> provider) {
  final unwrapped = provider is ResizeImage ? provider.imageProvider : provider;
  return (unwrapped as AssetImage).assetName;
}
