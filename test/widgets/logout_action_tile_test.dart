import 'dart:ui' show Tristate;

import 'package:evercare/screens/profile/logout_action_tile.dart';
import 'package:evercare/theme/app_colors.dart';
import 'package:evercare/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpTile(
    WidgetTester tester, {
    VoidCallback? onTap,
    bool isLoading = false,
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: LogoutActionTile(onTap: onTap, isLoading: isLoading),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('uses an opaque pink surface without any layered shadow', (
    tester,
  ) async {
    await pumpTile(tester, onTap: () {});
    final surface = tester.widget<Material>(
      find.byKey(const ValueKey('logout-tile-surface')),
    );
    expect(surface.color, AppColors.destructiveContainer);
    expect(surface.color!.a, 1);
    expect(surface.elevation, 0);
    expect(surface.shadowColor, Colors.transparent);
    expect(surface.surfaceTintColor, Colors.transparent);
    final shape = surface.shape! as RoundedRectangleBorder;
    expect(shape.side.style, BorderStyle.solid);
    for (final box in tester.widgetList<DecoratedBox>(
      find.descendant(
        of: find.byType(LogoutActionTile),
        matching: find.byType(DecoratedBox),
      ),
    )) {
      if (box.decoration case final BoxDecoration decoration) {
        expect(decoration.boxShadow, anyOf(isNull, isEmpty));
      }
    }
    expect(
      tester.getSize(find.byType(InkWell)).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('has a working tap and one accessible button label', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var taps = 0;
    await pumpTile(tester, onTap: () => taps++);
    expect(find.bySemanticsLabel('Log Out'), findsOneWidget);
    final node = tester.getSemantics(find.bySemanticsLabel('Log Out'));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    expect(node.getSemanticsData().flagsCollection.isButton, isTrue);
    expect(node.getSemanticsData().flagsCollection.isEnabled, Tristate.isTrue);
    await tester.tap(find.text('Log Out'));
    expect(taps, 1);
    semantics.dispose();
  });

  testWidgets('loading announces signing out and ignores repeated taps', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var taps = 0;
    await pumpTile(tester, onTap: () => taps++, isLoading: true);
    expect(find.text('Signing out…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    expect(tester.widget<InkWell>(find.byType(InkWell)).onTap, isNull);
    final node = tester.getSemantics(find.bySemanticsLabel('Signing out…'));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
    expect(node.getSemanticsData().flagsCollection.isEnabled, Tristate.isFalse);
    expect(node.getSemanticsData().flagsCollection.isLiveRegion, isTrue);
    await tester.tap(find.text('Signing out…'));
    expect(taps, 0);
    semantics.dispose();
  });

  testWidgets('320 px and 3x text fit in both action and loading states', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final loading in [false, true]) {
      await pumpTile(tester, onTap: () {}, isLoading: loading, textScale: 3);
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(InkWell)).height,
        greaterThanOrEqualTo(48),
      );
    }
  });
}
