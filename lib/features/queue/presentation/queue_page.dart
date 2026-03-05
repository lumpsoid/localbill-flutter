import 'package:flutter/material.dart';

import 'models/queue_side_effects.dart';
import 'models/queue_state.dart';
import 'queue_controller.dart';

class QueuePage extends StatefulWidget {
  const QueuePage({required this.controller, super.key});

  final QueueController controller;

  @override
  State<QueuePage> createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> {
  late final ValueNotifier<QueueState> _state;
  final _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _state = ValueNotifier(const QueueState());
    widget.controller.onViewAttach(
      updater: (s) => _state.value = s,
      pusher: _onEffect,
    );
  }

  void _onEffect(QueueEffect effect) {
    if (!mounted) return;
    switch (effect) {
      case QueueSnackbarEffect(:final message):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      case QueueProcessCompleteEffect(:final succeeded, :final failed):
        final msg = 'Done: $succeeded ok, $failed failed.';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
    }
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
    return ValueListenableBuilder<QueueState>(
      valueListenable: _state,
      builder: (context, state, _) {
        final isProcessing = state.status == QueueStatus.processing;
        return Column(
          children: [
            // Add-to-queue row
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _urlController,
                      enabled: !isProcessing,
                      decoration: const InputDecoration(
                        hintText: 'Invoice URL…',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: isProcessing
                        ? null
                        : () {
                            // Remove from local queue handled by controller.
                            // This button adds a new URL to the queue.
                            _addToQueue();
                          },
                    icon: const Icon(Icons.add),
                    tooltip: 'Add to queue',
                  ),
                ],
              ),
            ),

            // Process button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isProcessing
                      ? null
                      : widget.controller.onProcessQueue,
                  icon: isProcessing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow_outlined),
                  label: isProcessing
                      ? Text(
                          'Processing ${(state.processingIndex ?? 0) + 1}'
                          ' of ${state.items.length}…',
                        )
                      : Text('Process ${state.items.length} queued URL(s)'),
                ),
              ),
            ),

            const Divider(height: 24),

            // Queue list
            Expanded(
              child: switch (state.status) {
                QueueStatus.idle || QueueStatus.loading =>
                  const Center(child: CircularProgressIndicator()),
                QueueStatus.error => Center(
                  child: Text(state.errorMessage ?? 'Error loading queue'),
                ),
                QueueStatus.loaded || QueueStatus.processing
                    when state.items.isEmpty =>
                  const Center(child: Text('Queue is empty.')),
                _ => ListView.builder(
                  itemCount: state.items.length,
                  itemBuilder: (context, i) {
                    final url = state.items[i];
                    final isActive =
                        isProcessing && state.processingIndex == i;
                    return ListTile(
                      leading: isActive
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.link_outlined),
                      title: Text(
                        url,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: isProcessing
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () =>
                                  widget.controller.onRemoveUrl(url),
                            ),
                    );
                  },
                ),
              },
            ),
          ],
        );
      },
    );
  }

  void _addToQueue() {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    widget.controller.onAddUrl(url);
    _urlController.clear();
  }
}
