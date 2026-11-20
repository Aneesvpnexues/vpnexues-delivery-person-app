import 'package:flutter/material.dart';

import '../state/app_state.dart';
import 'home_tab.dart';
import 'money_tab.dart';
import 'orders_tab.dart';
import 'profile_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.state});

  final AppState state;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeTab(state: widget.state, onOpenTab: _open),
          OrdersTab(state: widget.state, onOpenTab: _open),
          MoneyTab(state: widget.state, onOpenTab: _open),
          ProfileTab(state: widget.state, onOpenTab: _open),
        ],
      ),
    );
  }

  void _open(int i) => setState(() => _index = i);
}
