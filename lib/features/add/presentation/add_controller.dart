import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/presentation/presenter.dart';
import '../../../core/presentation/side_effect.dart';
import '../../shared/data/invoice_helpers.dart';
import '../../shared/domain/entities/transaction.dart';
import '../../shared/domain/repositories/transaction_repository.dart';
import 'add_presenter.dart';
import 'models/add_state.dart';

sealed class AddEffect {
  const AddEffect();
}

class AddSuccessEffect extends AddEffect {
  const AddSuccessEffect();
}

class AddErrorEffect extends AddEffect {
  const AddErrorEffect(this.message);
  final String message;
}

class AddController {
  AddController({
    required TransactionRepository transactionRepository,
    AddPresenter? presenter,
    SideEffector<AddEffect>? effectPusher,
  }) : _repo = transactionRepository,
       _presenter = presenter ?? AddPresenter(),
       _effectPusher = effectPusher ?? SideEffector<AddEffect>();

  final TransactionRepository _repo;
  final AddPresenter _presenter;
  final SideEffector<AddEffect> _effectPusher;
  final _uuid = const Uuid();

  void onViewAttach({
    required StateUpdater<AddState> updater,
    required SideEffectPusher<AddEffect> pusher,
  }) {
    _presenter.attach(updater);
    _effectPusher.attach(pusher);
  }

  void onViewDetach() {
    _presenter.detach();
    _effectPusher.detach();
  }

  Future<void> onSave({
    required String date,
    required String retailer,
    required String name,
    required double quantity,
    required double unitPrice,
    required double priceTotal,
    required String currency,
    required String country,
    String? link,
    String? notes,
  }) async {
    _presenter.setSaving();
    try {
      final datePrefix = compactDate(date);
      final slug = slugify(name);
      final id = '$datePrefix-$slug-${_uuid.v4().substring(0, 4)}';

      final tx = Transaction(
        id: id,
        date: date,
        retailer: retailer,
        name: name,
        quantity: quantity,
        unitPrice: unitPrice,
        priceTotal: priceTotal,
        currency: currency,
        country: country,
        link: link,
        notes: notes,
      );

      await _repo.save(tx);
      _presenter.setSuccess();
      _effectPusher.push(const AddSuccessEffect());
    } on Object catch (e, trace) {
      debugPrint('AddController.onSave error: $e\n$trace');
      const msg = 'Failed to save transaction.';
      _presenter.setError(msg);
      _effectPusher.push(const AddErrorEffect(msg));
    }
  }
}
