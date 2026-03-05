import 'package:flutter/material.dart' hide SearchController;

import 'features/add/presentation/add_controller.dart';
import 'features/add/presentation/add_page.dart';
import 'features/insert/presentation/insert_controller.dart';
import 'features/insert/presentation/insert_page.dart';
import 'features/queue/presentation/queue_controller.dart';
import 'features/queue/presentation/queue_page.dart';
import 'features/report/presentation/report_controller.dart';
import 'features/report/presentation/report_page.dart';
import 'features/search/presentation/search_controller.dart';
import 'features/search/presentation/search_page.dart';
import 'features/shared/data/http_sync_repository.dart';
import 'features/shared/data/local_queue_repository.dart';
import 'features/shared/data/local_transaction_repository.dart';
import 'features/sync/presentation/sync_controller.dart';
import 'features/sync/presentation/sync_page.dart';
import 'features/transactions/presentation/transactions_controller.dart';
import 'features/transactions/presentation/transactions_page.dart';

void main() {
  runApp(const LocalBillApp());
}

class LocalBillApp extends StatelessWidget {
  const LocalBillApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LocalBill',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const _CompositionRoot(),
    );
  }
}

/// Composition root: creates repositories and controllers, then renders the
/// main shell. This is the single place where dependencies are wired together.
class _CompositionRoot extends StatefulWidget {
  const _CompositionRoot();

  @override
  State<_CompositionRoot> createState() => _CompositionRootState();
}

class _CompositionRootState extends State<_CompositionRoot> {
  // ── Repositories (shared singletons) ────────────────────────────────────
  final _txRepo = LocalTransactionRepository();
  final _queueRepo = LocalQueueRepository();

  // ── Controllers (created once, reused across tabs) ───────────────────────
  late final TransactionsController _transactionsCtrl;
  late final InsertController _insertCtrl;
  late final QueueController _queueCtrl;
  late final ReportController _reportCtrl;
  late final SearchController _searchCtrl;
  late final AddController _addCtrl;
  late final SyncController _syncCtrl;

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _transactionsCtrl = TransactionsController(transactionRepository: _txRepo);
    _insertCtrl = InsertController(
      transactionRepository: _txRepo,
      queueRepository: _queueRepo,
    );
    _queueCtrl = QueueController(
      queueRepository: _queueRepo,
      transactionRepository: _txRepo,
    );
    _reportCtrl = ReportController(transactionRepository: _txRepo);
    _searchCtrl = SearchController(transactionRepository: _txRepo);
    _addCtrl = AddController(transactionRepository: _txRepo);
    final initUrl = 'http://192.168.1.2:8080';
    _syncCtrl = SyncController(
      transactionRepository: _txRepo,
      initialServerUrl: initUrl,
      syncRepository: HttpSyncRepository(serverUrl: initUrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <_TabPage>[
      _TabPage(
        label: 'Transactions',
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long,
        child: TransactionsPage(controller: _transactionsCtrl),
      ),
      _TabPage(
        label: 'Insert',
        icon: Icons.add_link_outlined,
        activeIcon: Icons.add_link,
        child: InsertPage(controller: _insertCtrl),
      ),
      _TabPage(
        label: 'Add',
        icon: Icons.edit_note_outlined,
        activeIcon: Icons.edit_note,
        child: AddPage(controller: _addCtrl),
      ),
      _TabPage(
        label: 'Queue',
        icon: Icons.queue_outlined,
        activeIcon: Icons.queue,
        child: QueuePage(controller: _queueCtrl),
      ),
      _TabPage(
        label: 'Report',
        icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart,
        child: ReportPage(controller: _reportCtrl),
      ),
      _TabPage(
        label: 'Search',
        icon: Icons.search_outlined,
        activeIcon: Icons.search,
        child: SearchPage(controller: _searchCtrl),
      ),
      _TabPage(
        label: 'Sync',
        icon: Icons.sync_outlined,
        activeIcon: Icons.sync,
        child: SyncPage(controller: _syncCtrl),
      ),
    ];

    final current = pages[_selectedIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(current.label),
        centerTitle: false,
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              icon: const Icon(Icons.refresh_outlined),
              tooltip: 'Refresh',
              onPressed: _transactionsCtrl.loadTransactions,
            ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages.map((p) => p.child).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations:
            pages
                .map(
                  (p) => NavigationDestination(
                    icon: Icon(p.icon),
                    selectedIcon: Icon(p.activeIcon),
                    label: p.label,
                  ),
                )
                .toList(),
      ),
    );
  }
}

class _TabPage {
  const _TabPage({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.child,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget child;
}
