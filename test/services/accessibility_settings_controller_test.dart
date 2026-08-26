import 'package:evercare/services/accessibility_settings_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('restores and persists app-wide accessibility preferences', () async {
    final preferences = _FakeSharedPreferencesAsync(<String, Object?>{
      AccessibilitySettingsController.textSizePreferenceKey:
          EverCareTextSize.extraLarge.name,
      AccessibilitySettingsController.reduceMotionPreferenceKey: true,
    });
    final settings = AccessibilitySettingsController(preferences: preferences);
    addTearDown(settings.dispose);

    await settings.load();

    expect(settings.isLoaded, isTrue);
    expect(settings.textSize, EverCareTextSize.extraLarge);
    expect(settings.textScaleMultiplier, 1.3);
    expect(settings.reduceMotion, isTrue);

    await settings.setTextSize(EverCareTextSize.large);
    await settings.setReduceMotion(false);

    expect(
      preferences.values[AccessibilitySettingsController.textSizePreferenceKey],
      EverCareTextSize.large.name,
    );
    expect(
      preferences.values[AccessibilitySettingsController
          .reduceMotionPreferenceKey],
      isFalse,
    );
  });

  test(
    'uses safe defaults when local preferences contain unknown data',
    () async {
      final settings = AccessibilitySettingsController(
        preferences: _FakeSharedPreferencesAsync(<String, Object?>{
          AccessibilitySettingsController.textSizePreferenceKey: 'huge',
          AccessibilitySettingsController.reduceMotionPreferenceKey: 'invalid',
        }),
      );
      addTearDown(settings.dispose);

      await settings.load();

      expect(settings.textSize, EverCareTextSize.standard);
      expect(settings.reduceMotion, isFalse);
    },
  );
}

class _FakeSharedPreferencesAsync implements SharedPreferencesAsync {
  _FakeSharedPreferencesAsync(this.values);

  final Map<String, Object?> values;

  @override
  Future<String?> getString(String key) async => values[key] as String?;

  @override
  Future<bool?> getBool(String key) async => values[key] as bool?;

  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> setBool(String key, bool value) async {
    values[key] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnsupportedError('Unexpected preference call: $invocation');
  }
}
