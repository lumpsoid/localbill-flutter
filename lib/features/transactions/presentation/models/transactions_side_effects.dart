sealed class TransactionsEffect {
  const TransactionsEffect();
}

class ShowSnackbarEffect extends TransactionsEffect {
  const ShowSnackbarEffect(this.message);
  final String message;
}

class TransactionDeletedEffect extends TransactionsEffect {
  const TransactionDeletedEffect(this.name);
  final String name;
}
