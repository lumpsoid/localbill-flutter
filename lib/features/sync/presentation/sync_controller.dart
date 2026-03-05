import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/presentation/presenter.dart';
import '../../../core/presentation/side_effect.dart';
import '../../shared/data/http_sync_repository.dart';
import '../../shared/domain/repositories/sync_repository.dart';
import '../../shared/domain/repositories/transaction_repository.dart';
import 'models/sync_state.dart';
import 'sync_presenter.dart';

sealed class SyncEffect {
  const SyncEffect();
}

class SyncCompleteEffect extends SyncEffect {
  const SyncCompleteEffect({required this.pushed, required this.pulled});
  final int pushed;
  final int pulled;
}

class SyncErrorEffect extends SyncEffect {
  const SyncErrorEffect(this.message);
  final String message;
}

class SyncController {
  SyncController({
    required TransactionRepository transactionRepository,
    required String initialServerUrl,
    SyncPresenter? presenter,
    SideEffector<SyncEffect>? effectPusher,
  }) : _txRepo = transactionRepository,
       _presenter = presenter ?? SyncPresenter(),
       _effectPusher = effectPusher ?? SideEffector<SyncEffect>(),
       _serverUrl = initialServerUrl;

  final TransactionRepository _txRepo;
  final SyncPresenter _presenter;
  final SideEffector<SyncEffect> _effectPusher;
  String _serverUrl;

  void onViewAttach({
    required StateUpdater<SyncState> updater,
    required SideEffectPusher<SyncEffect> pusher,
  }) {
    _presenter.attach(updater);
    _effectPusher.attach(pusher);
    _presenter.setServerUrl(_serverUrl);
  }

  void onViewDetach() {
    _presenter.detach();
    _effectPusher.detach();
  }

  void onServerUrlChanged(String url) {
    _serverUrl = url;
    _presenter.setServerUrl(url);
  }

  Future<void> onSync() async {
    if (_serverUrl.trim().isEmpty) {
      _effectPusher.push(
        const SyncErrorEffect('Server URL is empty. Set it above.'),
      );
      return;
    }

    _presenter.setSyncing();
    try {
      final local = await _txRepo.loadAll();
      final repo = HttpSyncRepository(serverUrl: _serverUrl.trim());
      final result = await repo.sync(local);

      // Persist any new transactions received from the server.
      if (result.pulled > 0) {
        // The sync response already handled merging on the server side;
        // we just need to reload (the controller above the home page will
        // refresh when navigating back).
      }

      _presenter.setSuccess(result);
      _effectPusher.push(
        SyncCompleteEffect(pushed: result.pushed, pulled: result.pulled),
      );
    } on Object catch (e, trace) {
      debugPrint('SyncController.onSync error: $e\n$trace');
      final msg = e.toString();
      _presenter.setError(msg);
      _effectPusher.push(SyncErrorEffect(msg));
    }
  }

  /// Fetch and process the remote queue.
  Future<void> onFetchRemoteQueue({
    required Future<void> Function(String url) processUrl,
  }) async {
    if (_serverUrl.trim().isEmpty) return;
    try {
      final repo = HttpSyncRepository(serverUrl: _serverUrl.trim());
      final urls = await repo.fetchRemoteQueue();
      final succeeded = <String>[];
      for (final url in urls) {
        try {
          await processUrl(url);
          succeeded.add(url);
        } on Object catch (e) {
          debugPrint('Remote queue process error for $url: $e');
        }
      }
      if (succeeded.isNotEmpty) {
        await repo.removeFromRemoteQueue(succeeded);
      }
    } on Object catch (e, trace) {
      debugPrint('SyncController.onFetchRemoteQueue error: $e\n$trace');
    }
  }
}
