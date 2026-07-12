import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:transposo/services/gemini_config.dart';
import 'package:transposo/services/gemini_vision_service.dart';

/// Builds a minimal successful generateContent response body.
String successBody(String text) => jsonEncode({
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': text},
            ],
          },
        },
      ],
    });

void main() {
  final imageBytes = Uint8List.fromList([1, 2, 3, 4]);

  group('GeminiVisionService.extractNotes', () {
    test('sends prompt, image and key, returns the model text', () async {
      late http.Request captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response(successBody('C:1 D:1 E:1'), 200);
      });
      final service = GeminiVisionService(client: client, apiKey: 'test-key');

      final result = await service.extractNotes(imageBytes, 'image/png');

      expect(result, 'C:1 D:1 E:1');
      expect(captured.url.toString(), GeminiConfig.generateContentUrl);
      expect(captured.headers['x-goog-api-key'], 'test-key');
      final sent = jsonDecode(captured.body) as Map<String, dynamic>;
      final parts =
          sent['contents'][0]['parts'] as List<dynamic>;
      expect(parts[0]['text'], GeminiConfig.extractionPrompt);
      expect(parts[1]['inline_data']['mime_type'], 'image/png');
      expect(parts[1]['inline_data']['data'], base64Encode(imageBytes));
    });

    test('strips code fences and collapses whitespace', () async {
      final client = MockClient((request) async {
        return http.Response(successBody('```\nC:1  D:1\nE:1\n```'), 200);
      });
      final service = GeminiVisionService(client: client, apiKey: 'k');

      expect(await service.extractNotes(imageBytes, 'image/jpeg'),
          'C:1 D:1 E:1');
    });

    test('throws GeminiMissingKeyException when no key is configured', () {
      final client = MockClient((request) async {
        fail('must not reach the network without a key');
      });
      final service = GeminiVisionService(client: client, apiKey: '');

      expect(
        () => service.extractNotes(imageBytes, 'image/jpeg'),
        throwsA(isA<GeminiMissingKeyException>()),
      );
    });

    test('throws GeminiApiException with the API error message on non-200',
        () {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {'message': 'API key not valid'},
          }),
          400,
        );
      });
      final service = GeminiVisionService(client: client, apiKey: 'bad');

      expect(
        () => service.extractNotes(imageBytes, 'image/jpeg'),
        throwsA(
          isA<GeminiApiException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having((e) => e.message, 'message', 'API key not valid'),
        ),
      );
    });

    test('throws GeminiNetworkException when the transport fails', () {
      final client = MockClient((request) async {
        throw http.ClientException('Connection failed');
      });
      final service = GeminiVisionService(client: client, apiKey: 'k');

      expect(
        () => service.extractNotes(imageBytes, 'image/jpeg'),
        throwsA(isA<GeminiNetworkException>()),
      );
    });

    test('throws GeminiNoNotesException when the model reports NONE', () {
      final client = MockClient((request) async {
        return http.Response(successBody('NONE'), 200);
      });
      final service = GeminiVisionService(client: client, apiKey: 'k');

      expect(
        () => service.extractNotes(imageBytes, 'image/jpeg'),
        throwsA(isA<GeminiNoNotesException>()),
      );
    });

    test('throws GeminiNoNotesException when candidates are missing', () {
      final client = MockClient((request) async {
        return http.Response(jsonEncode({'candidates': []}), 200);
      });
      final service = GeminiVisionService(client: client, apiKey: 'k');

      expect(
        () => service.extractNotes(imageBytes, 'image/jpeg'),
        throwsA(isA<GeminiNoNotesException>()),
      );
    });
  });
}
