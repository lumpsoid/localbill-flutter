import 'package:flutter/material.dart';

import 'models/sync_state.dart';
import 'sync_controller.dart';

class SyncPage extends StatefulWidget {
  const SyncPage({required this.controller, super.key});

  final SyncController controller;

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  late final ValueNotifier<SyncState> _state;
  late final TextEditingController _serverUrlCtrl;

  @override
  void initState() {
    super.initState();
    _state = ValueNotifier(const SyncState());
    widget.controller.onViewAttach(
      updater: (s) {
        _state.value = s;
        if (_serverUrlCtrl.text != s.serverUrl) {
          _serverUrlCtrl.text = s.serverUrl;
        }
      },
      pusher: _onEffect,
    );
    _serverUrlCtrl = TextEditingController(text: _state.value.serverUrl);
  }

  void _onEffect(SyncEffect effect) {
    if (!mounted) return;
    switch (effect) {
      case SyncCompleteEffect(:final pushed, :final pulled, :final conflicts):
        final extra = conflicts > 0 ? ' ($conflicts conflict(s))' : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync done: $pushed pushed, $pulled pulled$extra.'),
          ),
        );
      case SyncErrorEffect(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync error: $message')),
        );
    }
  }

  @override
  void dispose() {
    widget.controller.onViewDetach();
    _state.dispose();
    _serverUrlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SyncState>(
      valueListenable: _state,
      builder: (context, state, _) {
        final isSyncing = state.status == SyncStatus.syncing;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Sync your transactions with the localbill-server.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _serverUrlCtrl,
                enabled: !isSyncing,
                decoration: const InputDecoration(
                  labelText: 'Server URL',
                  hintText: 'http://192.168.1.2:8080',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.dns_outlined),
                ),
                onChanged: widget.controller.onServerUrlChanged,
              ),
              const SizedBox(height: 24),
              if (isSyncing)
                const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Syncing…'),
                  ],
                )
              else
                FilledButton.icon(
                  onPressed: widget.controller.onSync,
                  icon: const Icon(Icons.sync_outlined),
                  label: const Text('Sync now'),
                ),
              if (state.status == SyncStatus.success) ...[
                const SizedBox(height: 24),
                _SyncResultCard(
                  pushed: state.pushed,
                  pulled: state.pulled,
                ),
                if (state.conflicts.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _ConflictList(conflicts: state.conflicts),
                ],
              ],
              if (state.status == SyncStatus.error) ...[
                const SizedBox(height: 16),
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      state.errorMessage ?? 'Unknown error',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SyncResultCard extends StatelessWidget {
  const _SyncResultCard({required this.pushed, required this.pulled});

  final int pushed;
  final int pulled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _Stat(label: 'Pushed', value: '$pushed'),
            _Stat(label: 'Pulled', value: '$pulled'),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

/// Displays the list of sync conflicts with details for user review.
class _ConflictList extends StatelessWidget {
  const _ConflictList({required this.conflicts});

  final List<SyncConflict> conflicts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: theme.colorScheme.error, size: 20),
            const SizedBox(width: 8),
            Text(
              '${conflicts.length} conflict(s) detected',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'The following records have different core data on the server '
          'and on this device. No data was overwritten. '
          'Please investigate manually.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        ...conflicts.map((c) => _ConflictCard(conflict: c)),
      ],
    );
  }
}

class _ConflictCard extends StatelessWidget {
  const _ConflictCard({required this.conflict});

  final SyncConflict conflict;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final client = conflict.clientVersion;
    final server = conflict.serverVersion;

    return Card(
      color: theme.colorScheme.errorContainer,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ID: ${conflict.id}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 4),
            _ConflictRow(
              label: 'Local',
              name: client.name,
              total: client.priceTotal,
              currency: client.currency,
              hash: client.coreHash,
              color: theme.colorScheme.onErrorContainer,
            ),
            const Divider(height: 12),
            _ConflictRow(
              label: 'Server',
              name: server.name,
              total: server.priceTotal,
              currency: server.currency,
              hash: server.coreHash,
              color: theme.colorScheme.onErrorContainer,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConflictRow extends StatelessWidget {
  const _ConflictRow({
    required this.label,
    required this.name,
    required this.total,
    required this.currency,
    required this.hash,
    required this.color,
  });

  final String label;
  final String name;
  final double total;
  final String currency;
  final String hash;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 12,
          ),
        ),
        Text(
          '$name — $total $currency',
          style: TextStyle(color: color),
        ),
        Text(
          'hash: ${hash.substring(0, 16)}…',
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
