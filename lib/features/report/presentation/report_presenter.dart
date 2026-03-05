import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import '../../../core/presentation/presenter.dart';
import '../../shared/domain/entities/transaction.dart';
import 'models/report_state.dart';

class ReportPresenter extends Presenter<ReportState> {
  ReportPresenter([ReportState? initialState])
    : super(initialState ?? const ReportState());

  void setLoading() =>
      updateState((s) => s.copyWith(status: ReportStatus.loading));

  void setReport(List<Transaction> transactions) {
    // Aggregate by YYYY-MM.
    final totals = <String, _Acc>{};
    for (final t in transactions) {
      if (t.date.length < 7) continue;
      final ym = t.date.substring(0, 7);
      final acc = totals.putIfAbsent(ym, _Acc.new);
      acc.total += t.priceTotal;
      acc.count++;
    }

    final sorted =
        totals.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    final rows = IList(
      sorted.map(
        (e) => MonthlyTotal(
          yearMonth: e.key,
          total: e.value.total,
          count: e.value.count,
        ),
      ),
    );

    final grandTotal = rows.fold<double>(0.0, (sum, r) => sum + r.total);

    updateState(
      (s) => s.copyWith(
        status: ReportStatus.loaded,
        rows: rows,
        grandTotal: grandTotal,
        totalItems: transactions.length,
      ),
    );
  }

  void setError(String message) => updateState(
    (s) => s.copyWith(status: ReportStatus.error, errorMessage: message),
  );
}

class _Acc {
  double total = 0.0;
  int count = 0;
}
