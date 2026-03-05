enum AddStatus { idle, saving, success, error }

class AddState {
  const AddState({
    this.status = AddStatus.idle,
    this.errorMessage,
  });

  final AddStatus status;
  final String? errorMessage;

  AddState copyWith({AddStatus? status, String? errorMessage}) => AddState(
    status: status ?? this.status,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}
