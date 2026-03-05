sealed class InsertEffect {
  const InsertEffect();
}

class InsertSuccessEffect extends InsertEffect {
  const InsertSuccessEffect(this.count);
  final int count;
}

class InsertErrorEffect extends InsertEffect {
  const InsertErrorEffect(this.message);
  final String message;
}

class InsertDuplicateEffect extends InsertEffect {
  const InsertDuplicateEffect();
}

class InsertQueuedEffect extends InsertEffect {
  const InsertQueuedEffect();
}
