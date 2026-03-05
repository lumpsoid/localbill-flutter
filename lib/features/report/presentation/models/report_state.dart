import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:meta/meta.dart';

@immutable
class MonthlyTotal {
  const MonthlyTotal({
    required this.yearMonth,
    required this.total,
    required this.count,
  });

  /// "YYYY-MM"
  final String yearMonth;
  final double total;
  final int count;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthlyTotal &&
          other.yearMonth == yearMonth &&
          other.total == total &&
          other.count == count;

  @override
  int get hashCode => Object.hash(yearMonth, total, count);
}

enum ReportStatus { idle, loading, loaded, error }

class ReportState {
  const ReportState({
    this.status = ReportStatus.idle,
    this.rows = const IListConst([]),
    this.grandTotal = 0.0,
    this.totalItems = 0,
    this.errorMessage,
  });

  final ReportStatus status;
  final IList<MonthlyTotal> rows;
  final double grandTotal;
  final int totalItems;
  final String? errorMessage;

  ReportState copyWith({
    ReportStatus? status,
    IList<MonthlyTotal>? rows,
    double? grandTotal,
    int? totalItems,
    String? errorMessage,
  }) => ReportState(
    status: status ?? this.status,
    rows: rows ?? this.rows,
    grandTotal: grandTotal ?? this.grandTotal,
    totalItems: totalItems ?? this.totalItems,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}
