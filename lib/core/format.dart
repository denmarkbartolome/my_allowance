import 'package:intl/intl.dart';
import 'constants.dart';

final _money = NumberFormat.currency(symbol: AppConfig.currency, decimalDigits: 2);

String money(double v) => _money.format(v);

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String dayHeader(DateTime d) {
  final n = DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final yesterday = DateTime(n.year, n.month, n.day - 1);
  if (sameDay(d, today)) return 'Today';
  if (sameDay(d, yesterday)) return 'Yesterday';
  return DateFormat('EEEE, MMM d').format(d);
}

String shortDate(DateTime d) => DateFormat('MMM d').format(d);

String greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 18) return 'Good afternoon';
  return 'Good evening';
}
