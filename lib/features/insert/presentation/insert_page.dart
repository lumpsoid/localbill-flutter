import 'package:flutter/material.dart';

import '../../scanner/presentation/scanner_page.dart';
import 'insert_controller.dart';
import 'models/insert_side_effects.dart';
import 'models/insert_state.dart';

class InsertPage extends StatefulWidget {
  const InsertPage({required this.controller, super.key});

  final InsertController controller;

  @override
  State<InsertPage> createState() => _InsertPageState();
}

class _InsertPageState extends State<InsertPage> {
  late final ValueNotifier<InsertState> _state;
  final _urlController = TextEditingController();
  bool _force = false;

  @override
  void initState() {
    super.initState();
    _state = ValueNotifier(const InsertState());
    widget.controller.onViewAttach(
      updater: (s) => _state.value = s,
      pusher: _onEffect,
    );
  }

  void _onEffect(InsertEffect effect) {
    if (!mounted) return;
    switch (effect) {
      case InsertSuccessEffect(:final count):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved $count transaction(s).')),
        );
        _urlController.clear();
      case InsertErrorEffect(:final message):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $message')));
      case InsertDuplicateEffect():
        _showDuplicateDialog();
      case InsertQueuedEffect():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('URL added to queue.')),
        );
        _urlController.clear();
    }
  }

  void _showDuplicateDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Already recorded'),
        content: const Text(
          'This invoice URL is already in your transactions.\n'
          'Insert anyway?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.controller.onInsertUrl(
                _urlController.text,
                force: true,
              );
            },
            child: const Text('Insert anyway'),
          ),
        ],
      ),
    );
  }

  /// Open the QR scanner and, if a URL is returned, fill the text field and
  /// immediately start parsing the invoice.
  Future<void> _scanQr() async {
    final url = await Navigator.of(context).push<String>(ScannerPage.route());
    if (url == null || url.isEmpty) return;
    _urlController.text = url;
    // Auto-insert once the URL is scanned.
    widget.controller.onInsertUrl(url, force: _force);
  }

  @override
  void dispose() {
    widget.controller.onViewDetach();
    _state.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<InsertState>(
      valueListenable: _state,
      builder: (context, state, _) {
        final isParsing = state.status == InsertStatus.parsing;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Scan the QR code on your invoice or paste the URL manually.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              // QR scan button — prominent, full-width
              OutlinedButton.icon(
                onPressed: isParsing ? null : _scanQr,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan invoice QR code'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'or paste URL',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _urlController,
                enabled: !isParsing,
                decoration: const InputDecoration(
                  labelText: 'Invoice URL',
                  hintText: 'https://suf.purs.gov.rs/v/?vl=...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _force,
                onChanged:
                    isParsing ? null : (v) => setState(() => _force = v ?? false),
                title: const Text('Insert even if already recorded'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              if (isParsing)
                const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Parsing invoice…'),
                  ],
                )
              else ...[
                FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Insert invoice'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _queue,
                  icon: const Icon(Icons.queue_outlined),
                  label: const Text('Add to queue'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _submit() =>
      widget.controller.onInsertUrl(_urlController.text, force: _force);

  void _queue() => widget.controller.onQueueUrl(_urlController.text);
}
