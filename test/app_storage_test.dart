import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transposo/core/instruments.dart';
import 'package:transposo/services/app_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('workspace persistence', () {
    test('returns null before anything was saved', () async {
      final storage = AppStorage();
      expect(await storage.loadWorkspace(), isNull);
    });

    test('round-trips input text and instruments', () async {
      final storage = AppStorage();
      await storage.saveWorkspace(
        input: 'C:1 D:0.5 A+:2',
        source: Instrument.eFlat,
        target: Instrument.f,
      );

      final workspace = await storage.loadWorkspace();
      expect(workspace, isNotNull);
      expect(workspace!.input, 'C:1 D:0.5 A+:2');
      expect(workspace.source, Instrument.eFlat);
      expect(workspace.target, Instrument.f);
    });

    test('returns null when a stored instrument name is unknown', () async {
      SharedPreferences.setMockInitialValues({
        'workspace.input': 'C:1',
        'workspace.source': 'theremin',
        'workspace.target': 'c',
      });
      final storage = AppStorage();
      expect(await storage.loadWorkspace(), isNull);
    });
  });

  group('conversion history', () {
    ConversionRecord record(String notes) => ConversionRecord(
          timestamp: DateTime(2026, 7, 14, 12),
          source: Instrument.c,
          target: Instrument.bFlat,
          notes: notes,
        );

    test('starts empty', () async {
      expect(await AppStorage().loadHistory(), isEmpty);
    });

    test('adds records newest first and round-trips them', () async {
      final storage = AppStorage();
      await storage.addHistoryRecord(record('C:1'));
      final returned = await storage.addHistoryRecord(record('D:1'));

      expect(returned.map((r) => r.notes), ['D:1', 'C:1']);

      final reloaded = await storage.loadHistory();
      expect(reloaded.map((r) => r.notes), ['D:1', 'C:1']);
      expect(reloaded.first.timestamp, DateTime(2026, 7, 14, 12));
      expect(reloaded.first.source, Instrument.c);
      expect(reloaded.first.target, Instrument.bFlat);
    });

    test('caps the history at historyLimit records', () async {
      final storage = AppStorage(historyLimit: 3);
      for (var i = 1; i <= 5; i++) {
        await storage.addHistoryRecord(record('N:$i'));
      }

      final history = await storage.loadHistory();
      expect(history.map((r) => r.notes), ['N:5', 'N:4', 'N:3']);
    });

    test('treats corrupted stored history as empty', () async {
      SharedPreferences.setMockInitialValues({'history': 'not json ['});
      expect(await AppStorage().loadHistory(), isEmpty);
    });

    test('clearHistory removes every record', () async {
      final storage = AppStorage();
      await storage.addHistoryRecord(record('C:1'));
      await storage.clearHistory();
      expect(await storage.loadHistory(), isEmpty);
    });
  });
}
