enum SyncStatus { idle, syncing, success, error }

class SyncState {
  const SyncState({
    this.status = SyncStatus.idle,
    this.pushed = 0,
    this.pulled = 0,
    this.errorMessage,
    this.serverUrl = '',
  });

  final SyncStatus status;
  final int pushed;
  final int pulled;
  final String? errorMessage;
  final String serverUrl;

  SyncState copyWith({
    SyncStatus? status,
    int? pushed,
    int? pulled,
    String? errorMessage,
    String? serverUrl,
  }) => SyncState(
    status: status ?? this.status,
    pushed: pushed ?? this.pushed,
    pulled: pulled ?? this.pulled,
    errorMessage: errorMessage ?? this.errorMessage,
    serverUrl: serverUrl ?? this.serverUrl,
  );
}
