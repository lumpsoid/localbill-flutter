import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/presentation/presenter.dart';
import '../../../core/presentation/side_effect.dart';
import '../../shared/domain/repositories/sync_repository.dart';
import '../../shared/domain/repositories/transaction_repository.dart';
import 'models/sync_state.dart';
import 'sync_presenter.dart';

sealed class SyncEffect {
  const SyncEffect();
}

class SyncCompleteEffect extends SyncEffect {
  const SyncCompleteEffect({
    required this.pushed,
    required this.pulled,
    required this.conflicts,
  });
  final int pushed;
  final int pulled;
  final int conflicts;
}

class SyncErrorEffect extends SyncEffect {
  const SyncErrorEffect(this.message);
  final String message;
}

class SyncController {
  SyncController({
    required TransactionRepository transactionRepository,
    required String initialServerUrl,
    required SyncRepository Function(String url) syncRepositoryFactory,
    SyncPresenter? presenter,
    SideEffector<SyncEffect>? effectPusher,
  }) : _txRepo = transactionRepository,
       _syncRepositoryFactory = syncRepositoryFactory,
       _presenter = presenter ?? SyncPresenter(),
       _effectPusher = effectPusher ?? SideEffector<SyncEffect>(),
       _serverUrl = initialServerUrl,
       _syncRepo = syncRepositoryFactory(initialServerUrl);

  final TransactionRepository _txRepo;
  final SyncRepository Function(String url) _syncRepositoryFactory;
  final SyncPresenter _presenter;
  final SideEffector<SyncEffect> _effectPusher;
  String _serverUrl;
  SyncRepository _syncRepo;

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
    _syncRepo = _syncRepositoryFactory(url);
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
      // Load all local transactions (including soft-deleted) for sync.
      final allLocal = await _txRepo.loadAllForSync();

      // Only send records the server has never acknowledged.
      final unacknowledged =
          allLocal.where((t) => t.serverSeq == null).toList();

      // The highest seq we have already integrated from the server.
      final lastSeq = await _txRepo.loadLastSeq();

      final result = await _syncRepo.sync(
        unacknowledged: unacknowledged,
        lastSeq: lastSeq,
      );

      // ── Persist sync results ────────────────────────────────────────────

      // 1. Update serverSeq for each accepted record.
      if (result.acceptedSeqs.isNotEmpty) {
        // Build a fast lookup of all local records by id.
        final localById = {for (final t in allLocal) t.id: t};
        for (final entry in result.acceptedSeqs.entries) {
          final tx = localById[entry.key];
          if (tx != null) {
            await _txRepo.save(tx.copyWith(serverSeq: entry.value));
          }
        }
      }

      // 2. Upsert new records from the server.
      //    Merge envelope by updatedAt if already exists locally.
      for (final serverTx in result.newTransactions) {
        final existing = allLocal.where((t) => t.id == serverTx.id).firstOrNull;
        if (existing == null) {
          // Completely new to this device.
          await _txRepo.save(serverTx);
        } else {
          // Already exists; take whichever envelope is newer.
          final existingUpdatedAt = existing.updatedAt;
          final serverUpdatedAt = serverTx.updatedAt;
          if (serverUpdatedAt.compareTo(existingUpdatedAt) > 0) {
            // Server envelope is newer: apply server envelope but keep local
            // core fields (they are identical since coreHash matched).
            await _txRepo.save(
              existing.withEnvelope(
                tags: serverTx.tags,
                notes: serverTx.notes,
                deleted: serverTx.deleted,
              ).copyWith(serverSeq: serverTx.serverSeq),
            );
          } else if (serverTx.serverSeq != null) {
            // Just stamp the serverSeq we received.
            await _txRepo.save(
              existing.copyWith(serverSeq: serverTx.serverSeq),
            );
          }
        }
      }

      // 3. Advance the lastSeq watermark.
      if (result.newServerSeq != null && result.newServerSeq! > lastSeq) {
        await _txRepo.saveLastSeq(result.newServerSeq!);
      }

      _presenter.setSuccess(result);
      _effectPusher.push(SyncCompleteEffect(
        pushed: result.pushed,
        pulled: result.pulled,
        conflicts: result.conflicts.length,
      ));
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
      final urls = await _syncRepo.fetchRemoteQueue();
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
        await _syncRepo.removeFromRemoteQueue(succeeded);
      }
    } on Object catch (e, trace) {
      debugPrint('SyncController.onFetchRemoteQueue error: $e\n$trace');
    }
  }
}
