import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/presentation/presenter.dart';
import '../../../core/presentation/side_effect.dart';
import '../../shared/domain/repositories/transaction_repository.dart';
import 'models/report_state.dart';
import 'report_presenter.dart';

sealed class ReportEffect {
  const ReportEffect();
}

class ReportErrorEffect extends ReportEffect {
  const ReportErrorEffect(this.message);
  final String message;
}

class ReportController {
  ReportController({
    required TransactionRepository transactionRepository,
    ReportPresenter? presenter,
    SideEffector<ReportEffect>? effectPusher,
  }) : _repo = transactionRepository,
       _presenter = presenter ?? ReportPresenter(),
       _effectPusher = effectPusher ?? SideEffector<ReportEffect>();

  final TransactionRepository _repo;
  final ReportPresenter _presenter;
  final SideEffector<ReportEffect> _effectPusher;

  void onViewAttach({
    required StateUpdater<ReportState> updater,
    required SideEffectPusher<ReportEffect> pusher,
  }) {
    _presenter.attach(updater);
    _effectPusher.attach(pusher);
    unawaited(loadReport());
  }

  void onViewDetach() {
    _presenter.detach();
    _effectPusher.detach();
  }

  Future<void> loadReport() async {
    _presenter.setLoading();
    try {
      final transactions = await _repo.loadAll();
      _presenter.setReport(transactions);
    } on Object catch (e, trace) {
      debugPrint('ReportController.loadReport error: $e\n$trace');
      _presenter.setError('Failed to load report.');
      _effectPusher.push(const ReportErrorEffect('Failed to load report.'));
    }
  }
}
