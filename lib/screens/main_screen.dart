import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'home_screen.dart';
import 'employee_list_screen.dart';
import 'employee_form_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

/// Root shell with Apple HIG-compliant bottom navigation.
/// All tabs wrapped in [IndexedStack] to preserve state.
class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final _homeKey = GlobalKey<HomeScreenState>();
  final _listKey = GlobalKey<EmployeeListScreenState>();
  final _reportsKey = GlobalKey<ReportsScreenState>();

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _tabs = [
      HomeScreen(key: _homeKey),
      EmployeeListScreen(key: _listKey),
      ReportsScreen(key: _reportsKey),
      const SettingsScreen(),
    ];
  }

  Future<void> _openAddEmployee() async {
    HapticFeedback.lightImpact();
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const EmployeeFormScreen()),
    );
    if (added == true) {
      _homeKey.currentState?.loadData();
      _listKey.currentState?.loadData();
      _reportsKey.currentState?.loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _tabs),

        // ── FAB (kept for quick add, positioned above nav) ───────────────
        floatingActionButton: (_currentIndex == 0 || _currentIndex == 1)
            ? FloatingActionButton(
                onPressed: _openAddEmployee,
                elevation: 4,
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                shape: const CircleBorder(),
                child: const Icon(Icons.add_rounded, size: 28),
              )
            : null,

        // ── Apple HIG: NavigationBar with ≤ 5 destinations ───────────────
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) {
            HapticFeedback.selectionClick();
            setState(() => _currentIndex = i);
            if (i == 0) _homeKey.currentState?.loadData();
            if (i == 1) _listKey.currentState?.loadData();
            if (i == 2) _reportsKey.currentState?.loadData();
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Icon(Icons.group_outlined),
              selectedIcon: Icon(Icons.group_rounded),
              label: 'المستفيدون',
            ),
            NavigationDestination(
              icon: Icon(Icons.description_outlined),
              selectedIcon: Icon(Icons.description_rounded),
              label: 'التقارير',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'الإعدادات',
            ),
          ],
        ),
      ),
    );
  }
}
