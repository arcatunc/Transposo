import 'package:flutter_test/flutter_test.dart';
import 'package:transposo/core/measure_partitioner.dart';
import 'package:transposo/core/transposition.dart';

List<TransposedNote> notesOf(String input) => transposeSequence(input, 0, 0);

void main() {
  group('partitionIntoMeasures', () {
    test('roadmap scenario 1: bar line inserted every 4.0 beats', () {
      final result = partitionIntoMeasures(notesOf('C:2 D:2 E:1 F:1 G:2'));
      expect(result, 'C2 D2 | E F G2');
    });

    test('roadmap scenario 2: fractional beats map to ABC /2 and /4', () {
      final result = partitionIntoMeasures(
        notesOf('C:0.5 D:0.5 E:0.25 F:0.25 G:0.5 A:2'),
      );
      expect(result, 'C/2D/2E/4F/4G/2 A2');
    });

    test('accumulated fractions still close the bar at exactly 4 beats', () {
      // 8 x 0.5 = 4.0 beats, then one more note starts measure two.
      final result = partitionIntoMeasures(
        notesOf('C:0.5 C:0.5 C:0.5 C:0.5 C:0.5 C:0.5 C:0.5 C:0.5 D:1'),
      );
      expect(result, 'C/2C/2C/2C/2C/2C/2C/2C/2 | D');
    });

    test('smart beaming: sub-beat neighbours join, longer notes break beams',
        () {
      // Eighths around a quarter note: the quarter keeps spaces on both
      // sides, the eighth pairs are glued so ABCJS beams them.
      final result = partitionIntoMeasures(
        notesOf('C:0.5 D:0.5 E:1 F:0.5 G:0.5 A:1'),
      );
      expect(result, 'C/2D/2 E F/2G/2 A');
    });

    test('smart beaming does not join across a bar line', () {
      // Four eighths finish measure one; the following eighths start
      // measure two after the bar, not beamed to the previous group.
      final result = partitionIntoMeasures(
        notesOf('C:1 D:1 E:1 F:0.5 G:0.5 A:0.5 B:0.5 C:3'),
      );
      expect(result, 'C D E F/2G/2 | A/2B/2 C3');
    });

    test('line break appended after every 4 measures', () {
      // 20 quarter notes = 5 full measures: 4 on line one, 1 on line two.
      final input = List.filled(20, 'C:1').join(' ');
      final result = partitionIntoMeasures(notesOf(input));
      expect(
        result,
        'C C C C | C C C C | C C C C | C C C C |\nC C C C',
      );
    });

    test('a note longer than a measure spills without emitting empty bars',
        () {
      // Bars fall at absolute beats 4 and 8: the C spills across the first
      // boundary, D completes the carried measure, E fills the third.
      final result = partitionIntoMeasures(notesOf('C:6 D:2 E:4'));
      expect(result, 'C6 | D2 | E4');
    });

    test('empty input produces an empty body', () {
      expect(partitionIntoMeasures(const []), '');
    });
  });

  group('buildAbcDocument', () {
    test('wraps the body in a 4/4 header with quarter-note unit length', () {
      final doc = buildAbcDocument(notesOf('C:2 D:2 E:1 F:1 G:2'));
      expect(doc, 'X:1\nM:4/4\nL:1/4\nK:C\nC2 D2 | E F G2');
    });
  });
}
