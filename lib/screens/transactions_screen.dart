import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/transaction_model.dart';
import '../providers/budget_controller.dart';
import '../widgets/transaction_sheet.dart';
import '../widgets/transaction_tile.dart';

enum _Range {
  all('All'),
  week('This week'),
  month('This month');

  const _Range(this.label);
  final String label;
}

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  _Range _range = _Range.all;

  List<TransactionModel> _filtered(BudgetController c) {
    switch (_range) {
      case _Range.all:
        return c.transactions;
      case _Range.week:
        final end = DateTime(c.weekStart.year, c.weekStart.month, c.weekStart.day + 6);
        return c.transactions
            .where((t) => !t.date.isBefore(c.weekStart) && !t.date.isAfter(end))
            .toList();
      case _Range.month:
        final end = DateTime(c.today.year, c.today.month + 1, 0);
        return c.transactions
            .where((t) => !t.date.isBefore(c.monthStart) && !t.date.isAfter(end))
            .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<BudgetController>();
    final list = _filtered(c);
    final total = list.fold(0.0, (s, t) => s + t.amount);

    final rows = <Widget>[];
    DateTime? lastDay;
    var animIndex = 0;
    for (final t in list) {
      if (lastDay == null || !sameDay(lastDay, t.date)) {
        rows.add(Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
          child: Text(
            dayHeader(t.date),
            style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700),
          ),
        ));
        lastDay = t.date;
      }
      final tile = TransactionTile(
        tx: t,
        onTap: () => showTransactionSheet(context, existing: t),
        onDelete: () => deleteWithUndo(c, ScaffoldMessenger.of(context), t),
      );
      // Small stagger for the first few rows only.
      rows.add(animIndex < 8
          ? tile
              .animate(delay: (50 * animIndex).ms)
              .fadeIn(duration: 350.ms)
              .slideX(begin: .05, end: 0)
          : tile);
      animIndex++;
    }

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Expenses',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -.5)),
                const SizedBox(height: 4),
                Text(
                  '${list.length} ${list.length == 1 ? 'expense' : 'expenses'}, ${money(total)} total',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final r in _Range.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _FilterChip(
                            label: r.label,
                            selected: r == _range,
                            onTap: () => setState(() => _range = r),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: c.load,
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceHigh,
              child: list.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 90),
                        Center(child: Icon(Icons.receipt_long_rounded, size: 48, color: AppColors.textMuted)),
                        SizedBox(height: 14),
                        Center(
                          child: Text('Nothing here yet',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        ),
                        SizedBox(height: 6),
                        Center(
                          child: Text('Tap Add expense to log a purchase.',
                              style: TextStyle(color: AppColors.textMuted)),
                        ),
                      ],
                    )
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
                      children: rows,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(.22) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.primary : Colors.white10),
          boxShadow: selected
              ? AppTheme.glow(AppColors.primary, opacity: .35, blur: 16, spread: -2)
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.text : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
