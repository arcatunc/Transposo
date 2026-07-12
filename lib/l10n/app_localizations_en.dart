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

  @override
  String get sheetLabel => 'Sheet music';

  @override
  String get scanSectionTitle => 'Read notes from a photo';

  @override
  String get scanFromCamera => 'Camera';

  @override
  String get scanFromGallery => 'Gallery';

  @override
  String get aiReadingIndicator => 'Reading notes from the image...';

  @override
  String get aiReadSuccess =>
      'Notes read from the image. Review them, then transpose.';

  @override
  String get aiNetworkError =>
      'No internet connection. Please check your network and try again.';

  @override
  String get aiMissingKeyError =>
      'Gemini API key is not configured for this build.';

  @override
  String get aiNoNotesError => 'No readable notes were found in this image.';

  @override
  String get aiGenericError =>
      'The AI service could not process the image. Please try again.';

  @override
  String get imagePickError => 'The image could not be loaded.';
}
