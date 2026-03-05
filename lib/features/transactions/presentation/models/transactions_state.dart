import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import 'transaction_ui_item.dart';

enum TransactionsStatus { idle, loading, loaded, error }

class TransactionsState {
  const TransactionsState({
    this.status = TransactionsStatus.idle,
    this.items = const IListConst([]),
    this.errorMessage,
  });

  final TransactionsStatus status;
  final IList<TransactionUiItem> items;
  final String? errorMessage;

  TransactionsState copyWith({
    TransactionsStatus? status,
    IList<TransactionUiItem>? items,
    String? errorMessage,
  }) => TransactionsState(
    status: status ?? this.status,
    items: items ?? this.items,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}
