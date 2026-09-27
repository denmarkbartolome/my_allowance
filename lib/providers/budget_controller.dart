import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../core/format.dart';
import '../models/allowance_settings.dart';
import '../models/transaction_model.dart';
import '../services/supabase_service.dart';

class DaySpend {
  const DaySpend(this.date, this.spent, {required this.isToday, required this.isFuture});
  final DateTime date;
  final double spent;
  final bool isToday;
  final bool isFuture;
}

/// Holds all app data and does the budget maths.
class BudgetController extends ChangeNotifier {
  BudgetController(this._service);
  final SupabaseService _service;

  List<TransactionModel> _tx = [];
  AllowanceSettings _settings = AllowanceSettings.empty;
  bool loading = true;
  bool _loaded = false;
  String? error;

  // ------------------------------------------------------------------ state
  List<TransactionModel> get transactions => List.unmodifiable(_tx);
  AllowanceSettings get settings => _settings;
  bool get hasBudget => _settings.amount > 0;
  bool get initialLoading => loading && !_loaded;

  // ------------------------------------------------------------------ dates
  DateTime get today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  bool get _weekly => _settings.period == AllowancePeriod.weekly;

  DateTime get weekStart {
    final t = today;
    return DateTime(t.year, t.month, t.day - (t.weekday - 1));
  }

  DateTime get monthStart => DateTime(today.year, today.month, 1);

  DateTime get periodStart => _weekly ? weekStart : monthStart;

  DateTime get periodEnd => _weekly
      ? DateTime(weekStart.year, weekStart.month, weekStart.day + 6)
      : DateTime(today.year, today.month + 1, 0);

  int get totalDays => _weekly ? 7 : periodEnd.day;

  /// Days left in the period, including today.
  int get daysLeft =>
      _weekly ? 7 - (today.weekday - 1) : periodEnd.day - today.day + 1;

  bool _inPeriod(DateTime d) => !d.isBefore(periodStart) && !d.isAfter(periodEnd);

  double _sum(Iterable<TransactionModel> l) => l.fold(0.0, (s, t) => s + t.amount);

  // ---------------------------------------------------------------- budget
  List<TransactionModel> get periodTransactions =>
      _tx.where((t) => _inPeriod(t.date)).toList();

  double get spentPeriod => _sum(periodTransactions);

  double get spentToday => _sum(_tx.where((t) => sameDay(t.date, today)));

  double get _spentBeforeToday =>
      _sum(periodTransactions.where((t) => t.date.isBefore(today)));

  /// Plain average: allowance / days in the period.
  double get dailyBudget => _settings.amount / totalDays;

  /// Adaptive limit for today: what's still unspent, shared over the days left.
  /// Overspend yesterday lowers today's limit; saving raises it.
  double get safeToday => daysLeft <= 0
      ? 0
      : math.max(0, _settings.amount - _spentBeforeToday) / daysLeft;

  /// Money left to spend today (negative = over the limit).
  double get todayLeft => safeToday - spentToday;

  /// 0..1 share of today's limit that's still available (drives the ring).
  double get ringFraction =>
      safeToday <= 0 ? 0 : (todayLeft / safeToday).clamp(0.0, 1.0);

  double get periodRemaining => _settings.amount - spentPeriod;

  double get periodProgress =>
      _settings.amount <= 0 ? 0 : (spentPeriod / _settings.amount).clamp(0.0, 1.0);

  /// Mon-Sun of the current week.
  List<DaySpend> get weekDays => List.generate(7, (i) {
        final d = DateTime(weekStart.year, weekStart.month, weekStart.day + i);
        return DaySpend(
          d,
          _sum(_tx.where((t) => sameDay(t.date, d))),
          isToday: sameDay(d, today),
          isFuture: d.isAfter(today),
        );
      });

  double get weekSpent => weekDays.fold(0.0, (s, d) => s + d.spent);

  double get weekBudget => _weekly ? _settings.amount : dailyBudget * 7;

  List<MapEntry<String, double>> get categoryTotals {
    final m = <String, double>{};
    for (final t in periodTransactions) {
      m[t.category] = (m[t.category] ?? 0) + t.amount;
    }
    return m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  /// Used by the allowance form to preview the daily amount.
  double previewDaily(double amount, AllowancePeriod period) {
    final days = period == AllowancePeriod.weekly
        ? 7
        : DateTime(today.year, today.month + 1, 0).day;
    return amount / days;
  }

  // ------------------------------------------------------------------ CRUD
  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      _tx = await _service.fetchTransactions();
      _settings = await _service.fetchSettings();
    } catch (_) {
      error = 'Could not load your data. Check your connection and pull down to retry.';
    }
    loading = false;
    _loaded = true;
    notifyListeners();
  }

  void _sort() => _tx.sort((a, b) {
        final byDate = b.date.compareTo(a.date);
        if (byDate != 0) return byDate;
        final ac = a.createdAt, bc = b.createdAt;
        if (ac == null || bc == null) return 0;
        return bc.compareTo(ac);
      });

  Future<void> add(TransactionModel tx) async {
    final saved = await _service.insertTransaction(tx);
    _tx.add(saved);
    _sort();
    notifyListeners();
  }

  Future<void> update(TransactionModel tx) async {
    final saved = await _service.updateTransaction(tx);
    final i = _tx.indexWhere((t) => t.id == saved.id);
    if (i != -1) _tx[i] = saved;
    _sort();
    notifyListeners();
  }

  /// Removes instantly (so swipe-to-dismiss works) and rolls back on failure.
  Future<void> remove(TransactionModel tx) async {
    final index = _tx.indexWhere((t) => t.id == tx.id);
    if (index == -1) return;
    _tx.removeAt(index);
    notifyListeners();
    try {
      await _service.deleteTransaction(tx.id!);
    } catch (e) {
      _tx.insert(index, tx);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> saveSettings(AllowanceSettings s) async {
    await _service.saveSettings(s);
    _settings = s;
    notifyListeners();
  }
}
