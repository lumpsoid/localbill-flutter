import '../entities/transaction.dart';

abstract interface class TransactionRepository {
  /// Returns all saved transactions, sorted by date descending.
  Future<List<Transaction>> loadAll();

  /// Persists a transaction. Overwrites if [transaction.id] already exists.
  Future<void> save(Transaction transaction);

  /// Deletes the transaction with [id]. No-op if not found.
  Future<void> delete(String id);

  /// Returns `true` when any transaction's [link] matches [url].
  Future<bool> isDuplicate(String url);
}
