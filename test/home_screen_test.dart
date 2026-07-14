import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transposo/main.dart';
import 'package:transposo/widgets/sheet_music_view.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('transposes typed notes from Piano (C) to Trumpet (Bb)',
      (tester) async {
    await tester.pumpWidget(const TransposoApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'C:1 D:1 E:1');

    // Defaults are source C and target Bb, so just transpose. The button can
    // sit below the fold now that the scan section is above it, so scroll it
    // into view first.
    await tester.dragUntilVisible(
      find.byType(FilledButton),
      find.byType(ListView),
      const Offset(0, -100),
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    // The result card is below the fold of the lazy ListView, so scroll it
    // into view before asserting on it.
    await tester.dragUntilVisible(
      find.text('D:1 E:1 F#:1'),
      find.byType(ListView),
      const Offset(0, -100),
    );
    expect(find.text('D:1 E:1 F#:1'), findsOneWidget);

    // The sheet card appears with the partitioned ABC document (rendered as
    // fallback text in tests, where no webview platform exists). It sits
    // below the fold of the lazy ListView, so scroll it into view first.
    await tester.dragUntilVisible(
      find.byType(SheetMusicView),
      find.byType(ListView),
      const Offset(0, -100),
    );
    expect(find.byType(SheetMusicView), findsOneWidget);
    expect(find.textContaining('D E ^F'), findsOneWidget);
  });

  testWidgets('shows a warning when input is empty', (tester) async {
    await tester.pumpWidget(const TransposoApp());
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.byType(FilledButton),
      find.byType(ListView),
      const Offset(0, -100),
    );
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
    await tester.dragUntilVisible(
      find.byType(FilledButton),
      find.byType(ListView),
      const Offset(0, -100),
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('Bb-:1'),
      find.byType(ListView),
      const Offset(0, -100),
    );
    expect(find.text('Bb-:1'), findsOneWidget);
  });
}
