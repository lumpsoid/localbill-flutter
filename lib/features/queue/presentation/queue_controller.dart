import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/presentation/presenter.dart';
import '../../../core/presentation/side_effect.dart';
import '../../shared/data/invoice_helpers.dart';
import '../../shared/data/invoice_parser.dart';
import '../../shared/domain/entities/transaction.dart';
import '../../shared/domain/repositories/queue_repository.dart';
import '../../shared/domain/repositories/transaction_repository.dart';
import 'models/queue_side_effects.dart';
import 'models/queue_state.dart';
import 'queue_presenter.dart';

class QueueController {
  QueueController({
    required QueueRepository queueRepository,
    required TransactionRepository transactionRepository,
    QueuePresenter? presenter,
    SideEffector<QueueEffect>? effectPusher,
  }) : _queueRepo = queueRepository,
       _txRepo = transactionRepository,
       _presenter = presenter ?? QueuePresenter(),
       _effectPusher = effectPusher ?? SideEffector<QueueEffect>();

  final QueueRepository _queueRepo;
  final TransactionRepository _txRepo;
  final QueuePresenter _presenter;
  final SideEffector<QueueEffect> _effectPusher;
  final _uuid = const Uuid();

  void onViewAttach({
    required StateUpdater<QueueState> updater,
    required SideEffectPusher<QueueEffect> pusher,
  }) {
    _presenter.attach(updater);
    _effectPusher.attach(pusher);
    unawaited(loadQueue());
  }

  void onViewDetach() {
    _presenter.detach();
    _effectPusher.detach();
  }

  Future<void> loadQueue() async {
    _presenter.setLoading();
    try {
      final items = await _queueRepo.loadAll();
      _presenter.setQueue(items);
    } on Object catch (e, trace) {
      debugPrint('QueueController.loadQueue error: $e\n$trace');
      _presenter.setError('Failed to load queue.');
    }
  }

  Future<void> onAddUrl(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      _effectPusher.push(const QueueSnackbarEffect('URL must not be empty.'));
      return;
    }
    await _queueRepo.add(trimmed);
    _effectPusher.push(const QueueSnackbarEffect('URL added to queue.'));
    unawaited(loadQueue());
  }

  Future<void> onRemoveUrl(String url) async {
    await _queueRepo.remove(url);
    _effectPusher.push(const QueueSnackbarEffect('URL removed from queue.'));
    unawaited(loadQueue());
  }

  Future<void> onProcessQueue() async {
    final items = await _queueRepo.loadAll();
    if (items.isEmpty) {
      _effectPusher.push(const QueueSnackbarEffect('Queue is empty.'));
      return;
    }

    final succeeded = <String>[];
    final failed = <String>[];

    for (var i = 0; i < items.length; i++) {
      _presenter.setProcessing(i);
      final url = items[i];
      try {
        final invoice = await parseInvoice(url);
        for (final item in invoice.items) {
          final datePrefix = compactDate(invoice.date);
          final slug = slugify(item.name);
          final id = '$datePrefix-$slug-${_uuid.v4().substring(0, 4)}';
          final tx = Transaction(
            id: id,
            date: invoice.date,
            retailer: invoice.retailer,
            name: item.name,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            priceTotal: item.total,
            currency: invoice.currency,
            country: invoice.country,
            link: invoice.url,
            notes: invoice.rawBillText.isEmpty ? null : invoice.rawBillText,
          );
          await _txRepo.save(tx);
        }
        succeeded.add(url);
      } on Object catch (e, trace) {
        debugPrint('QueueController: failed to process $url: $e\n$trace');
        failed.add(url);
      }
    }

    // Remove successfully-processed URLs from the queue.
    final remaining = items.where((u) => failed.contains(u)).toList();
    await _queueRepo.saveAll(remaining);

    _effectPusher.push(
      QueueProcessCompleteEffect(
        succeeded: succeeded.length,
        failed: failed.length,
      ),
    );
    unawaited(loadQueue());
  }
}
