import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/presentation/presenter.dart';
import '../../../core/presentation/side_effect.dart';
import '../../shared/domain/repositories/transaction_repository.dart';
import 'models/transactions_side_effects.dart';
import 'models/transactions_state.dart';
import 'transactions_presenter.dart';

class TransactionsController {
  TransactionsController({
    required TransactionRepository transactionRepository,
    TransactionsPresenter? presenter,
    SideEffector<TransactionsEffect>? effectPusher,
  }) : _repo = transactionRepository,
       _presenter = presenter ?? TransactionsPresenter(),
       _effectPusher = effectPusher ?? SideEffector<TransactionsEffect>();

  final TransactionRepository _repo;
  final TransactionsPresenter _presenter;
  final SideEffector<TransactionsEffect> _effectPusher;

  void onViewAttach({
    required StateUpdater<TransactionsState> updater,
    required SideEffectPusher<TransactionsEffect> pusher,
  }) {
    _presenter.attach(updater);
    _effectPusher.attach(pusher);
    unawaited(loadTransactions());
  }

  void onViewDetach() {
    _presenter.detach();
    _effectPusher.detach();
  }

  Future<void> loadTransactions() async {
    _presenter.setLoading();
    try {
      final transactions = await _repo.loadAll();
      _presenter.setTransactions(transactions);
    } on Object catch (e, trace) {
      debugPrint('TransactionsController.loadTransactions error: $e\n$trace');
      _presenter.setError('Failed to load transactions.');
      _effectPusher.push(const ShowSnackbarEffect('Failed to load transactions.'));
    }
  }

  Future<void> onDeleteTransaction(String id, String name) async {
    try {
      await _repo.delete(id);
      _effectPusher.push(TransactionDeletedEffect(name));
      unawaited(loadTransactions());
    } on Object catch (e, trace) {
      debugPrint('TransactionsController.onDeleteTransaction error: $e\n$trace');
      _effectPusher.push(ShowSnackbarEffect('Failed to delete "$name".'));
    }
  }
}
