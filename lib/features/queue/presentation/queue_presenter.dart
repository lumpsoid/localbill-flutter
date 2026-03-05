import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import '../../../core/presentation/presenter.dart';
import 'models/queue_state.dart';

class QueuePresenter extends Presenter<QueueState> {
  QueuePresenter([QueueState? initialState])
    : super(initialState ?? const QueueState());

  void setLoading() =>
      updateState((s) => s.copyWith(status: QueueStatus.loading));

  void setQueue(List<String> items) => updateState(
    (s) => s.copyWith(status: QueueStatus.loaded, items: IList(items)),
  );

  void setProcessing(int index) => updateState(
    (s) => s.copyWith(status: QueueStatus.processing, processingIndex: index),
  );

  void setError(String message) => updateState(
    (s) => s.copyWith(status: QueueStatus.error, errorMessage: message),
  );
}
