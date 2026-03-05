enum InsertStatus { idle, parsing, success, error }

class InsertState {
  const InsertState({
    this.status = InsertStatus.idle,
    this.errorMessage,
    this.savedCount = 0,
  });

  final InsertStatus status;
  final String? errorMessage;

  /// Number of transaction files written on last successful insert.
  final int savedCount;

  InsertState copyWith({
    InsertStatus? status,
    String? errorMessage,
    int? savedCount,
  }) => InsertState(
    status: status ?? this.status,
    errorMessage: errorMessage ?? this.errorMessage,
    savedCount: savedCount ?? this.savedCount,
  );
}
