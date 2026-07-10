import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Transposo'**
  String get appTitle;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The ultimate transposing tool for musicians.'**
  String get appSubtitle;

  /// No description provided for @sourceInstrument.
  ///
  /// In en, this message translates to:
  /// **'Source instrument'**
  String get sourceInstrument;

  /// No description provided for @targetInstrument.
  ///
  /// In en, this message translates to:
  /// **'Target instrument'**
  String get targetInstrument;

  /// No description provided for @instrumentC.
  ///
  /// In en, this message translates to:
  /// **'Piano / Flute / Violin / Guitar (C)'**
  String get instrumentC;

  /// No description provided for @instrumentBb.
  ///
  /// In en, this message translates to:
  /// **'Trumpet / Clarinet / Soprano & Tenor Sax (Bb)'**
  String get instrumentBb;

  /// No description provided for @instrumentEb.
  ///
  /// In en, this message translates to:
  /// **'Alto & Baritone Sax (Eb)'**
  String get instrumentEb;

  /// No description provided for @instrumentF.
  ///
  /// In en, this message translates to:
  /// **'French Horn (F)'**
  String get instrumentF;

  /// No description provided for @notesInputLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesInputLabel;

  /// No description provided for @notesInputHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. C:1 D:0.5 A+:2'**
  String get notesInputHint;

  /// No description provided for @notesInputHelper.
  ///
  /// In en, this message translates to:
  /// **'Format: Note:Beat — octave up A+:1, octave down A-:1'**
  String get notesInputHelper;

  /// No description provided for @transposeButton.
  ///
  /// In en, this message translates to:
  /// **'Transpose'**
  String get transposeButton;

  /// No description provided for @resultLabel.
  ///
  /// In en, this message translates to:
  /// **'Transposed notes'**
  String get resultLabel;

  /// No description provided for @emptyInputWarning.
  ///
  /// In en, this message translates to:
  /// **'Please enter some notes first.'**
  String get emptyInputWarning;

  /// No description provided for @noValidNotesWarning.
  ///
  /// In en, this message translates to:
  /// **'No valid notes found — check the format (e.g. C:1 D:0.5).'**
  String get noValidNotesWarning;

  /// No description provided for @skippedTokensNotice.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 invalid entry was skipped.} other{{count} invalid entries were skipped.}}'**
  String skippedTokensNotice(int count);

  /// No description provided for @swapInstrumentsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Swap instruments'**
  String get swapInstrumentsTooltip;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
