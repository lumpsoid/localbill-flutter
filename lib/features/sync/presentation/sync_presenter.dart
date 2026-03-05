import '../../../core/presentation/presenter.dart';
import '../../shared/domain/repositories/sync_repository.dart';
import 'models/sync_state.dart';

class SyncPresenter extends Presenter<SyncState> {
  SyncPresenter([SyncState? initialState])
    : super(initialState ?? const SyncState());

  void setSyncing() =>
      updateState((s) => s.copyWith(status: SyncStatus.syncing));

  void setSuccess(SyncResult result) => updateState(
    (s) => s.copyWith(
      status: SyncStatus.success,
      pushed: result.pushed,
      pulled: result.pulled,
    ),
  );

  void setError(String message) => updateState(
    (s) => s.copyWith(status: SyncStatus.error, errorMessage: message),
  );

  void setServerUrl(String url) =>
      updateState((s) => s.copyWith(serverUrl: url));
}
