import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:transposo/l10n/app_localizations.dart';
import 'package:transposo/screens/home_screen.dart';
import 'package:transposo/services/gemini_vision_service.dart';

/// A 1x1 transparent PNG so Image.memory can decode the preview in tests.
final Uint8List kTinyPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJ'
  'AAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

/// Fake service that skips the network and returns a fixed token string,
/// per roadmap Phase 3 test scenario 2 (mock AI sequence injection).
class _FakeVisionService extends GeminiVisionService {
  _FakeVisionService(this.result) : super(apiKey: 'test-key');

  final Object result;

  @override
  Future<String> extractNotes(Uint8List imageBytes, String mimeType) async {
    final r = result;
    if (r is GeminiException) throw r;
    return r as String;
  }
}

Widget _app({required GeminiVisionService service, PickImageFn? pickImage}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: HomeScreen(
      visionService: service,
      pickImage: pickImage ??
          (source) async => XFile.fromData(
                kTinyPng,
                mimeType: 'image/png',
                name: 'sheet.png',
              ),
    ),
  );
}

void main() {
  testWidgets('mock AI output lands in the notes input field', (tester) async {
    await tester.pumpWidget(_app(service: _FakeVisionService('C:1 D:1 E:1')));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.photo_library_outlined));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'C:1 D:1 E:1');
    // The picked image preview is shown.
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('network failure surfaces a snackbar, field stays untouched',
      (tester) async {
    await tester.pumpWidget(_app(
      service: _FakeVisionService(const GeminiNetworkException('offline')),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.photo_camera_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, isEmpty);
  });

  testWidgets('cancelled pick does nothing', (tester) async {
    await tester.pumpWidget(_app(
      service: _FakeVisionService('C:1'),
      pickImage: (source) async => null,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.photo_library_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
    expect(find.byType(Image), findsNothing);
  });
}
