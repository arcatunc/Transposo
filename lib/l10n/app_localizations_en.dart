// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Transposo';

  @override
  String get appSubtitle => 'The ultimate transposing tool for musicians.';

  @override
  String get sourceInstrument => 'Source instrument';

  @override
  String get targetInstrument => 'Target instrument';

  @override
  String get instrumentC => 'Piano / Flute / Violin / Guitar (C)';

  @override
  String get instrumentBb => 'Trumpet / Clarinet / Soprano & Tenor Sax (Bb)';

  @override
  String get instrumentEb => 'Alto & Baritone Sax (Eb)';

  @override
  String get instrumentF => 'French Horn (F)';

  @override
  String get notesInputLabel => 'Notes';

  @override
  String get notesInputHint => 'e.g. C:1 D:0.5 A+:2';

  @override
  String get notesInputHelper =>
      'Format: Note:Beat — octave up A+:1, octave down A-:1';

  @override
  String get transposeButton => 'Transpose';

  @override
  String get resultLabel => 'Transposed notes';

  @override
  String get emptyInputWarning => 'Please enter some notes first.';

  @override
  String get noValidNotesWarning =>
      'No valid notes found — check the format (e.g. C:1 D:0.5).';

  @override
  String skippedTokensNotice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count invalid entries were skipped.',
      one: '1 invalid entry was skipped.',
    );
    return '$_temp0';
  }

  @override
  String get swapInstrumentsTooltip => 'Swap instruments';
}
