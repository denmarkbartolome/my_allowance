import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/allowance_settings.dart';
import '../providers/budget_controller.dart';
import '../services/supabase_service.dart';
import '../widgets/glow_card.dart';
import '../widgets/gradient_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _amount = TextEditingController();
  AllowancePeriod _period = AllowancePeriod.weekly;
  bool _synced = false;
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  double? get _parsed => double.tryParse(_amount.text.replaceAll(',', ''));

  Future<void> _save(BudgetController c) async {
    final value = _parsed;
    final messenger = ScaffoldMessenger.of(context);
    if (value == null || value < 0) {
      messenger.showSnackBar(const SnackBar(content: Text('Enter a valid allowance amount.')));
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await c.saveSettings(AllowanceSettings(amount: value, period: _period));
      messenger.showSnackBar(const SnackBar(content: Text('Allowance saved')));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not save your allowance. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    final service = context.read<SupabaseService>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Log out?'),
        content: const Text('Your expenses stay saved. Log back in any time.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true) await service.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<BudgetController>();
    final user = context.read<SupabaseService>().currentUser;

    // Fill the form once, after the first load finishes.
    if (!_synced && !c.initialLoading) {
      _synced = true;
      _period = c.settings.period;
      if (c.settings.amount > 0) {
        _amount.text = c.settings.amount.toStringAsFixed(
          c.settings.amount.truncateToDouble() == c.settings.amount ? 0 : 2,
        );
      }
    }

    final preview = _parsed;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 40),
        children: [
          const Text('Profile',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -.5)),
          const SizedBox(height: 18),
          GlowCard(
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: AppTheme.glow(AppColors.primary, opacity: .4, blur: 20),
                  ),
                  child: const Icon(Icons.person_rounded, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (user?.userMetadata?['name'] as String?) ?? 'Student',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? '',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          GlowCard(
            glowColor: AppColors.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your allowance',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                const SizedBox(height: 4),
                const Text(
                  'We split it across the days to get your daily budget.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 18),
                _PeriodToggle(
                  value: _period,
                  onChanged: (p) => setState(() => _period = p),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _amount,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  decoration: InputDecoration(
                    prefixText: '${AppConfig.currency} ',
                    prefixStyle: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                    hintText: _period == AllowancePeriod.weekly
                        ? 'Amount per week'
                        : 'Amount per month',
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  child: (preview != null && preview > 0)
                      ? Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Row(
                            children: [
                              const Icon(Icons.auto_awesome_rounded,
                                  size: 16, color: AppColors.secondary),
                              const SizedBox(width: 8),
                              Text(
                                "That's about ${money(c.previewDaily(preview, _period))} a day",
                                style: const TextStyle(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
                const SizedBox(height: 20),
                GradientButton(
                  label: 'Save allowance',
                  icon: Icons.check_rounded,
                  loading: _saving,
                  onPressed: () => _save(c),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Log out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: BorderSide(color: AppColors.danger.withOpacity(.5)),
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodToggle extends StatelessWidget {
  const _PeriodToggle({required this.value, required this.onChanged});
  final AllowancePeriod value;
  final ValueChanged<AllowancePeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    final weekly = value == AllowancePeriod.weekly;
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: weekly ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: .5,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppTheme.glow(AppColors.primary, opacity: .45, blur: 16, spread: -2),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final p in AllowancePeriod.values)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onChanged(p),
                    child: Center(
                      child: Text(
                        p.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: p == value ? Colors.white : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
