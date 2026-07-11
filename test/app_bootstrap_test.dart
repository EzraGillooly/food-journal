import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_journal/app.dart';
import 'package:food_journal/core/theme/app_theme.dart';
import 'package:food_journal/core/theme/theme_provider.dart';

void main() {
  testWidgets('app boots to the placeholder home with Soft Blush theme', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: FoodJournalApp()));
    await tester.pumpAndSettle();

    expect(find.text('Food Journal'), findsOneWidget);
    expect(find.textContaining('Soft Blush'), findsOneWidget);
  });

  test('default theme preset is Soft Blush', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(
      container.read(themeControllerProvider).preset,
      AppThemePreset.softBlush,
    );
  });
}
