import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import '../../../core/presentation/presenter.dart';
import '../../../features/shared/domain/entities/transaction.dart';
import 'models/transaction_ui_item.dart';
import 'models/transactions_state.dart';

class TransactionsPresenter extends Presenter<TransactionsState> {
  TransactionsPresenter([TransactionsState? initialState])
    : super(initialState ?? const TransactionsState());

  void setLoading() =>
      updateState((s) => s.copyWith(status: TransactionsStatus.loading));

  void setTransactions(List<Transaction> transactions) {
    final items = IList(transactions.map(_toUiItem));
    updateState(
      (s) => s.copyWith(status: TransactionsStatus.loaded, items: items),
    );
  }

  void setError(String message) => updateState(
    (s) => s.copyWith(
      status: TransactionsStatus.error,
      errorMessage: message,
    ),
  );

  TransactionUiItem _toUiItem(Transaction t) => TransactionUiItem(
    id: t.id,
    dateLabel: _formatDate(t.date),
    retailer: t.retailer,
    name: t.name,
    quantityLabel: _formatQuantity(t.quantity),
    unitPriceLabel: '${t.unitPrice.toStringAsFixed(2)} ${t.currency}',
    priceLabel: '${t.priceTotal.toStringAsFixed(2)} ${t.currency}',
    currency: t.currency,
    country: t.country,
    tags: t.tags.toList(),
    updatedAtLabel: _formatDate(t.updatedAt),
    link: t.link,
    notes: t.notes,
  );

  String _formatDate(String iso) {
    // "2024-03-15T14:30:00" → "2024-03-15 14:30"
    if (iso.length < 10) return iso;
    final date = iso.substring(0, 10);
    final time = iso.length >= 16 ? iso.substring(11, 16) : '';
    return time.isEmpty ? date : '$date $time';
  }

  String _formatQuantity(double qty) =>
      qty == qty.truncateToDouble() ? qty.toInt().toString() : qty.toString();
}
