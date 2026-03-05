import 'package:flutter/material.dart';

import 'models/report_state.dart';
import 'report_controller.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({required this.controller, super.key});

  final ReportController controller;

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  late final ValueNotifier<ReportState> _state;

  @override
  void initState() {
    super.initState();
    _state = ValueNotifier(const ReportState());
    widget.controller.onViewAttach(
      updater: (s) => _state.value = s,
      pusher: _onEffect,
    );
  }

  void _onEffect(ReportEffect effect) {
    if (!mounted) return;
    switch (effect) {
      case ReportErrorEffect(:final message):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  void dispose() {
    widget.controller.onViewDetach();
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ReportState>(
      valueListenable: _state,
      builder: (context, state, _) {
        return RefreshIndicator(
          onRefresh: widget.controller.loadReport,
          child: switch (state.status) {
            ReportStatus.idle || ReportStatus.loading =>
              const Center(child: CircularProgressIndicator()),
            ReportStatus.error => Center(
              child: Text(state.errorMessage ?? 'Error loading report'),
            ),
            ReportStatus.loaded when state.rows.isEmpty =>
              const Center(child: Text('No transactions to report.')),
            ReportStatus.loaded => _ReportBody(state: state),
          },
        );
      },
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({required this.state});

  final ReportState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Row(
          children: [
            Expanded(
              child: Text('Month', style: theme.textTheme.labelLarge),
            ),
            Text('Items', style: theme.textTheme.labelLarge),
            const SizedBox(width: 16),
            SizedBox(
              width: 110,
              child: Text(
                'Total (RSD)',
                textAlign: TextAlign.right,
                style: theme.textTheme.labelLarge,
              ),
            ),
          ],
        ),
        const Divider(),
        // Rows
        ...state.rows.map(
          (row) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(child: Text(row.yearMonth)),
                Text('${row.count}'),
                const SizedBox(width: 16),
                SizedBox(
                  width: 110,
                  child: Text(
                    row.total.toStringAsFixed(2),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(),
        // Grand total
        Row(
          children: [
            Expanded(
              child: Text(
                'TOTAL (${state.totalItems} items)',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              width: 110,
              child: Text(
                state.grandTotal.toStringAsFixed(2),
                textAlign: TextAlign.right,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
