import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api_client.dart';
import 'core/session_lifecycle.dart';
import 'screens/root_gate.dart';
import 'state/app_state.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final prefs = await SharedPreferences.getInstance();
  final state = AppState(ApiClient(prefs));
  runApp(PartnerApp(state: state));
  state.boot();
}

class PartnerApp extends StatelessWidget {
  const PartnerApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VP Nexues Partner',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: SessionLifecycle(
        state: state,
        child: RootGate(state: state),
      ),
    );
  }
}
