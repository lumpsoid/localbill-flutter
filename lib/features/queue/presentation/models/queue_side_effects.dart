sealed class QueueEffect {
  const QueueEffect();
}

class QueueSnackbarEffect extends QueueEffect {
  const QueueSnackbarEffect(this.message);
  final String message;
}

class QueueProcessCompleteEffect extends QueueEffect {
  const QueueProcessCompleteEffect({
    required this.succeeded,
    required this.failed,
  });
  final int succeeded;
  final int failed;
}
