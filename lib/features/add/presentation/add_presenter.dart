import '../../../core/presentation/presenter.dart';
import 'models/add_state.dart';

class AddPresenter extends Presenter<AddState> {
  AddPresenter([AddState? initialState])
    : super(initialState ?? const AddState());

  void setIdle() => updateState((s) => s.copyWith(status: AddStatus.idle));

  void setSaving() => updateState((s) => s.copyWith(status: AddStatus.saving));

  void setSuccess() =>
      updateState((s) => s.copyWith(status: AddStatus.success));

  void setError(String message) => updateState(
    (s) => s.copyWith(status: AddStatus.error, errorMessage: message),
  );
}
