# Transposo

**Transposo: Sheet Music Transposer**

The ultimate transposing tool for musicians.

## 1. About the Project

Transposo is a mobile application built with Flutter that rewrites sheet music from one instrument's key to another in seconds. A musician enters a sequence of notes (or scans a photo of a sheet), selects the source and target instruments, and Transposo produces the transposed note sequence together with a rendered musical staff.

### 1.1. Core Purpose

Many band instruments are transposing instruments: the written note they read is not the concert pitch they produce. A piece written for Piano (in C) must be rewritten before a Trumpet (in B flat) or an Alto Saxophone (in E flat) can play it. Doing this by hand is slow and error prone. Transposo automates the entire pipeline: parsing, semitone arithmetic with correct octave handling, measure partitioning, and visual staff rendering.

### 1.2. Key Features

1. **Transposition engine.** A pure Dart engine converts note sequences between instrument keys, correctly carrying the octave marker when a transposition crosses the B to C boundary.
2. **Supported instruments.** Instruments are grouped by key: C (Piano, Flute, Violin, Guitar), B flat (Trumpet, Clarinet, Soprano and Tenor Sax), E flat (Alto and Baritone Sax), and F (French Horn).
3. **Sheet music rendering.** The result is partitioned into 4/4 measures and drawn as a real musical staff using the ABCJS library inside a webview. ABCJS is bundled locally, so rendering works fully offline. Consecutive eighth and sixteenth notes are beamed together as in standard notation.
4. **AI photo scanning.** A photo of sheet music, taken with the camera or picked from the gallery, is sent to the Google Gemini Vision API, which extracts the notes and places them in the input field for review before transposing.
5. **Persistence and history.** The active workspace (input text and instrument selections) survives app restarts, and the last 50 conversions are kept in a history list that can restore any past conversion with one tap.
6. **Live re-rendering.** Editing the note input re-transposes and redraws the staff in real time with a short debounce, without pressing the button again.
7. **Modern UI.** Material 3 design, automatic dark and light themes following the system setting, and full English and Turkish localization.

### 1.3. Note Input Format

Notes are entered as space separated tokens in the form `Note[:Beat]`.

1. **Note names:** `C C# Db D D# Eb E F F# Gb G G# Ab A A# Bb B` (enharmonic spellings such as `B#` or `Cb` are also accepted).
2. **Octave markers:** append `+` for one octave up or `-` for one octave down, relative to the middle octave starting at C4. Markers are stackable, for example `C#++`.
3. **Beat:** the duration in quarter note beats (`4` whole, `2` half, `1` quarter, `0.5` eighth, `0.25` sixteenth). When omitted, the beat defaults to `1`.
4. **Error handling:** malformed tokens are skipped silently and a notice shows how many were ignored.

Example input:

```text
C:1 D:1 E:1 F#:0.5 G+:2 A-:1
```

## 2. Requirements

The following tools must be installed on the system before building or running the project.

1. **Flutter SDK.** A recent stable release with Dart included. Verify with `flutter doctor`.
2. **Android Studio and the Android SDK.** Required to build and run the Android app, including platform tools and an emulator or a physical device with USB debugging enabled.
3. **Git.** Needed to clone the repository.
4. **A Google Gemini API key.** Required only for the photo scanning feature. A free tier key can be created in Google AI Studio. The rest of the app works without it.
5. **Xcode on macOS (optional).** The iOS scaffold exists but has not been tested; building for iOS requires a Mac with Xcode.

**Note on platforms:** the project targets Android first. Desktop and web are not supported targets; on platforms without a webview implementation the sheet view falls back to showing the raw ABC text.

## 3. Installation

Follow these steps to set up and run the project.

1. Clone the repository and enter the project directory:

```bash
git clone https://github.com/arcatunc/Transposo.git
cd Transposo
```

2. Fetch the dependencies:

```bash
flutter pub get
```

3. Generate the localization classes (also runs automatically during a normal build because `generate: true` is set in `pubspec.yaml`):

```bash
flutter gen-l10n
```

4. Run the app on a connected Android device or emulator, passing your Gemini API key as a compile time variable:

```bash
flutter run --dart-define=GEMINI_API_KEY=your_key_here
```

5. To build a release APK:

```bash
flutter build apk --dart-define=GEMINI_API_KEY=your_key_here
```

**API key security:** the key is never hardcoded in the source. It is injected at compile time through the `dart-define` mechanism and is sent to Google in an HTTP header rather than in the URL, so it does not appear in logs. If the key is omitted, the app runs normally and the photo scan feature shows a localized error explaining that the key is missing.

## 4. Running the Tests

The project has a full test suite covering the engine, the measure partitioner, the Gemini service, storage, and the widget flows. Run everything with:

```bash
flutter test
```

Static analysis should also pass cleanly:

```bash
flutter analyze
```

## 5. Project Structure

1. `lib/main.dart` contains the app entry point with Material 3 themes and localization setup.
2. `lib/core/` holds the pure Dart business logic with no Flutter imports, which makes it fully unit testable. It contains `transposition.dart` (the transposition engine), `instruments.dart` (the instrument enum with semitone offsets), and `measure_partitioner.dart` (bar line insertion and ABC document building).
3. `lib/services/` contains `gemini_config.dart` (every Gemini constant in one file, including the model name `gemini-flash-latest` and the extraction prompt), `gemini_vision_service.dart` (the REST client with typed exceptions), and `app_storage.dart` (workspace and history persistence over `shared_preferences`).
4. `lib/screens/home_screen.dart` is the single page UI: photo scan section, instrument dropdowns with a swap button, the note input, the result card, the sheet music card, and the history bottom sheet. Services are constructor injectable for testing.
5. `lib/widgets/sheet_music_view.dart` wraps the webview, splices the ABCJS source inline into the HTML template, and pushes ABC strings into the page through JavaScript.
6. `lib/l10n/` holds the English and Turkish ARB files; the `app_localizations` Dart files are generated and must never be edited by hand.
7. `assets/` bundles `abcjs_template.html` (the webview page with a pinch to zoom viewport) and `abcjs-basic-min.js` (ABCJS v6.4.4, kept local for offline rendering).
8. `test/` contains the unit and widget tests, one file per subsystem.
9. `PROJECT_ROADMAP.md` records the original project plan, phases, and test scenarios; `DEVELOPMENT_LOG.md` records the rules, agreed decisions, and per phase progress.

**Data flow:** the home screen reads the input text, calls `transposeSequence` with the source and target semitone offsets, shows the resulting readable tokens in the result card, and in parallel builds an ABC document that the webview renders as a staff.

## 6. Troubleshooting

1. **The sheet card is blank or white on Android.** The template and the ABCJS source are loaded as a single self contained HTML string, and the page waits until the webview has a real width before drawing, so this should not occur on current builds. If it does, JavaScript errors are forwarded to Dart through the `SheetBridge` channel and printed with `debugPrint`; check the logs with `flutter logs`.
2. **Photo scan fails with an HTTP 404 model error.** Google occasionally retires pinned Gemini model versions. The app uses the `gemini-flash-latest` alias, which always tracks the newest Flash model. If Google changes the alias scheme, update the single `model` constant in `lib/services/gemini_config.dart`.
3. **Photo scan reports a missing key.** The app was built without the `GEMINI_API_KEY` compile time variable. Rebuild with the flag shown in the installation section.
4. **Photo scan fails while offline.** Network failures surface as a localized snackbar instead of a crash. Restore connectivity and try again.
5. **Localization strings are missing after editing an ARB file.** Run `flutter gen-l10n` again, or perform a full `flutter run`, which regenerates them automatically.
6. **Widget tests fail with storage errors.** Tests that pump the home screen must call `SharedPreferences.setMockInitialValues({})` in `setUp`, because the screen touches storage during initialization.

## 7. Notes for Developers

1. **Reference implementation.** The transposition arithmetic is a Dart port of the original Python project at `https://github.com/arcatunc/Transposer.git`, with one deliberate improvement: transpositions crossing the B to C boundary carry the octave marker instead of wrapping silently.
2. **Gemini integration decision.** The app calls the Gemini REST API directly with the `http` package instead of the deprecated `google_generative_ai` package. All Gemini constants live in one file so the model or endpoint can be swapped in a single place.
3. **Persistence decision.** `shared_preferences` was chosen over Hive because the data is simple key value pairs plus one JSON list, and it requires no code generation. History stores only the input notes; the transposed output is recomputed on restore so records never go stale if the engine changes.
4. **Testing conventions.** The vision service, the image picker, and the storage layer are all injectable through the `HomeScreen` constructor, so widget tests run without platform plugins or network access.
5. **Commit policy.** Commit messages are written per phase or hotfix, and the log in `DEVELOPMENT_LOG.md` is updated at the end of every phase.
