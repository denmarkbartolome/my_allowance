import 'package:flutter/material.dart';
import '../core/categories.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/transaction_model.dart';

/// One expense row. Tap to edit, swipe left to delete.
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.tx,
    required this.onTap,
    required this.onDelete,
  });

  final TransactionModel tx;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cat = categoryOf(tx.category);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: BorderSide(color: Colors.white.withOpacity(.05)),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey(tx.id ?? tx.hashCode),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDelete(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 26),
          decoration: BoxDecoration(
            color: AppColors.danger.withOpacity(.18),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(Icons.delete_rounded, color: AppColors.danger),
        ),
        child: Material(
          color: AppColors.surface,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: cat.color.withOpacity(.16),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: AppTheme.glow(cat.color, opacity: .25, blur: 16, spread: -2),
                    ),
                    child: Icon(cat.icon, color: cat.color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${tx.category}, ${shortDate(tx.date)}',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '-${money(tx.amount)}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
