// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Transposo';

  @override
  String get appSubtitle =>
      'Nota kağıtlarını saniyeler içinde enstrümanına uyarla.';

  @override
  String get sourceInstrument => 'Kaynak enstrüman';

  @override
  String get targetInstrument => 'Hedef enstrüman';

  @override
  String get instrumentC => 'Piyano / Flüt / Keman / Gitar (Do)';

  @override
  String get instrumentBb =>
      'Trompet / Klarnet / Soprano ve Tenor Saksafon (Si♭)';

  @override
  String get instrumentEb => 'Alto ve Bariton Saksafon (Mi♭)';

  @override
  String get instrumentF => 'Korno (Fa)';

  @override
  String get notesInputLabel => 'Notalar';

  @override
  String get notesInputHint => 'örn. C:1 D:0.5 A+:2';

  @override
  String get notesInputHelper =>
      'Biçim: Nota:Vuruş — üst oktav A+:1, alt oktav A-:1';

  @override
  String get transposeButton => 'Dönüştür';

  @override
  String get resultLabel => 'Dönüştürülen notalar';

  @override
  String get emptyInputWarning => 'Lütfen önce nota girin.';

  @override
  String get noValidNotesWarning =>
      'Geçerli nota bulunamadı — biçimi kontrol edin (örn. C:1 D:0.5).';

  @override
  String skippedTokensNotice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count geçersiz giriş atlandı.',
      one: '1 geçersiz giriş atlandı.',
    );
    return '$_temp0';
  }

  @override
  String get swapInstrumentsTooltip => 'Enstrümanları değiştir';

  @override
  String get sheetLabel => 'Nota görünümü';
}
