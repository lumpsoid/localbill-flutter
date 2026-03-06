import 'package:flutter/material.dart';

import 'models/transactions_side_effects.dart';
import 'models/transactions_state.dart';
import 'transaction_detail_page.dart';
import 'transactions_controller.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({required this.controller, super.key});

  final TransactionsController controller;

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  late final ValueNotifier<TransactionsState> _state;

  @override
  void initState() {
    super.initState();
    _state = ValueNotifier(const TransactionsState());
    widget.controller.onViewAttach(
      updater: (s) => _state.value = s,
      pusher: _onEffect,
    );
  }

  void _onEffect(TransactionsEffect effect) {
    if (!mounted) return;
    switch (effect) {
      case ShowSnackbarEffect(:final message):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      case TransactionDeletedEffect(:final name):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"$name" deleted')),
        );
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
    return ValueListenableBuilder<TransactionsState>(
      valueListenable: _state,
      builder: (context, state, _) {
        return RefreshIndicator(
          onRefresh: widget.controller.loadTransactions,
          child: switch (state.status) {
            TransactionsStatus.idle ||
            TransactionsStatus.loading =>
              const Center(child: CircularProgressIndicator()),
            TransactionsStatus.error => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.errorMessage ?? 'Error loading transactions'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: widget.controller.loadTransactions,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            TransactionsStatus.loaded when state.items.isEmpty =>
              const Center(child: Text('No transactions yet.')),
            TransactionsStatus.loaded => ListView.builder(
              itemCount: state.items.length,
              itemBuilder: (context, i) {
                final item = state.items[i];
                return _TransactionTile(
                  item: item,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => TransactionDetailPage(item: item),
                    ),
                  ),
                  onDelete: () => widget.controller
                      .onDeleteTransaction(item.id, item.name),
                );
              },
            ),
          },
        );
      },
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  final dynamic item; // TransactionUiItem
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${item.retailer} · ${item.dateLabel}'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            item.priceLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      onTap: onTap,
      onLongPress: () => _confirmDelete(context),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: Text(item.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
