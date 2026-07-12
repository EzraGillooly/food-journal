import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_journal/features/settings/theme_creator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('theme creator renders its content (not just a barrier)', (
    tester,
  ) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Builder(
            builder: (ctx) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showThemeCreator(ctx),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Header, a picker label, and the save button must all be present and sized.
    expect(find.text('Custom theme'), findsOneWidget);
    expect(find.text('Background'), findsOneWidget);
    expect(find.text('Save & apply'), findsOneWidget);
    expect(tester.getSize(find.text('Background')).height, greaterThan(0));
  });
}
