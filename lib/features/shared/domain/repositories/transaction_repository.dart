import '../entities/transaction.dart';

abstract interface class TransactionRepository {
  /// Returns all non-deleted transactions, sorted by date descending.
  Future<List<Transaction>> loadAll();

  /// Returns ALL transactions including soft-deleted ones.
  /// Used by sync to push the full local state to the server.
  Future<List<Transaction>> loadAllForSync();

  /// Persists a transaction. Overwrites if [transaction.id] already exists.
  Future<void> save(Transaction transaction);

  /// Soft-deletes the transaction with [id] by setting [Transaction.deleted].
  /// Financial records are never hard-deleted.
  Future<void> delete(String id);

  /// Returns `true` when any non-deleted transaction's [link] matches [url].
  Future<bool> isDuplicate(String url);

  /// Returns the highest serverSeq integrated from the server (0 if never synced).
  Future<int> loadLastSeq();

  /// Persists the highest serverSeq so the next sync can request only deltas.
  Future<void> saveLastSeq(int seq);
}
