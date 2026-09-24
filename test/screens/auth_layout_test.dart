import 'package:evercare/screens/authentication/auth_widgets.dart';
import 'package:evercare/screens/authentication/login_screen.dart';
import 'package:evercare/screens/authentication/registration_screen.dart';
import 'package:evercare/theme/app_theme.dart';
import 'package:evercare/widgets/app_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpAuthLayout(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double scale = 1,
  double keyboardHeight = 0,
  List<Widget>? children,
  Widget? screen,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          viewInsets: EdgeInsets.only(bottom: keyboardHeight),
        ),
        child: child!,
      ),
      home:
          screen ??
          AuthPage(
            title: 'Create your account',
            subtitle: 'A little about you helps us personalize your care.',
            children:
                children ??
                [
                  for (var i = 1; i <= 8; i++)
                    AppTextField(label: 'Field $i', icon: Icons.person_outline),
                  const AuthErrorMessage(
                    message: 'Check your connection and try signing in again.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: () {}, child: const Text('Continue')),
                ],
          ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('brand stays fixed while only the form scrolls', (tester) async {
    await pumpAuthLayout(tester);
    final brand = find.byKey(const ValueKey('auth-fixed-brand'));
    final scroll = find.byKey(const ValueKey('auth-form-scroll'));
    final start = tester.getRect(brand);
    final firstFieldY = tester.getTopLeft(find.text('Field 1')).dy;
    expect(find.byType(EverCareLogo), findsOneWidget);
    expect(find.text('EverCare'), findsOneWidget);
    expect(find.text('Care, made simpler'), findsOneWidget);
    await tester.drag(scroll, const Offset(0, -450));
    await tester.pumpAndSettle();
    expect(tester.getRect(brand), start);
    expect(find.text('Care, made simpler').hitTestable(), findsOneWidget);
    expect(tester.getTopLeft(find.text('Field 1')).dy, lessThan(firstFieldY));
    expect(tester.takeException(), isNull);
  });

  for (final scenario in [
    (
      name: 'narrow large text',
      size: const Size(320, 720),
      scale: 3.0,
      keyboard: 0.0,
    ),
    (
      name: 'narrow keyboard',
      size: const Size(320, 720),
      scale: 1.3,
      keyboard: 320.0,
    ),
    (
      name: 'large text keyboard',
      size: const Size(320, 720),
      scale: 3.0,
      keyboard: 320.0,
    ),
    (
      name: 'landscape keyboard',
      size: const Size(640, 360),
      scale: 3.0,
      keyboard: 140.0,
    ),
  ]) {
    testWidgets('auth form remains usable with ${scenario.name}', (
      tester,
    ) async {
      await pumpAuthLayout(
        tester,
        size: scenario.size,
        scale: scenario.scale,
        keyboardHeight: scenario.keyboard,
      );
      final brand = find.byKey(const ValueKey('auth-fixed-brand'));
      final initialBrand = tester.getRect(brand);
      await tester.ensureVisible(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(tester.getRect(brand), initialBrand);
      expect(find.text('Continue').hitTestable(), findsOneWidget);
      expect(find.text('EverCare').hitTestable(), findsOneWidget);
      expect(find.byType(EverCareLogo).hitTestable(), findsOneWidget);
      expect(find.text('Care, made simpler').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final screen in [const LoginScreen(), const RegistrationScreen()]) {
    testWidgets('${screen.runtimeType} keeps branding above a scaled form', (
      tester,
    ) async {
      await pumpAuthLayout(
        tester,
        screen: screen,
        size: const Size(320, 720),
        scale: 3,
        keyboardHeight: 320,
      );
      final brand = find.byKey(const ValueKey('auth-fixed-brand'));
      final initialBrand = tester.getRect(brand);
      final footer = find.byType(AuthAccountLink);
      await tester.ensureVisible(footer);
      await tester.pumpAndSettle();
      expect(tester.getRect(brand), initialBrand);
      expect(find.text('EverCare').hitTestable(), findsOneWidget);
      expect(find.text('Care, made simpler').hitTestable(), findsOneWidget);
      expect(footer.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('login actions retain comfortable touch targets', (tester) async {
    await pumpAuthLayout(tester, screen: const LoginScreen());
    for (final label in ['Back', 'Show password']) {
      final button = find.byTooltip(label);
      expect(tester.getSize(button).width, greaterThanOrEqualTo(48));
      expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
    }
    final forgotPassword = find.widgetWithText(TextButton, 'Forgot password?');
    expect(tester.getSize(forgotPassword).height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
  });

  testWidgets('role choices wrap and expose the selected state', (
    tester,
  ) async {
    var selected = 'Senior';
    await pumpAuthLayout(
      tester,
      size: const Size(320, 720),
      scale: 3,
      children: [
        StatefulBuilder(
          builder: (context, setState) => Column(
            children: [
              for (final role in ['Senior', 'Caregiver', 'Family Member'])
                AuthRoleOption(
                  label: role,
                  description: 'Choose the role that fits your care.',
                  selected: selected == role,
                  onSelected: () => setState(() => selected = role),
                ),
            ],
          ),
        ),
      ],
    );
    await tester.ensureVisible(find.text('Family Member'));
    await tester.tap(find.text('Family Member'));
    await tester.pumpAndSettle();
    expect(selected, 'Family Member');
    final options = tester.widgetList<AuthRoleOption>(
      find.byType(AuthRoleOption),
    );
    expect(
      options.where((option) => option.selected).single.label,
      'Family Member',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('revealed passwords still disable keyboard suggestions', (
    tester,
  ) async {
    await pumpAuthLayout(
      tester,
      children: const [
        AppTextField(
          label: 'Password',
          icon: Icons.lock_outline,
          obscureText: false,
          autofillHints: [AutofillHints.password],
        ),
      ],
    );
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.enableSuggestions, isFalse);
    expect(field.autocorrect, isFalse);
  });
}
