import '../entities/transaction.dart';

/// A conflict detected during sync: the client and server disagree on the
/// immutable core fields (coreHash mismatch) for the same [id].
///
/// Conflicts are never auto-resolved. They are surfaced to the user so they
/// can investigate. The server version is preserved on the server; the client
/// version is preserved locally. Neither is overwritten automatically.
class SyncConflict {
  const SyncConflict({
    required this.id,
    required this.clientVersion,
    required this.serverVersion,
  });

  final String id;
  final Transaction clientVersion;
  final Transaction serverVersion;
}

/// Result of a sync operation.
class SyncResult {
  const SyncResult({
    required this.pushed,
    required this.pulled,
    required this.conflicts,
    required this.newTransactions,
    required this.acceptedSeqs,
    this.newServerSeq,
  });

  /// Number of records the client uploaded and the server accepted.
  final int pushed;

  /// Number of new records received from the server.
  final int pulled;

  /// Conflicts: same id but different coreHash on client vs server.
  final List<SyncConflict> conflicts;

  /// Full transaction objects for new records from the server.
  final List<Transaction> newTransactions;

  /// Map of id → serverSeq for records accepted this sync round.
  final Map<String, int> acceptedSeqs;

  /// The server's highest sequence number after this sync round.
  final int? newServerSeq;
}

abstract interface class SyncRepository {
  /// Performs a delta sync with the server.
  ///
  /// [unacknowledged] — transactions where [Transaction.serverSeq] is null
  ///   (never sent or response was lost).
  /// [lastSeq] — the highest serverSeq the client has already integrated.
  ///   Pass 0 on first sync to receive all server records.
  ///
  /// Returns a [SyncResult] describing what was exchanged and any conflicts.
  Future<SyncResult> sync({
    required List<Transaction> unacknowledged,
    required int lastSeq,
  });

  /// Fetches URLs from the remote queue.
  Future<List<String>> fetchRemoteQueue();

  /// Marks queue items as processed so the server can remove them.
  Future<void> removeFromRemoteQueue(List<String> urls);
}
