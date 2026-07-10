/// Pure-Dart port of the Transposer engine (find_note_index / transposer),
/// extended to carry the octave across the B→C boundary when transposing.
library;

/// Chromatic scale spelled the way musicians read it (matches the original
/// project's readable output: sharps for C/F, flats for E/A/B).
const List<String> readableNotes = [
  'C', 'C#', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'Ab', 'A', 'Bb', 'B',
];

/// The same scale in ABC notation, used by the sheet renderer (Phase 2).
const List<String> abcNotes = [
  'C', '^C', 'D', '_E', 'E', 'F', '^F', 'G', '_A', 'A', '_B', 'B',
];

const Map<String, int> _noteMap = {
  'C': 0, 'B#': 0, 'C#': 1, 'DB': 1, 'D': 2, 'D#': 3, 'EB': 3,
  'E': 4, 'FB': 4, 'F': 5, 'E#': 5, 'F#': 6, 'GB': 6, 'G': 7,
  'G#': 8, 'AB': 8, 'A': 9, 'A#': 10, 'BB': 10, 'B': 11, 'CB': 11,
};

/// Returns the chromatic index (0–11) of a note name like `C`, `F#`, `Bb`,
/// or -1 if the name is not a valid note.
int findNoteIndex(String note) => _noteMap[note.toUpperCase().trim()] ?? -1;

/// One successfully transposed note.
class TransposedNote {
  const TransposedNote({
    required this.noteIndex,
    required this.octave,
    required this.beat,
  });

  /// Chromatic index 0–11 after transposition.
  final int noteIndex;

  /// Net octave shift relative to the middle octave (`+` markers minus `-`
  /// markers, plus any carry from crossing the B→C boundary).
  final int octave;

  /// Beat duration as entered (e.g. 1, 0.5, 2).
  final double beat;

  /// The note in input notation, e.g. `F#+:0.5`.
  String get readable {
    final marker = octave >= 0 ? '+' * octave : '-' * (-octave);
    return '${readableNotes[noteIndex]}$marker:${_formatBeat(beat)}';
  }

  /// The note in ABC notation, e.g. `^F'/2` (uppercase = middle octave,
  /// `'` up an octave, `,` down an octave).
  String get abc {
    final marker = octave >= 0 ? "'" * octave : ',' * (-octave);
    final duration = switch (beat) {
      0.5 => '/2',
      0.25 => '/4',
      1 => '',
      _ => _formatBeat(beat),
    };
    return '${abcNotes[noteIndex]}$marker$duration';
  }

  static String _formatBeat(double beat) =>
      beat == beat.roundToDouble() ? beat.round().toString() : beat.toString();
}

/// Transposes a single `Note[+/-]:Beat` token by `targetValue - sourceValue`
/// semitones. Returns null for tokens whose note name is invalid, so callers
/// can skip them safely.
TransposedNote? transposeToken(String token, int sourceValue, int targetValue) {
  final parts = token.split(':');
  var notePart = parts[0].trim();

  var octave = 0;
  while (notePart.endsWith('+') || notePart.endsWith('-')) {
    octave += notePart.endsWith('+') ? 1 : -1;
    notePart = notePart.substring(0, notePart.length - 1);
  }

  final index = findNoteIndex(notePart);
  if (index == -1) return null;

  final beat = parts.length > 1 ? double.tryParse(parts[1].trim()) : 1.0;
  if (beat == null || beat <= 0) return null;

  final raw = index + (targetValue - sourceValue);
  // Euclidean division so negative raw indexes wrap down an octave.
  final newIndex = ((raw % 12) + 12) % 12;
  final octaveCarry = ((raw - newIndex) / 12).round();

  return TransposedNote(
    noteIndex: newIndex,
    octave: octave + octaveCarry,
    beat: beat,
  );
}

/// Transposes a whitespace-separated sequence of tokens, silently skipping
/// malformed ones.
List<TransposedNote> transposeSequence(
  String input,
  int sourceValue,
  int targetValue,
) {
  return input
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .map((t) => transposeToken(t, sourceValue, targetValue))
      .whereType<TransposedNote>()
      .toList();
}
