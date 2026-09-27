import 'package:flutter/material.dart';

class ExpenseCategory {
  const ExpenseCategory(this.name, this.icon, this.color);
  final String name;
  final IconData icon;
  final Color color;
}

const expenseCategories = <ExpenseCategory>[
  ExpenseCategory('Food', Icons.restaurant_rounded, Color(0xFFFF8A5C)),
  ExpenseCategory('Transport', Icons.directions_bus_rounded, Color(0xFF4DB8FF)),
  ExpenseCategory('School', Icons.school_rounded, Color(0xFF7C5CFF)),
  ExpenseCategory('Shopping', Icons.shopping_bag_rounded, Color(0xFFFF5CAE)),
  ExpenseCategory('Fun', Icons.sports_esports_rounded, Color(0xFFFFB84D)),
  ExpenseCategory('Bills', Icons.receipt_long_rounded, Color(0xFF2DE2B0)),
  ExpenseCategory('Health', Icons.favorite_rounded, Color(0xFFFF5C7A)),
  ExpenseCategory('Other', Icons.category_rounded, Color(0xFF8C90B0)),
];

ExpenseCategory categoryOf(String name) => expenseCategories.firstWhere(
      (c) => c.name == name,
      orElse: () => expenseCategories.last,
    );
