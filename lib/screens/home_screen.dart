import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/instruments.dart';
import '../l10n/app_localizations.dart';
import '../core/measure_partitioner.dart';
import '../core/transposition.dart';
import '../services/gemini_vision_service.dart';
import '../widgets/sheet_music_view.dart';

/// Picks an image from [source], or returns null when the user cancels.
/// Injectable so widget tests can bypass the platform image picker.
typedef PickImageFn = Future<XFile?> Function(ImageSource source);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.visionService, this.pickImage});

  /// Gemini service override for tests; the real one is created lazily.
  final GeminiVisionService? visionService;

  /// Image picker override for tests.
  final PickImageFn? pickImage;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _notesController = TextEditingController();
  Instrument _source = Instrument.c;
  Instrument _target = Instrument.bFlat;
  List<TransposedNote> _result = [];
  int _skippedCount = 0;
  bool _hasTransposed = false;

  late final GeminiVisionService _visionService =
      widget.visionService ?? GeminiVisionService();
  late final PickImageFn _pickImage = widget.pickImage ??
      (source) => ImagePicker().pickImage(
            source: source,
            maxWidth: 2048,
            maxHeight: 2048,
            imageQuality: 90,
          );
  Uint8List? _pickedImageBytes;
  bool _isReadingImage = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  /// Infers the mime type sent to Gemini from the picked file.
  static String _mimeTypeFor(XFile file) {
    if (file.mimeType != null && file.mimeType!.isNotEmpty) {
      return file.mimeType!;
    }
    final path = file.path.toLowerCase();
    if (path.endsWith('.png')) return 'image/png';
    if (path.endsWith('.webp')) return 'image/webp';
    if (path.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }

  Future<void> _scanImage(ImageSource source) async {
    if (_isReadingImage) return;
    final l10n = AppLocalizations.of(context)!;

    final XFile? file;
    try {
      file = await _pickImage(source);
    } catch (_) {
      _showSnack(l10n.imagePickError);
      return;
    }
    if (file == null || !mounted) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _pickedImageBytes = bytes;
      _isReadingImage = true;
    });

    try {
      final notes = await _visionService.extractNotes(
        bytes,
        _mimeTypeFor(file),
      );
      if (!mounted) return;
      setState(() => _notesController.text = notes);
      _showSnack(l10n.aiReadSuccess);
    } on GeminiMissingKeyException {
      _showSnack(l10n.aiMissingKeyError);
    } on GeminiNetworkException {
      _showSnack(l10n.aiNetworkError);
    } on GeminiNoNotesException {
      _showSnack(l10n.aiNoNotesError);
    } on GeminiApiException catch (e) {
      debugPrint('Gemini API error ${e.statusCode}: ${e.message}');
      _showSnack('${l10n.aiGenericError}\nHTTP ${e.statusCode}: ${e.message}');
    } finally {
      if (mounted) setState(() => _isReadingImage = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _instrumentName(AppLocalizations l10n, Instrument instrument) {
    return switch (instrument) {
      Instrument.c => l10n.instrumentC,
      Instrument.bFlat => l10n.instrumentBb,
      Instrument.eFlat => l10n.instrumentEb,
      Instrument.f => l10n.instrumentF,
    };
  }

  void _transpose() {
    final l10n = AppLocalizations.of(context)!;
    final input = _notesController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.emptyInputWarning)));
      return;
    }

    final tokenCount =
        input.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).length;
    final result = transposeSequence(
      input,
      _source.semitoneOffset,
      _target.semitoneOffset,
    );

    setState(() {
      _result = result;
      _skippedCount = tokenCount - result.length;
      _hasTransposed = true;
    });

    if (result.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.noValidNotesWarning)));
    } else if (_skippedCount > 0) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.skippedTokensNotice(_skippedCount))),
        );
    }
  }

  void _swapInstruments() {
    setState(() {
      final tmp = _source;
      _source = _target;
      _target = tmp;
    });
  }

  Widget _instrumentDropdown({
    required String label,
    required Instrument value,
    required ValueChanged<Instrument> onChanged,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return DropdownButtonFormField<Instrument>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final instrument in Instrument.values)
          DropdownMenuItem(
            value: instrument,
            child: Text(
              _instrumentName(l10n, instrument),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _instrumentDropdown(
                      label: l10n.sourceInstrument,
                      value: _source,
                      onChanged: (v) => setState(() => _source = v),
                    ),
                    IconButton(
                      tooltip: l10n.swapInstrumentsTooltip,
                      icon: const Icon(Icons.swap_vert),
                      onPressed: _swapInstruments,
                    ),
                    _instrumentDropdown(
                      label: l10n.targetInstrument,
                      value: _target,
                      onChanged: (v) => setState(() => _target = v),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.scanSectionTitle,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isReadingImage
                                ? null
                                : () => _scanImage(ImageSource.camera),
                            icon: const Icon(Icons.photo_camera_outlined),
                            label: Text(l10n.scanFromCamera),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isReadingImage
                                ? null
                                : () => _scanImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: Text(l10n.scanFromGallery),
                          ),
                        ),
                      ],
                    ),
                    if (_pickedImageBytes != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.memory(
                              _pickedImageBytes!,
                              height: 140,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            if (_isReadingImage) ...[
                              const Positioned.fill(
                                child: ColoredBox(color: Colors.black45),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(),
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n.aiReadingIndicator,
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(color: Colors.white),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: _notesController,
                      minLines: 3,
                      maxLines: 6,
                      decoration: InputDecoration(
                        labelText: l10n.notesInputLabel,
                        hintText: l10n.notesInputHint,
                        helperText: l10n.notesInputHelper,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _transpose,
                      icon: const Icon(Icons.music_note),
                      label: Text(l10n.transposeButton),
                    ),
                  ],
                ),
              ),
            ),
            if (_hasTransposed && _result.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.resultLabel,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        _result.map((n) => n.readable).join(' '),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        l10n.sheetLabel,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    SheetMusicView(abc: buildAbcDocument(_result)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
