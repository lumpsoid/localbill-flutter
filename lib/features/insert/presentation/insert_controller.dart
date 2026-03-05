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
import 'models/insert_side_effects.dart';
import 'models/insert_state.dart';
import 'insert_presenter.dart';

class InsertController {
  InsertController({
    required TransactionRepository transactionRepository,
    required QueueRepository queueRepository,
    InsertPresenter? presenter,
    SideEffector<InsertEffect>? effectPusher,
  }) : _txRepo = transactionRepository,
       _queueRepo = queueRepository,
       _presenter = presenter ?? InsertPresenter(),
       _effectPusher = effectPusher ?? SideEffector<InsertEffect>();

  final TransactionRepository _txRepo;
  final QueueRepository _queueRepo;
  final InsertPresenter _presenter;
  final SideEffector<InsertEffect> _effectPusher;
  final _uuid = const Uuid();

  void onViewAttach({
    required StateUpdater<InsertState> updater,
    required SideEffectPusher<InsertEffect> pusher,
  }) {
    _presenter.attach(updater);
    _effectPusher.attach(pusher);
  }

  void onViewDetach() {
    _presenter.detach();
    _effectPusher.detach();
  }

  Future<void> onInsertUrl(String url, {bool force = false}) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      _effectPusher.push(const InsertErrorEffect('URL must not be empty'));
      return;
    }

    if (!force && await _txRepo.isDuplicate(trimmed)) {
      _effectPusher.push(const InsertDuplicateEffect());
      return;
    }

    _presenter.setParsing();
    try {
      final invoice = await parseInvoice(trimmed);
      int saved = 0;
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
        saved++;
      }
      _presenter.setSuccess(saved);
      _effectPusher.push(InsertSuccessEffect(saved));
    } on InvoiceParseException catch (e) {
      debugPrint('InsertController: parse error: $e');
      _presenter.setError(e.message);
      _effectPusher.push(InsertErrorEffect(e.message));
    } on Object catch (e, trace) {
      debugPrint('InsertController: unexpected error: $e\n$trace');
      const msg = 'Unexpected error. Check your internet connection.';
      _presenter.setError(msg);
      _effectPusher.push(const InsertErrorEffect(msg));
    }
  }

  Future<void> onQueueUrl(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      _effectPusher.push(const InsertErrorEffect('URL must not be empty'));
      return;
    }
    await _queueRepo.add(trimmed);
    _effectPusher.push(const InsertQueuedEffect());
  }
}
