import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_journal/features/entries/data/food_category.dart';
import 'package:food_journal/shared/category_tag.dart';
import 'package:food_journal/shared/made_bought_toggle.dart';
import 'package:food_journal/shared/rating_control.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _host(Widget child) => ProviderScope(
  child: MaterialApp(home: Scaffold(body: child)),
);

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('RatingControl half-star tap reports an odd value', (
    tester,
  ) async {
    int? picked;
    await tester.pumpWidget(
      _host(RatingControl(value: null, onChanged: (v) => picked = v)),
    );
    // Right (full) zone of the 4th star = 8/10.
    await tester.tap(find.byKey(const ValueKey('rate-8')));
    expect(picked, 8);
    // Left (half) zone of the 4th star = 7/10.
    await tester.tap(find.byKey(const ValueKey('rate-7')));
    expect(picked, 7);
  });

  testWidgets('RatingControl renders five stars', (tester) async {
    await tester.pumpWidget(_host(RatingControl(value: 9, onChanged: (_) {})));
    // 9/10 = four full stars + one half star.
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(4));
    expect(find.byIcon(Icons.star_half_rounded), findsOneWidget);
  });

  testWidgets('MadeBoughtToggle flips selection', (tester) async {
    bool? homemade;
    await tester.pumpWidget(
      _host(MadeBoughtToggle(isHomemade: true, onChanged: (v) => homemade = v)),
    );
    await tester.tap(find.text('Bought it'));
    expect(homemade, false);
  });

  testWidgets('CategoryTag shows the category label', (tester) async {
    await tester.pumpWidget(
      _host(const CategoryTag(category: FoodCategory.dinner)),
    );
    expect(find.text('Dinner'), findsOneWidget);
  });

  test('FoodCategory wire values round-trip', () {
    for (final c in FoodCategory.values) {
      expect(FoodCategory.fromWire(c.wire), c);
    }
  });
}
