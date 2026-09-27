import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/pulse_glow.dart';
import '../widgets/transaction_sheet.dart';
import 'overview_screen.dart';
import 'profile_screen.dart';
import 'transactions_screen.dart';

/// Bottom navigation + the glowing "Add expense" button.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      OverviewScreen(onOpenSettings: () => _go(2), onSeeAll: () => _go(1)),
      const TransactionsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
        child: KeyedSubtree(key: ValueKey(_index), child: pages[_index]),
      ),
      floatingActionButton: _index == 2
          ? null
          : PulseGlow(
              color: AppColors.primary,
              borderRadius: 20,
              child: FloatingActionButton.extended(
                onPressed: () => showTransactionSheet(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add expense', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white10)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _go,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.donut_large_rounded),
              label: 'Overview',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_rounded),
              label: 'Expenses',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
