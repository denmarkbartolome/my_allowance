import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/categories.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../models/transaction_model.dart';
import '../providers/budget_controller.dart';
import 'gradient_button.dart';

/// Opens the add / edit expense sheet. Pass [existing] to edit.
Future<void> showTransactionSheet(BuildContext context, {TransactionModel? existing}) {
  // The sheet lives on the root navigator, so hand the controller in directly.
  final controller = context.read<BudgetController>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TransactionSheet(controller: controller, existing: existing),
  );
}

/// Deletes an expense and offers Undo.
Future<void> deleteWithUndo(
  BudgetController c,
  ScaffoldMessengerState messenger,
  TransactionModel tx,
) async {
  try {
    await c.remove(tx);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('Deleted "${tx.title}"'),
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppColors.secondary,
          onPressed: () => c.add(tx),
        ),
      ));
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Could not delete. Try again.')),
    );
  }
}

class _TransactionSheet extends StatefulWidget {
  const _TransactionSheet({required this.controller, this.existing});
  final BudgetController controller;
  final TransactionModel? existing;

  @override
  State<_TransactionSheet> createState() => _TransactionSheetState();
}

class _TransactionSheetState extends State<_TransactionSheet> {
  final _form = GlobalKey<FormState>();
  late final _amount = TextEditingController(
    text: widget.existing == null ? '' : widget.existing!.amount.toStringAsFixed(2),
  );
  late final _title = TextEditingController(text: widget.existing?.title ?? '');
  late final _note = TextEditingController(text: widget.existing?.note ?? '');
  late String _category = widget.existing?.category ?? 'Food';
  late DateTime _date = widget.existing?.date ?? widget.controller.today;
  bool _saving = false;
  String? _error;

  bool get _editing => widget.existing != null;

  @override
  void dispose() {
    _amount.dispose();
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final tx = TransactionModel(
      id: widget.existing?.id,
      title: _title.text.trim(),
      amount: double.parse(_amount.text.replaceAll(',', '')),
      category: _category,
      date: _date,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    );
    try {
      if (_editing) {
        await widget.controller.update(tx);
      } else {
        await widget.controller.add(tx);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      // Temporary: shows the real error on screen so we can see exactly
      // why the save failed, instead of a generic message. Safe to revert
      // to the generic message once the cause is fixed.
      debugPrint('SAVE ERROR: $e');
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Save failed: $e';
        });
      }
    }
  }

  void _delete() {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    deleteWithUndo(widget.controller, messenger, widget.existing!);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(top: BorderSide(color: AppColors.primary.withOpacity(.35))),
          boxShadow: AppTheme.glow(AppColors.primary, opacity: .25, blur: 40, spread: 0),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _editing ? 'Edit expense' : 'Add expense',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (_editing)
                      IconButton(
                        onPressed: _delete,
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                        tooltip: 'Delete expense',
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amount,
                  autofocus: !_editing,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
                  decoration: const InputDecoration(
                    prefixText: '${AppConfig.currency} ',
                    prefixStyle: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                    hintText: '0.00',
                  ),
                  validator: (v) {
                    final n = double.tryParse((v ?? '').replaceAll(',', ''));
                    if (n == null || n <= 0) return 'Enter an amount greater than 0';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'What did you spend on?',
                    prefixIcon: Icon(Icons.edit_rounded),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Add a short title' : null,
                ),
                const SizedBox(height: 18),
                const Text('Category',
                    style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in expenseCategories)
                      _CategoryChip(
                        category: c,
                        selected: c.name == _category,
                        onTap: () => setState(() => _category = c.name),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(16),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 20, color: AppColors.textMuted),
                        const SizedBox(width: 12),
                        Text(DateFormat('EEE, MMM d, yyyy').format(_date)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _note,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(hintText: 'Note (optional)'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.danger)),
                ],
                const SizedBox(height: 22),
                GradientButton(
                  label: _editing ? 'Save changes' : 'Add expense',
                  icon: Icons.check_rounded,
                  loading: _saving,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final ExpenseCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = category.color;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? c.withOpacity(.2) : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? c : Colors.transparent, width: 1.3),
          boxShadow: selected ? AppTheme.glow(c, opacity: .35, blur: 16, spread: -2) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(category.icon, size: 18, color: selected ? c : AppColors.textMuted),
            const SizedBox(width: 6),
            Text(
              category.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.text : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}