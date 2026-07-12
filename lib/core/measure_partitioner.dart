/// Partitions transposed notes into 4/4 measures and builds the ABC
/// notation document consumed by the sheet renderer (Phase 2).
library;

import 'transposition.dart';

/// Tolerance for accumulated floating-point beat sums (0.25 + 0.25 + ...).
const double _epsilon = 1e-9;

/// Joins the notes' ABC tokens, inserting a bar line (`|`) every
/// [beatsPerMeasure] cumulative beats and a line break every
/// [measuresPerLine] measures.
///
/// Example: `C:2 D:2 E:1 F:1 G:2` becomes `C2 D2 | E F G2`.
String partitionIntoMeasures(
  List<TransposedNote> notes, {
  double beatsPerMeasure = 4.0,
  int measuresPerLine = 4,
}) {
  final lines = <String>[];
  final measuresInLine = <String>[];
  final currentMeasure = <String>[];
  var beats = 0.0;

  void flushMeasure() {
    if (currentMeasure.isEmpty) return;
    measuresInLine.add(currentMeasure.join(' '));
    currentMeasure.clear();
    if (measuresInLine.length == measuresPerLine) {
      lines.add(measuresInLine.join(' | '));
      measuresInLine.clear();
    }
  }

  for (final note in notes) {
    if (beats >= beatsPerMeasure - _epsilon) {
      // A note longer than a full measure spills over; keep bars aligned by
      // dropping whole measures' worth of beats before starting the next bar.
      while (beats >= beatsPerMeasure - _epsilon) {
        beats -= beatsPerMeasure;
      }
      flushMeasure();
    }
    currentMeasure.add(note.abc);
    beats += note.beat;
  }
  flushMeasure();
  if (measuresInLine.isNotEmpty) {
    lines.add(measuresInLine.join(' | '));
  }

  return lines.join(' |\n');
}

/// Wraps the partitioned body in a minimal ABC tune header (4/4 time,
/// quarter-note unit length to match `beat == 1`).
String buildAbcDocument(List<TransposedNote> notes) {
  final body = partitionIntoMeasures(notes);
  return 'X:1\nM:4/4\nL:1/4\nK:C\n$body';
}
