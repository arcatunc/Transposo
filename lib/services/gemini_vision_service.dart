/// Serverless Gemini Vision integration (Phase 3).
///
/// Sends a sheet music image plus the structured extraction prompt to the
/// Gemini generateContent REST endpoint using plain `http`, per the project
/// decision to avoid the deprecated google_generative_ai package.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'gemini_config.dart';

/// Base class for every failure the service can report, so the UI can map
/// each case to a localized message.
sealed class GeminiException implements Exception {
  const GeminiException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// No API key was provided at compile time.
class GeminiMissingKeyException extends GeminiException {
  const GeminiMissingKeyException()
      : super('GEMINI_API_KEY was not provided via --dart-define');
}

/// The device could not reach the API (offline, DNS failure, timeout).
class GeminiNetworkException extends GeminiException {
  const GeminiNetworkException(super.message);
}

/// The API answered with a non-success status code.
class GeminiApiException extends GeminiException {
  const GeminiApiException(this.statusCode, super.message);

  final int statusCode;
}

/// The API answered successfully but no note text could be extracted
/// (empty candidates, safety block, or the model reported NONE).
class GeminiNoNotesException extends GeminiException {
  const GeminiNoNotesException() : super('No notes found in the image');
}

/// Calls Gemini Vision over REST and returns the extracted note tokens.
class GeminiVisionService {
  GeminiVisionService({http.Client? client, String? apiKey})
      : _client = client ?? http.Client(),
        _apiKey = apiKey ?? GeminiConfig.apiKey;

  final http.Client _client;
  final String _apiKey;

  static const Duration _timeout = Duration(seconds: 60);

  /// Sends [imageBytes] (with its [mimeType], e.g. `image/jpeg`) to Gemini
  /// and returns the raw `Note:Beat` token string produced by the model.
  ///
  /// Throws a [GeminiException] subtype on any failure.
  Future<String> extractNotes(Uint8List imageBytes, String mimeType) async {
    if (_apiKey.isEmpty) {
      throw const GeminiMissingKeyException();
    }

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': GeminiConfig.extractionPrompt},
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Encode(imageBytes),
              },
            },
          ],
        },
      ],
      'generationConfig': {'temperature': 0},
    });

    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(GeminiConfig.generateContentUrl),
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': _apiKey,
            },
            body: body,
          )
          .timeout(_timeout);
    } on SocketException catch (e) {
      throw GeminiNetworkException(e.message);
    } on http.ClientException catch (e) {
      throw GeminiNetworkException(e.message);
    } on Exception catch (e) {
      // TimeoutException and anything else transport related.
      throw GeminiNetworkException(e.toString());
    }

    if (response.statusCode != 200) {
      throw GeminiApiException(
        response.statusCode,
        _errorMessageFromBody(response.body),
      );
    }

    final text = _textFromBody(response.body);
    if (text == null || text.isEmpty || text.toUpperCase() == 'NONE') {
      throw const GeminiNoNotesException();
    }
    return text;
  }

  /// Extracts and cleans the model text from a generateContent response.
  static String? _textFromBody(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final candidates = json['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) return null;
      final content =
          (candidates.first as Map<String, dynamic>)['content']
              as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      if (parts == null) return null;
      final text = parts
          .map((p) => (p as Map<String, dynamic>)['text'] as String? ?? '')
          .join(' ');
      return _sanitize(text);
    } on FormatException {
      return null;
    }
  }

  /// Strips code fences and collapses whitespace so the result drops
  /// straight into the note input field.
  static String _sanitize(String text) {
    return text
        .replaceAll(RegExp(r'```[a-zA-Z]*'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _errorMessageFromBody(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final error = json['error'] as Map<String, dynamic>?;
      return error?['message'] as String? ?? body;
    } on FormatException {
      return body;
    }
  }
}
