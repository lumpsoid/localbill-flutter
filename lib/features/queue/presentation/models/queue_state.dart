import 'package:fast_immutable_collections/fast_immutable_collections.dart';

enum QueueStatus { idle, loading, loaded, processing, error }

class QueueState {
  const QueueState({
    this.status = QueueStatus.idle,
    this.items = const IListConst([]),
    this.processingIndex,
    this.errorMessage,
  });

  final QueueStatus status;
  final IList<String> items;

  /// Index of the URL currently being processed (null when idle).
  final int? processingIndex;
  final String? errorMessage;

  QueueState copyWith({
    QueueStatus? status,
    IList<String>? items,
    int? processingIndex,
    String? errorMessage,
  }) => QueueState(
    status: status ?? this.status,
    items: items ?? this.items,
    processingIndex: processingIndex,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}
