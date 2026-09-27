import 'package:intl/intl.dart';

class TransactionModel {
  const TransactionModel({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
    this.createdAt,
  });

  final String? id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String? note;
  final DateTime? createdAt;

  factory TransactionModel.fromMap(Map<String, dynamic> m) {
    final parsed = DateTime.parse(m['date'] as String);
    return TransactionModel(
      id: m['id'] as String,
      title: m['title'] as String,
      amount: (m['amount'] as num).toDouble(),
      category: (m['category'] as String?) ?? 'Other',
      date: DateTime(parsed.year, parsed.month, parsed.day),
      note: m['note'] as String?,
      createdAt: m['created_at'] != null
          ? DateTime.tryParse(m['created_at'] as String)?.toLocal()
          : null,
    );
  }

  /// Payload for insert/update (user_id is filled in by the database).
  Map<String, dynamic> toMap() => {
        'title': title,
        'amount': amount,
        'category': category,
        'note': note,
        'date': DateFormat('yyyy-MM-dd').format(date),
      };
}
