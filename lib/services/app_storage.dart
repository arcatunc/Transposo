/// Local persistence for Phase 4: the active workspace (input text and
/// instrument selection) and the conversion history, both stored in
/// `shared_preferences` so they survive app restarts.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/instruments.dart';

/// One past conversion shown in the history list. Stores the input notes;
/// the transposed output is recomputed on restore, so it never goes stale
/// if the engine changes.
class ConversionRecord {
  const ConversionRecord({
    required this.timestamp,
    required this.source,
    required this.target,
    required this.notes,
  });

  final DateTime timestamp;
  final Instrument source;
  final Instrument target;
  final String notes;

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'source': source.name,
        'target': target.name,
        'notes': notes,
      };

  /// Returns null when the stored entry cannot be parsed (corrupted value or
  /// an instrument name from a newer app version), so callers can skip it.
  static ConversionRecord? fromJson(Map<String, dynamic> json) {
    final timestamp = DateTime.tryParse(json['timestamp'] as String? ?? '');
    final source = Instrument.values.asNameMap()[json['source']];
    final target = Instrument.values.asNameMap()[json['target']];
    final notes = json['notes'] as String?;
    if (timestamp == null || source == null || target == null || notes == null) {
      return null;
    }
    return ConversionRecord(
      timestamp: timestamp,
      source: source,
      target: target,
      notes: notes,
    );
  }
}

/// The persisted form state restored on app launch.
class Workspace {
  const Workspace({
    required this.input,
    required this.source,
    required this.target,
  });

  final String input;
  final Instrument source;
  final Instrument target;
}

/// Thin wrapper over [SharedPreferences]. All methods are safe to call at any
/// time; `SharedPreferences.getInstance()` caches after the first read.
class AppStorage {
  AppStorage({this.historyLimit = 50});

  /// Oldest records beyond this count are dropped when a new one is added.
  final int historyLimit;

  static const _inputKey = 'workspace.input';
  static const _sourceKey = 'workspace.source';
  static const _targetKey = 'workspace.target';
  static const _historyKey = 'history';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<void> saveWorkspace({
    required String input,
    required Instrument source,
    required Instrument target,
  }) async {
    final prefs = await _prefs;
    await prefs.setString(_inputKey, input);
    await prefs.setString(_sourceKey, source.name);
    await prefs.setString(_targetKey, target.name);
  }

  /// Returns null when nothing was saved yet (first launch).
  Future<Workspace?> loadWorkspace() async {
    final prefs = await _prefs;
    final input = prefs.getString(_inputKey);
    final source = Instrument.values.asNameMap()[prefs.getString(_sourceKey)];
    final target = Instrument.values.asNameMap()[prefs.getString(_targetKey)];
    if (input == null || source == null || target == null) return null;
    return Workspace(input: input, source: source, target: target);
  }

  Future<List<ConversionRecord>> loadHistory() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_historyKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(ConversionRecord.fromJson)
          .whereType<ConversionRecord>()
          .toList();
    } on FormatException {
      return [];
    }
  }

  /// Prepends [record] (newest first), trims to [historyLimit], persists, and
  /// returns the updated list for the UI.
  Future<List<ConversionRecord>> addHistoryRecord(
    ConversionRecord record,
  ) async {
    final history = await loadHistory();
    history.insert(0, record);
    if (history.length > historyLimit) {
      history.removeRange(historyLimit, history.length);
    }
    final prefs = await _prefs;
    await prefs.setString(
      _historyKey,
      jsonEncode([for (final r in history) r.toJson()]),
    );
    return history;
  }

  Future<void> clearHistory() async {
    final prefs = await _prefs;
    await prefs.remove(_historyKey);
  }
}
