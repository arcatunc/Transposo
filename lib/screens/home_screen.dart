import 'package:flutter/material.dart';
import '../core/instruments.dart';
import '../l10n/app_localizations.dart';
import '../core/transposition.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
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
            ],
          ],
        ),
      ),
    );
  }
}
