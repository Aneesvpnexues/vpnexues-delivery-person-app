import 'package:flutter/material.dart';

import '../state/app_state.dart';
import 'home_tab.dart';
import 'money_tab.dart';
import 'orders_tab.dart';
import 'profile_tab.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        return Scaffold(
          body: IndexedStack(
            index: state.homeTabIndex,
            children: [
              HomeTab(state: state, onOpenTab: state.setHomeTabIndex),
              OrdersTab(state: state, onOpenTab: state.setHomeTabIndex),
              MoneyTab(state: state, onOpenTab: state.setHomeTabIndex),
              ProfileTab(state: state, onOpenTab: state.setHomeTabIndex),
            ],
          ),
        );
      },
    );
  }
}
