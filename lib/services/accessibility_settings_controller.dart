import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The text-size choices offered by EverCare.
///
/// The multiplier is applied in addition to the device's own text scaling, so
/// a person who has already increased text size in Android or iOS does not
/// lose that accessibility preference.
enum EverCareTextSize {
  standard('Default', 1),
  large('Large', 1.15),
  extraLarge('Extra large', 1.3);

  const EverCareTextSize(this.label, this.multiplier);

  final String label;
  final double multiplier;

  static EverCareTextSize fromStorage(String? value) {
    return EverCareTextSize.values.firstWhere(
      (size) => size.name == value,
      orElse: () => EverCareTextSize.standard,
    );
  }
}

/// Holds the small set of accessibility preferences EverCare can apply
/// consistently throughout the app.
///
/// Settings are intentionally device-local. They are available before the
/// asynchronous restore finishes, then update the UI immediately whenever the
/// person makes a change.
class AccessibilitySettingsController extends ChangeNotifier {
  AccessibilitySettingsController({SharedPreferencesAsync? preferences})
    : _preferences = preferences;

  static const textSizePreferenceKey = 'evercare_accessibility_text_size';
  static const reduceMotionPreferenceKey =
      'evercare_accessibility_reduce_motion';

  SharedPreferencesAsync? _preferences;
  Future<void>? _loadFuture;
  EverCareTextSize _textSize = EverCareTextSize.standard;
  bool _reduceMotion = false;
  bool _hasLocalChanges = false;
  bool _isLoaded = false;

  EverCareTextSize get textSize => _textSize;
  double get textScaleMultiplier => _textSize.multiplier;
  bool get reduceMotion => _reduceMotion;
  bool get isLoaded => _isLoaded;

  SharedPreferencesAsync get _store =>
      _preferences ??= SharedPreferencesAsync();

  /// Restores settings once, without overriding a choice made while loading.
  Future<void> load() => _loadFuture ??= _restore();

  Future<void> _restore() async {
    EverCareTextSize restoredTextSize = EverCareTextSize.standard;
    var restoredReduceMotion = false;

    try {
      final values = await Future.wait<Object?>([
        _store.getString(textSizePreferenceKey),
        _store.getBool(reduceMotionPreferenceKey),
      ]);
      restoredTextSize = EverCareTextSize.fromStorage(values[0] as String?);
      restoredReduceMotion = values[1] as bool? ?? false;
    } catch (_) {
      // Accessibility defaults remain useful if local storage is unavailable.
    }

    if (!_hasLocalChanges) {
      _textSize = restoredTextSize;
      _reduceMotion = restoredReduceMotion;
    }
    _isLoaded = true;
    notifyListeners();
  }

  /// Applies the selected text size immediately, then saves it for next time.
  Future<void> setTextSize(EverCareTextSize value) async {
    if (_textSize == value) return;
    _hasLocalChanges = true;
    _textSize = value;
    notifyListeners();

    try {
      await _store.setString(textSizePreferenceKey, value.name);
    } catch (_) {
      // Keep the current-session preference even when persistence is blocked.
    }
  }

  /// Applies the motion preference immediately, then saves it for next time.
  Future<void> setReduceMotion(bool value) async {
    if (_reduceMotion == value) return;
    _hasLocalChanges = true;
    _reduceMotion = value;
    notifyListeners();

    try {
      await _store.setBool(reduceMotionPreferenceKey, value);
    } catch (_) {
      // Keep the current-session preference even when persistence is blocked.
    }
  }
}
