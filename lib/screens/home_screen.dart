import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../core/instruments.dart';
import '../l10n/app_localizations.dart';
import '../core/measure_partitioner.dart';
import '../core/transposition.dart';
import '../services/app_storage.dart';
import '../services/gemini_vision_service.dart';
import '../widgets/sheet_music_view.dart';

/// Picks an image from [source], or returns null when the user cancels.
/// Injectable so widget tests can bypass the platform image picker.
typedef PickImageFn = Future<XFile?> Function(ImageSource source);

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.visionService,
    this.pickImage,
    this.storage,
  });

  /// Gemini service override for tests; the real one is created lazily.
  final GeminiVisionService? visionService;

  /// Image picker override for tests.
  final PickImageFn? pickImage;

  /// Persistence override for tests.
  final AppStorage? storage;

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

  late final AppStorage _storage = widget.storage ?? AppStorage();
  List<ConversionRecord> _history = [];
  Timer? _liveUpdateDebounce;

  /// Debounce for persisting and live re-rendering while the user types.
  static const _liveUpdateDelay = Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();
    _notesController.addListener(_onNotesChanged);
    _restoreState();
  }

  @override
  void dispose() {
    _liveUpdateDebounce?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  /// Loads the persisted workspace and history on launch (roadmap Phase 4
  /// scenario 1: state survives an app restart).
  Future<void> _restoreState() async {
    final workspace = await _storage.loadWorkspace();
    final history = await _storage.loadHistory();
    if (!mounted) return;
    setState(() {
      _history = history;
      if (workspace != null) {
        _source = workspace.source;
        _target = workspace.target;
        _notesController.text = workspace.input;
      }
    });
  }

  /// Fires on every keystroke in the notes field; after a short pause it
  /// persists the workspace and, when a result is already on screen, silently
  /// re-transposes so the sheet music follows the edit in real time
  /// (roadmap Phase 4 scenario 3).
  void _onNotesChanged() {
    _liveUpdateDebounce?.cancel();
    _liveUpdateDebounce = Timer(_liveUpdateDelay, () {
      _persistWorkspace();
      if (_hasTransposed) _retranspose();
    });
  }

  void _persistWorkspace() {
    unawaited(_storage.saveWorkspace(
      input: _notesController.text,
      source: _source,
      target: _target,
    ));
  }

  /// Recomputes the result from the current input without snackbars and
  /// without recording history, used for live updates and history restores.
  void _retranspose() {
    if (!mounted) return;
    final input = _notesController.text.trim();
    final tokenCount =
        input.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).length;
    final result = input.isEmpty
        ? <TransposedNote>[]
        : transposeSequence(
            input,
            _source.semitoneOffset,
            _target.semitoneOffset,
          );
    setState(() {
      _result = result;
      _skippedCount = tokenCount - result.length;
    });
  }

  void _onInstrumentsChanged() {
    _persistWorkspace();
    if (_hasTransposed) _retranspose();
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

    _persistWorkspace();
    if (result.isNotEmpty) {
      unawaited(_recordHistory(input));
    }

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

  Future<void> _recordHistory(String input) async {
    final history = await _storage.addHistoryRecord(ConversionRecord(
      timestamp: DateTime.now(),
      source: _source,
      target: _target,
      notes: input,
    ));
    if (mounted) setState(() => _history = history);
  }

  void _swapInstruments() {
    setState(() {
      final tmp = _source;
      _source = _target;
      _target = tmp;
    });
    _onInstrumentsChanged();
  }

  /// Fills the form from a past conversion and shows its result immediately
  /// (roadmap Phase 4 scenario 2). Restoring does not add a history entry;
  /// only the transpose button does.
  void _restoreRecord(ConversionRecord record) {
    setState(() {
      _source = record.source;
      _target = record.target;
      _hasTransposed = true;
    });
    _notesController.text = record.notes;
    _persistWorkspace();
    _retranspose();
  }

  Future<void> _showHistory() async {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final dateFormat = DateFormat.yMMMd(locale).add_Hm();

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(sheetContext).size.height * 0.6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.historyTitle,
                              style:
                                  Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          if (_history.isNotEmpty)
                            TextButton.icon(
                              onPressed: () async {
                                await _storage.clearHistory();
                                if (mounted) {
                                  setState(() => _history = []);
                                }
                                setSheetState(() {});
                              },
                              icon: const Icon(Icons.delete_outline),
                              label: Text(l10n.historyClear),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _history.isEmpty
                          ? Center(child: Text(l10n.historyEmpty))
                          : ListView.separated(
                              itemCount: _history.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final record = _history[index];
                                return ListTile(
                                  title: Text(
                                    record.notes,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${dateFormat.format(record.timestamp)}'
                                    '  ·  '
                                    '${_instrumentShortName(l10n, record.source)}'
                                    ' → '
                                    '${_instrumentShortName(l10n, record.target)}',
                                  ),
                                  onTap: () {
                                    Navigator.of(sheetContext).pop();
                                    _restoreRecord(record);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _instrumentShortName(AppLocalizations l10n, Instrument instrument) {
    return switch (instrument) {
      Instrument.c => l10n.instrumentShortC,
      Instrument.bFlat => l10n.instrumentShortBb,
      Instrument.eFlat => l10n.instrumentShortEb,
      Instrument.f => l10n.instrumentShortF,
    };
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
        actions: [
          IconButton(
            tooltip: l10n.historyTooltip,
            icon: const Icon(Icons.history),
            onPressed: _showHistory,
          ),
        ],
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
                      onChanged: (v) {
                        setState(() => _source = v);
                        _onInstrumentsChanged();
                      },
                    ),
                    IconButton(
                      tooltip: l10n.swapInstrumentsTooltip,
                      icon: const Icon(Icons.swap_vert),
                      onPressed: _swapInstruments,
                    ),
                    _instrumentDropdown(
                      label: l10n.targetInstrument,
                      value: _target,
                      onChanged: (v) {
                        setState(() => _target = v);
                        _onInstrumentsChanged();
                      },
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
