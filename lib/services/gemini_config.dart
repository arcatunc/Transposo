/// Central place for every Gemini related constant so the model or endpoint
/// can be swapped without touching the service code.
library;

class GeminiConfig {
  GeminiConfig._();

  /// Model name. Kept here so it is easy to swap when Google rotates models.
  static const String model = 'gemini-flash-latest';

  /// Base URL of the Generative Language REST API.
  static const String baseUrl =
      'https://generativelanguage.googleapis.com/v1beta';

  /// Full generateContent endpoint for [model].
  static const String generateContentUrl =
      '$baseUrl/models/$model:generateContent';

  /// API key injected at compile time via
  /// `--dart-define=GEMINI_API_KEY=your_key`. Empty when not provided.
  static const String apiKey = String.fromEnvironment('GEMINI_API_KEY');

  /// The structured system prompt sent along with the sheet image. Instructs
  /// the model to answer with app-native `Note[:Beat]` tokens only.
  static const String extractionPrompt = '''
You are a sheet music reader. Look at the attached image of sheet music and
transcribe the notes in reading order (left to right, top line to bottom line).

Output format rules:
- Output ONLY the note tokens separated by single spaces. No explanations, no
  markdown, no code fences, no line breaks.
- Each token is Note:Beat, for example C:1 or F#:0.5 or Bb:2
- Note names: C C# Db D D# Eb E F F# Gb G G# Ab A A# Bb B
- Beat is the duration in quarter note beats: 4 = whole, 2 = half,
  1 = quarter, 0.5 = eighth, 0.25 = sixteenth
- Notes above the middle octave get a + suffix on the note name (A+:1),
  notes below get a - suffix (G-:2). Stack markers for two octaves (C++:1).
  Treat the octave starting at middle C (C4) as the middle octave.
- Ignore rests, lyrics, chord symbols and ornaments.
- If the image contains no readable sheet music, output exactly: NONE
''';
}
