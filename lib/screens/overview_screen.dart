import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/categories.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../providers/budget_controller.dart';
import '../services/supabase_service.dart';
import '../widgets/budget_ring.dart';
import '../widgets/glow_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/transaction_sheet.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/week_chart.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key, required this.onOpenSettings, required this.onSeeAll});

  final VoidCallback onOpenSettings;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<BudgetController>();

    if (c.initialLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final user = context.read<SupabaseService>().currentUser;
    final metaName = (user?.userMetadata?['name'] as String?)?.trim();
    final name = (metaName != null && metaName.isNotEmpty)
        ? metaName
        : (user?.email?.split('@').first ?? 'there');

    final recent = c.transactions.take(5).toList();
    final periodNoun = c.settings.period.noun;

    final sections = <Widget>[
      _Header(name: name),
      if (c.error != null) _ErrorBanner(message: c.error!),
      c.hasBudget ? _Hero(c: c) : _SetupCard(onTap: onOpenSettings),
      if (c.hasBudget) _PeriodCard(c: c, noun: periodNoun),
      _WeekCard(c: c),
      if (c.categoryTotals.isNotEmpty) _CategoryCard(c: c, noun: periodNoun),
      _RecentHeader(onSeeAll: onSeeAll, show: recent.isNotEmpty),
      if (recent.isEmpty)
        const _EmptyState()
      else
        for (final t in recent)
          TransactionTile(
            tx: t,
            onTap: () => showTransactionSheet(context, existing: t),
            onDelete: () => deleteWithUndo(c, ScaffoldMessenger.of(context), t),
          ),
    ];

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: c.load,
        color: AppColors.primary,
        backgroundColor: AppColors.surfaceHigh,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
          itemCount: sections.length,
          separatorBuilder: (_, i) {
            // Expense tiles carry their own bottom padding, so keep gaps tight there.
            final tileStart = sections.length - recent.length;
            if (recent.isEmpty) return const SizedBox(height: 18);
            if (i == tileStart - 1) return const SizedBox(height: 10);
            if (i >= tileStart) return const SizedBox.shrink();
            return const SizedBox(height: 18);
          },
          // One entrance moment: the hero card rises in on first load.
          itemBuilder: (_, i) => i == (c.error == null ? 1 : 2)
              ? sections[i].animate().fadeIn(duration: 550.ms).slideY(begin: .06, end: 0)
              : sections[i],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting(), style: const TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 2),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -.5),
              ),
            ],
          ),
        ),
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.glow(AppColors.primary, opacity: .4, blur: 20),
          ),
          child: Text(
            name.isEmpty ? '?' : name[0].toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.c});
  final BudgetController c;

  @override
  Widget build(BuildContext context) {
    final color = budgetColor(c.ringFraction, c.todayLeft);
    final period = c.settings.period.noun;
    return GlowCard(
      glowColor: color,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      gradient: const LinearGradient(
        colors: [AppColors.surfaceHigh, AppColors.surface],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bolt_rounded, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                'This $period, ${c.daysLeft} ${c.daysLeft == 1 ? 'day' : 'days'} left',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 14),
          BudgetRing(fraction: c.ringFraction, amountLeft: c.todayLeft),
          const SizedBox(height: 10),
          Text(
            'Safe limit today: ${money(c.safeToday)}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _Stat(label: 'Daily budget', value: money(c.dailyBudget)),
              _Stat(label: 'Spent today', value: money(c.spentToday)),
              _Stat(label: 'Left in $period', value: money(c.periodRemaining)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          ),
          const SizedBox(height: 3),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
        ],
      ),
    );
  }
}

class _SetupCard extends StatelessWidget {
  const _SetupCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      glowColor: AppColors.primary,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.savings_rounded, size: 46, color: AppColors.primary),
          const SizedBox(height: 14),
          const Text('Set your allowance',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text(
            'Enter what you get each week or month and MyAllowance works out how much you can spend every day.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, height: 1.4),
          ),
          const SizedBox(height: 20),
          GradientButton(label: 'Set allowance', onPressed: onTap),
        ],
      ),
    );
  }
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({required this.c, required this.noun});
  final BudgetController c;
  final String noun;

  @override
  Widget build(BuildContext context) {
    final over = c.periodRemaining < 0;
    final color = over ? AppColors.danger : AppColors.primary;
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('This $noun',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              Text(
                '${DateFormat('MMM d').format(c.periodStart)} to ${DateFormat('MMM d').format(c.periodEnd)}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: c.periodProgress),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => Container(
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.07),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: v.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: AppTheme.glow(color, opacity: .6, blur: 14, spread: 0),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Spent ${money(c.spentPeriod)}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
              Text(
                over
                    ? 'Over by ${money(-c.periodRemaining)}'
                    : '${money(c.periodRemaining)} left of ${money(c.settings.amount)}',
                style: TextStyle(
                  color: over ? AppColors.danger : AppColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.c});
  final BudgetController c;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Weekly summary',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(money(c.weekSpent),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  if (c.hasBudget)
                    Text('of ${money(c.weekBudget)}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          WeekChart(days: c.weekDays, dailyBudget: c.hasBudget ? c.dailyBudget : 0),
          if (c.hasBudget) ...[
            const SizedBox(height: 6),
            const Row(
              children: [
                Icon(Icons.horizontal_rule_rounded, size: 18, color: AppColors.warning),
                SizedBox(width: 6),
                Text('Daily budget',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.c, required this.noun});
  final BudgetController c;
  final String noun;

  @override
  Widget build(BuildContext context) {
    final totals = c.categoryTotals;
    final maxV = totals.first.value;
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Where it went this $noun',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 16),
          for (final e in totals.take(5))
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _CategoryRow(entry: e, maxValue: maxV),
            ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.entry, required this.maxValue});
  final MapEntry<String, double> entry;
  final double maxValue;

  @override
  Widget build(BuildContext context) {
    final cat = categoryOf(entry.key);
    return Row(
      children: [
        Icon(cat.icon, color: cat.color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(money(entry.value),
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 7),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: entry.value / maxValue),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: v,
                    minHeight: 6,
                    backgroundColor: Colors.white.withOpacity(.07),
                    valueColor: AlwaysStoppedAnimation(cat.color),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecentHeader extends StatelessWidget {
  const _RecentHeader({required this.onSeeAll, required this.show});
  final VoidCallback onSeeAll;
  final bool show;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Recent expenses',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        if (show)
          TextButton(
            onPressed: onSeeAll,
            child: const Text('See all', style: TextStyle(color: AppColors.primary)),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const GlowCard(
      padding: EdgeInsets.all(28),
      child: Column(
        children: [
          Icon(Icons.receipt_long_rounded, size: 40, color: AppColors.textMuted),
          SizedBox(height: 12),
          Text('No expenses yet', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          SizedBox(height: 6),
          Text(
            'Tap Add expense to log your first one.',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withOpacity(.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: AppColors.danger),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
