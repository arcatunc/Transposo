import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transposo/main.dart';

void main() {
  testWidgets('transposes typed notes from Piano (C) to Trumpet (Bb)',
      (tester) async {
    await tester.pumpWidget(const TransposoApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'C:1 D:1 E:1');

    // Defaults are source C and target Bb, so just transpose.
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('D:1 E:1 F#:1'), findsOneWidget);
  });

  testWidgets('shows a warning when input is empty', (tester) async {
    await tester.pumpWidget(const TransposoApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('swap button exchanges source and target instruments',
      (tester) async {
    await tester.pumpWidget(const TransposoApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.swap_vert));
    await tester.pumpAndSettle();

    // After the swap, Bb -> C transposes C down two semitones to Bb-.
    await tester.enterText(find.byType(TextField), 'C:1');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('Bb-:1'), findsOneWidget);
  });
}
