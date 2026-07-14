import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transposo/main.dart';

/// Phase 4 roadmap scenarios: lifecycle state survival, log record reversals,
/// and live edit syncing.
void main() {
  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.dragUntilVisible(
      finder,
      find.byType(ListView).first,
      const Offset(0, -100),
    );
  }

  String fieldText(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).controller!.text;

  testWidgets('restores workspace state saved by a previous run',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'workspace.input': 'C:1 D:0.5',
      'workspace.source': 'eFlat',
      'workspace.target': 'f',
    });

    await tester.pumpWidget(const TransposoApp());
    await tester.pumpAndSettle();

    expect(fieldText(tester), 'C:1 D:0.5');
    expect(find.text('Alto & Baritone Sax (Eb)'), findsOneWidget);
    expect(find.text('French Horn (F)'), findsOneWidget);
  });

  testWidgets('transposing saves the workspace and adds a history record',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const TransposoApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'C:1 D:1');
    await scrollTo(tester, find.byType(FilledButton));
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('workspace.input'), 'C:1 D:1');
    expect(prefs.getString('workspace.source'), 'c');
    expect(prefs.getString('workspace.target'), 'bFlat');

    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(ListTile),
        matching: find.text('C:1 D:1'),
      ),
      findsOneWidget,
    );

    // Clearing empties the list and shows the placeholder.
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNothing);
    expect(find.text('No conversions yet.'), findsOneWidget);
    expect(prefs.getString('history'), isNull);
  });

  testWidgets('tapping a history record restores fields and shows its result',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'history': jsonEncode([
        {
          'timestamp': '2026-07-14T10:30:00.000',
          'source': 'c',
          'target': 'bFlat',
          'notes': 'G:1 A:1',
        },
      ]),
    });

    await tester.pumpWidget(const TransposoApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();

    await tester.tap(find.descendant(
      of: find.byType(ListTile),
      matching: find.text('G:1 A:1'),
    ));
    await tester.pumpAndSettle();

    expect(fieldText(tester), 'G:1 A:1');
    await scrollTo(tester, find.text('A:1 B:1'));
    expect(find.text('A:1 B:1'), findsOneWidget);
  });

  testWidgets('editing the input live-updates the result and sheet',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const TransposoApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'C:1');
    await scrollTo(tester, find.byType(FilledButton));
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text('D:1'));
    expect(find.text('D:1'), findsOneWidget);

    // Edit the input without pressing the transpose button; after the
    // debounce the result and the ABC document must follow.
    await tester.enterText(find.byType(TextField), 'E:1');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('D:1'), findsNothing);
    await scrollTo(tester, find.text('F#:1'));
    expect(find.text('F#:1'), findsOneWidget);
    // The sheet fallback text (no webview in tests) carries the new note too.
    expect(find.textContaining('^F'), findsOneWidget);
  });
}
