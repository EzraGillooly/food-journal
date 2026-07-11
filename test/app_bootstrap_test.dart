import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_journal/core/theme/app_theme.dart';
import 'package:food_journal/core/theme/theme_provider.dart';
import 'package:food_journal/features/auth/presentation/login_screen.dart';

void main() {
  test('default theme preset is Soft Blush', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(
      container.read(themeControllerProvider).preset,
      AppThemePreset.softBlush,
    );
  });

  testWidgets('login screen renders its fields', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Log in'), findsOneWidget);
  });

  testWidgets('login validates empty submit', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pump();
    expect(find.text('Enter your email'), findsOneWidget);
  });
}
