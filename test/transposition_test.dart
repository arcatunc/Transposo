import 'package:flutter_test/flutter_test.dart';
import 'package:transposo/core/instruments.dart';
import 'package:transposo/core/transposition.dart';

void main() {
  group('findNoteIndex', () {
    test('maps naturals, sharps and flats', () {
      expect(findNoteIndex('C'), 0);
      expect(findNoteIndex('F#'), 6);
      expect(findNoteIndex('Bb'), 10);
      expect(findNoteIndex('eb'), 3);
      expect(findNoteIndex(' G '), 7);
    });

    test('returns -1 for invalid names', () {
      expect(findNoteIndex('XYZ'), -1);
      expect(findNoteIndex('H'), -1);
      expect(findNoteIndex(''), -1);
    });
  });

  group('transposeSequence', () {
    test('roadmap scenario 1: Piano (C) to Trumpet (Bb)', () {
      final result = transposeSequence(
        'C:1 D:1 E:1',
        Instrument.c.semitoneOffset,
        Instrument.bFlat.semitoneOffset,
      );
      expect(result.map((n) => n.readable).join(' '), 'D:1 E:1 F#:1');
    });

    test('roadmap scenario 2: octave markers survive identity transposition',
        () {
      final result = transposeSequence(
        'A+:1 G-:2',
        Instrument.bFlat.semitoneOffset,
        Instrument.bFlat.semitoneOffset,
      );
      expect(result.map((n) => n.readable).join(' '), 'A+:1 G-:2');
    });

    test('roadmap scenario 3: malformed tokens are skipped without crashing',
        () {
      final result = transposeSequence('XYZ:9 C:1 H:2 D:abc', 0, 2);
      expect(result.map((n) => n.readable).join(' '), 'D:1');
    });

    test('octave carries up when crossing the B-C boundary', () {
      // A (9) + 4 semitones = C# in the next octave.
      final result = transposeSequence('A:1', 0, 4);
      expect(result.single.readable, 'C#+:1');
    });

    test('octave carries down when transposing below C', () {
      // C (0) - 2 semitones = Bb in the octave below.
      final result = transposeSequence('C:1', 2, 0);
      expect(result.single.readable, 'Bb-:1');
    });

    test('octave carry combines with an existing marker', () {
      // B (11) + 2 = 13 -> C# with +1 carry, so B+ becomes C#++.
      final result = transposeSequence('B+:1', 0, 2);
      expect(result.single.readable, 'C#++:1');
    });

    test('beats pass through, including fractions', () {
      final result = transposeSequence('C:0.5 D:2 E:0.25', 0, 0);
      expect(
        result.map((n) => n.readable).join(' '),
        'C:0.5 D:2 E:0.25',
      );
    });
  });

  group('TransposedNote.abc (Phase 2 groundwork)', () {
    test('formats beats as ABC durations', () {
      final result = transposeSequence('C:0.5 D:0.25 E:1 F:2', 0, 0);
      expect(result.map((n) => n.abc).toList(), ['C/2', 'D/4', 'E', 'F2']);
    });

    test('uses ABC accidentals and octave marks', () {
      final result = transposeSequence('C#:1 Eb+:1 A-:1', 0, 0);
      expect(result.map((n) => n.abc).toList(), ['^C', "_E'", 'A,']);
    });
  });
}
