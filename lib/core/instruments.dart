/// The transposing instruments supported by Transposo.
///
/// [semitoneOffset] is the number of semitones added to a written note when
/// converting from this instrument's written pitch, matching the original
/// Transposer project (C=0, Bb=2, Eb=9, F=7).
enum Instrument {
  c(0),
  bFlat(2),
  eFlat(9),
  f(7);

  const Instrument(this.semitoneOffset);

  final int semitoneOffset;
}
