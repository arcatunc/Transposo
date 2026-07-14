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

  @override
  String get scanSectionTitle => 'Fotoğraftan nota oku';

  @override
  String get scanFromCamera => 'Kamera';

  @override
  String get scanFromGallery => 'Galeri';

  @override
  String get aiReadingIndicator => 'Görüntüdeki notalar okunuyor...';

  @override
  String get aiReadSuccess =>
      'Notalar görüntüden okundu. Kontrol edip dönüştürebilirsiniz.';

  @override
  String get aiNetworkError =>
      'İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edip tekrar deneyin.';

  @override
  String get aiMissingKeyError =>
      'Bu sürümde Gemini API anahtarı tanımlı değil.';

  @override
  String get aiNoNotesError => 'Bu görüntüde okunabilir nota bulunamadı.';

  @override
  String get aiGenericError =>
      'Yapay zeka servisi görüntüyü işleyemedi. Lütfen tekrar deneyin.';

  @override
  String get imagePickError => 'Görüntü yüklenemedi.';

  @override
  String get historyTooltip => 'Dönüşüm geçmişi';

  @override
  String get historyTitle => 'Geçmiş';

  @override
  String get historyEmpty => 'Henüz dönüşüm yok.';

  @override
  String get historyClear => 'Temizle';

  @override
  String get instrumentShortC => 'Do';

  @override
  String get instrumentShortBb => 'Si♭';

  @override
  String get instrumentShortEb => 'Mi♭';

  @override
  String get instrumentShortF => 'Fa';
}
