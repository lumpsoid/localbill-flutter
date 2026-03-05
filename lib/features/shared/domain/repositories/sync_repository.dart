import '../entities/transaction.dart';

/// Result of a sync operation.
class SyncResult {
  const SyncResult({
    required this.pushed,
    required this.pulled,
  });

  /// Number of transactions uploaded to the server.
  final int pushed;

  /// Number of transactions received from the server (new to local).
  final int pulled;
}

abstract interface class SyncRepository {
  /// Syncs local transactions with the server.
  ///
  /// Sends all [local] transactions to the server and receives any
  /// server-side transactions not present locally.
  ///
  /// Returns a [SyncResult] describing what was exchanged.
  Future<SyncResult> sync(List<Transaction> local);

  /// Fetches the remote queue and returns its URLs.
  Future<List<String>> fetchRemoteQueue();

  /// Reports successfully-processed queue items to the server for removal.
  Future<void> removeFromRemoteQueue(List<String> urls);
}
