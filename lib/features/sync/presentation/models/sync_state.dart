import '../../../shared/domain/repositories/sync_repository.dart';

export '../../../shared/domain/repositories/sync_repository.dart'
    show SyncConflict;

enum SyncStatus { idle, syncing, success, error }

class SyncState {
  const SyncState({
    this.status = SyncStatus.idle,
    this.pushed = 0,
    this.pulled = 0,
    this.conflicts = const [],
    this.errorMessage,
    this.serverUrl = '',
  });

  final SyncStatus status;
  final int pushed;
  final int pulled;

  /// Conflicts detected during the last sync. Empty when none.
  final List<SyncConflict> conflicts;

  final String? errorMessage;
  final String serverUrl;

  SyncState copyWith({
    SyncStatus? status,
    int? pushed,
    int? pulled,
    List<SyncConflict>? conflicts,
    String? errorMessage,
    String? serverUrl,
  }) =>
      SyncState(
        status: status ?? this.status,
        pushed: pushed ?? this.pushed,
        pulled: pulled ?? this.pulled,
        conflicts: conflicts ?? this.conflicts,
        errorMessage: errorMessage ?? this.errorMessage,
        serverUrl: serverUrl ?? this.serverUrl,
      );
}
