import '../../../core/presentation/presenter.dart';
import 'models/insert_state.dart';

class InsertPresenter extends Presenter<InsertState> {
  InsertPresenter([InsertState? initialState])
    : super(initialState ?? const InsertState());

  void setIdle() => updateState((s) => s.copyWith(status: InsertStatus.idle));

  void setParsing() =>
      updateState((s) => s.copyWith(status: InsertStatus.parsing));

  void setSuccess(int count) => updateState(
    (s) => s.copyWith(status: InsertStatus.success, savedCount: count),
  );

  void setError(String message) => updateState(
    (s) =>
        s.copyWith(status: InsertStatus.error, errorMessage: message),
  );
}
