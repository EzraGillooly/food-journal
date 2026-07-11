import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_journal/features/entries/data/food_category.dart';
import 'package:food_journal/shared/category_tag.dart';
import 'package:food_journal/shared/made_bought_toggle.dart';
import 'package:food_journal/shared/rating_control.dart';

Widget _host(Widget child) => ProviderScope(
  child: MaterialApp(home: Scaffold(body: child)),
);

void main() {
  testWidgets('RatingControl reports the tapped value', (tester) async {
    int? picked;
    await tester.pumpWidget(
      _host(RatingControl(value: picked, onChanged: (v) => picked = v)),
    );
    await tester.tap(find.text('7'));
    expect(picked, 7);
  });

  testWidgets('RatingControl renders all ten chips', (tester) async {
    await tester.pumpWidget(_host(RatingControl(value: 5, onChanged: (_) {})));
    for (var n = 1; n <= 10; n++) {
      expect(find.text('$n'), findsOneWidget);
    }
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
